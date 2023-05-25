
# Quantile and other data-chunking ----------------------------------------



#' Identify the quantile for each value in a df
#'
#' @param vals
#' @param q_perc
#'
#' @return
#' @export
#'
#' @examples
get_q <- function(vals, q_perc) {
  qs <- quantile(vals, probs = seq(0,1, q_perc), type = 5, na.rm = TRUE)
  binvec <- findInterval(vals, qs, rightmost.closed = TRUE)
  return(binvec)
}

#' Get the mean of each quantile
#'
#' @param vals
#' @param q_perc
#'
#' @return
#' @export
#'
#' @examples
get_qmean <- function(vals, q_perc = 0.02) {
  binvec <- get_q(vals, q_perc)
  qmean <- aggregate(x = vals, by = list(binvec), FUN = mean) %>%
    setNames(c('quantile', 'mean'))
}

#' Get the quantile for each unique value- needed for ranking
#'
#' @param vals
#' @param q_perc
#'
#' @return
#' @export
#'
#' @examples
get_q_unique <- function(vals, q_perc) {
  qs <- quantile(unique(vals), probs = seq(0,1, q_perc), type = 5, na.rm = TRUE)
  binvec <- findInterval(vals, qs, rightmost.closed = TRUE)
  return(binvec)
}


# Extract scalings --------------------------------------------------------

#' Get the scaling factors for the runoff scenarios
#'
#' @param sdl_runoff_scenarios a dataframe for runoff scenarios for an sdl unit
#'
#' @return
#' @export
#'
#' @examples
get_scalings <- function(sdl_runoff_scenarios) {
  # Stack
  stackdf <- sdl_runoff_scenarios %>%
    mutate(sdl = stringr::str_extract(path, "SS[0-9]+")) %>%
    select(sdl, Year, Month, Day, starts_with('Sim')) %>%
    pivot_longer(cols = starts_with('Sim'),
                 names_to = 'scenario', values_to = 'runoff')

  # Quantile means
  q_s <- stackdf %>%
    group_by(scenario, Month) %>%
    summarize(qmean = get_qmean(runoff)) %>%
    # reframe is the new way, but needs dplyr 1.1 which breaks lots of the functions
    # reframe(qmean = get_qmean(runoff)) %>%
    tidyr::unnest(cols = qmean)

  # Get the relative change
  q_s <- q_s %>%
    # group_by(scenario, Month) %>%
    baseline_compare(compare_col = 'scenario',
                     base_lev = 'SimR0',
                     values_col = 'mean',
                     group_cols = c('Month', 'quantile'),
                     comp_fun = `/`) %>%
    ungroup() %>%
    select(scenario = scenario.x, everything(),
           relative_change = `/_mean`,
           -scenario.y)
}


# RANK REGRESSION ---------------------------------------------------------

#' Find matched ranks for hydrograph and runoff scenarios, including dealing with uneven amounts of data, different duplicates, etc.
#'
#' @param hydro dataframe with hydrographs
#' @param model dataframe with runoff scenarios
#'
#' @return a tibble with the values from the model at an appropriate ranking in columns matching hydrograph values.
#' @export
#'
#' @examples
get_matched_ranks <- function(hydro, model, monthly = TRUE) {
  # We need the minimum number across hydro and all scenarios (which may have
  # different numbers of duplicates.)

  # Allow monthly or overall matching
  # if (monthly) {monthgroup <- rlang::quo(Month)} else {monthgroup = NULL}

  if (monthly) {monthgroup <- "Month"} else {monthgroup = NULL}

  uniquemodel <- model %>%
    pivot_longer(cols = starts_with('Sim')) %>%
    group_by(name, across(any_of(monthgroup))) %>%
    summarise(nunique = n_distinct(value))

  uniquehydro <- hydro %>%
    group_by(across(any_of(monthgroup))) %>%
    summarise(nunique = n_distinct(value))

  fewest <- min(min(uniquehydro$nunique),
                min(uniquemodel$nunique))

  # Rank the hydrograph
  hydro <- hydro %>%
    group_by(across(any_of(monthgroup))) %>%
    mutate(ranks = get_q_unique(value, 1/fewest))

  model_rankvals <- model %>%
    pivot_longer(cols = starts_with('Sim'), names_to = 'scenario') %>%
    group_by(scenario, across(any_of(monthgroup))) %>%
    mutate(ranks = get_q_unique(value, 1/fewest)) %>%
    group_by(scenario, across(any_of(monthgroup)), ranks) %>%
    summarise(mod_vals = median(value))

  # replace (really, add another column)
  rank_hydro <- left_join(hydro, model_rankvals, by = c('ranks', monthgroup))

  return(rank_hydro)
}

# DO THE SCALING ----------------------------------------------------------
#' Scales gauge data with q-q or regression from scenarios (over some or all of the data)
#'
#' The regression defaults to monthly, but if there is insufficient good data within any month, it reverts to using the full dataset without a month term.
#'
#' @param gaugedata dataframe of hydrograph data
#' @param gaugename name of gauge
#' @param all_sdl_scenario_list the big list of scenarios for all sdl units
#' @param qc_limit data quality code cutoff
#' @param regression if NULL, just returns q-q. If 'linear', linear regression over the last `reg_rank_prop`, if log, data is transformed to log scale for the regression and back-transformed to return values
#' @param reg_rank_prop proportion of data to use a regression fill on. Typically some small % of the bottom, but if 1, it will just regress the whole thing. I'm not going to bother writing the switches to kill the q-q in that case, since it's unlikely we'll use it. So it will build the q-q and then replace all the data.
#' @param lower_limit lower limit of hydrograph values we trust. Typically 1. Forms the 0-cutoff for log regressions, but also the data range to do linear regression.
#'
#' @return
#' @export
#'
#' @examples
scale_gauges <- function(gaugedata, gaugename, all_sdl_scenario_list, qc_limit = 150,
                         regression = 'linear',
                         reg_rank_prop = 0.05, lower_limit = 1,
                         savedata = FALSE) {

  suppressWarnings(gauge_units <- werptoolkitr::bom_basin_gauges %>%
    dplyr::filter(gauge == gaugename) %>%
    sf::st_intersection(werptoolkitr::sdl_units))

  sdl_name <- gauge_units$SWSDLID

  # catch potential double-matches
  if (length(sdl_name) > 1) {
    rlang::abort(glue::glue('Gauge {gaugename} matches to multiple sdl units: {sdl_name}\n'))
  }

  # If the sdl unit for the gauge isn't in the scaling scenarios, return NULL.
  # THis only happens for one gauge (422027) in the Barwon-Darling Watercourse (SS19)
  if (!(sdl_name %in% names(all_sdl_scenario_list))) {
    return(NULL)
  }

  # if they are level gauges, return NULL- the scaling doesn't make sense
  if (gaugename %in% gauge_cats$level) {return(NULL)}

  # Clean the data and scale the scenario- we only need one of the all_sdl_scenario_list
  datalist <- clean_to_scale(gaugedata = gaugedata, gaugename = gaugename,
                             sdl_runoff_scenarios = all_sdl_scenario_list[[sdl_name]],
                             qc_limit = qc_limit)

  if (is.null(datalist)) {return(NULL)}
  # do the transforms

  # qq all the data- this is cleaner and easier to check than doing it piecewise
  qq_gauge <- datalist$gaugedata %>%
    group_by(Month) %>%
    # get quantiles- make a dummy so NA quantiles exist and get join-crossed with scenarios
    mutate(quantile = get_q(value, q_perc = 0.02)) %>%
    ungroup() %>%
    # join to correct sdl unit for the scalings
    left_join(datalist$model_with_scaling,
              by = c('Month', 'quantile'),
              multiple = 'all') %>% # Says it's OK to duplicate rows x scenarios
    # get the adjusted levels
    mutate(adj_val = value*relative_change) %>%
    # Just the needed cols
    dplyr::select(scenario, site, Date, adj_val)

  if (!is.null(regression)) {
    rank_data <- get_matched_ranks(hydro = datalist$gaugedata,
                                   model = all_sdl_scenario_list[[sdl_name]],
                                   monthly = TRUE)

    # For the regression, we toss everything below lower_limit, so we need to know how many ranks are above this- those below shouldn't be included in the data to feed to the regression.
    rank_summary <- rank_data %>%
      filter(scenario == 'SimR0') %>%
      group_by(Month) %>%
      filter(value >= lower_limit) %>%
      summarise(mingoodrank = min(ranks), maxrank = max(ranks)) %>%
      mutate(nrankbottom = ceiling((maxrank - mingoodrank) * reg_rank_prop),
             bottom_ranks = mingoodrank + nrankbottom)


    # bottom_ranks <- max(rank_data$ranks, na.rm = TRUE)*reg_rank_prop

    # Some of the gauges just don't have enough data to fit by month. In that case, re-rank ignoring months
    # monthdata <- rank_data %>%
    #   filter(scenario == 'SimR0') %>%
    #   group_by(Month) %>%
    #   summarise(ndata = sum(ranks <= bottom_ranks & value >= lower_limit))

    # If insufficient data (at least 10 ranks with values above lower_limit and under reg_rank_prop of the total), re-rank overall, and set a monthly flag
    if (min(rank_summary$nrankbottom) < 10) {
      monthly <- FALSE
      rank_data <- get_matched_ranks(hydro = datalist$gaugedata,
                                     model = all_sdl_scenario_list[[sdl_name]],
                                     monthly = monthly)

      rank_summary <- rank_data %>%
        filter(scenario == 'SimR0') %>%
        filter(value >= lower_limit) %>%
        summarise(mingoodrank = min(ranks), maxrank = max(ranks)) %>%
        mutate(nrankbottom = ceiling((maxrank - mingoodrank) * reg_rank_prop),
               bottom_ranks = mingoodrank + nrankbottom)
      # bottom_ranks <- max(rank_data$ranks, na.rm = TRUE)*reg_rank_prop

      # Cut to those ranks and above the lower values we don't trust and the baseline runoff model

      rank_data <- bind_cols(rank_data, rank_summary)


    } else {
        monthly <- TRUE
        # Cut to those ranks and above the lower values we don't trust and the baseline runoff model- differs by month
        rank_data <- rank_data %>%
          left_join(rank_summary, by = 'Month')

    }

    # Make a version with just the relevant ranks and scenario to feed to the regression
    rank_data_0 <- rank_data %>%
      dplyr::filter(ranks >= mingoodrank &
                      ranks <= bottom_ranks &
                      scenario == 'SimR0')



    if (regression == 'linear') {

      if (monthly) {
        regression_bottom <- lm(value ~ mod_vals + Month + mod_vals*Month, data = rank_data_0)
      }
      if (!monthly) {
        regression_bottom <- lm(value ~ mod_vals, data = rank_data_0)
      }

      bottom_rank_fit <- rank_data %>%
        filter(ranks <= bottom_ranks) %>%
        modelr::add_predictions(regression_bottom, 'pred_hyd') %>%
        # Threshold for 0- make it 1 for log, 0 for linear.
        mutate(pred_hyd = ifelse(pred_hyd > 0, pred_hyd, 0)) %>%
        dplyr::select(Date, scenario, pred_hyd)
    }

    if (regression == 'log') {
      rank_data_0 <- rank_data_0 %>%
        mutate(log_mod = log(mod_vals),
               log_hyd = log(value))

      rank_data <- rank_data %>%
        mutate(log_mod = log(mod_vals),
               log_hyd = log(value))

      if (monthly) {
        regression_bottom <- lm(log_hyd ~ log_mod + Month + log_mod*Month, data = rank_data_0)
      }
      if (!monthly) {
        regression_bottom <- lm(log_hyd ~ log_mod, data = rank_data_0)
      }


      bottom_rank_fit <- rank_data %>%
        filter(ranks <= bottom_ranks) %>%
        modelr::add_predictions(regression_bottom, 'pred_hyd') %>%
        mutate(pred_hyd = exp(pred_log_hyd)) %>%
        # Threshold for 0- make it 1 for log, 0 for linear.
        mutate(pred_hyd = ifelse(pred_hyd > 1, pred_hyd_from_log, 0)) %>%
        dplyr::select(Date, scenario, pred_hyd)
    }

    # swap the values
    qq_gauge <- qq_gauge %>%
      left_join(bottom_rank_fit, by = c('Date', 'scenario')) %>%
      mutate(adj_val = ifelse(is.na(pred_hyd), adj_val, pred_hyd))

  }


  # Format cleanup
  qq_gauge <-  qq_gauge  %>%
    dplyr::select(-pred_hyd, -matches('Month')) %>%
    # pivot so the gauge name is col name
    tidyr::pivot_wider(names_from = site, values_from = adj_val) %>%
    # collapse to a list-tibble with one row per scenario This allows pmap-ing
    # over the rows (scenarios) to save each into a different folder
    group_by(scenario) %>%
    tidyr::nest() %>%
    ungroup()

  # Save the csvs
  if (savedata) {
    purrr::pmap(qq_gauge, savefun)
  }
  # Not sure this is a good idea- might want to return NULL
  # It's useful for diagnostics, I think.
  return(qq_gauge)
}

# Scaling helpers ---------------------------------------------------------

#' Data cleanup of the hydrograph and scenarios- catches weird edge cases and
#' gets the scaling factors for the runoff models
#'
#' @param gaugedata dataframe of hydrograph
#' @param gaugename name of gauge
#' @param all_sdl_scenario_list the big list of all sdl unit scenarios
#' @param qc_limit quality code limit above which to make data NA
#'
#' @return a list with `gaugedata` as the cleaned hydrograph and
#'   `model_with_scaling` as the relevant runoff scenarios for that gauge along
#'   with the scaling factors between each
#' @export
#'
#' @examples
clean_to_scale <- function(gaugedata, gaugename, sdl_runoff_scenarios, qc_limit) {


  model_with_scaling <- get_scalings(sdl_runoff_scenarios)

  # There is one gauge (currently- 412036) that returns duplicated dates from 1990-2004. I've had a long look, and the values differ on each day, with no apparent pattern. They do tend to track together, but the difference can be large. It's not obvious which to keep (if any). I'll just keep the first of each pair, but this should be revisited.
  gaugedata <- gaugedata[!duplicated(gaugedata$time), ]

  # Set bad data to NA
  gaugedata[gaugedata$quality_codes_id > qc_limit, 'value'] <- NA

  # There's one gauge 414209 with ALL bad data. return NULL
  if (all(is.na(gaugedata$value))) {return(NULL)}

  # make an NA quantile for each scenario so the join works properly
  if (any(is.na(gaugedata$value))) {
    nafill <- model_with_scaling %>%
      distinct(scenario, Month) %>%
      mutate(quantile = NA, mean = NA, ref_mean = NA, relative_change = NA)

    model_with_scaling <- bind_rows(model_with_scaling, nafill)
  }

  gaugedata <- gaugedata %>%
    # get the time units right
    mutate(Month = lubridate::month(time)) %>%
    rename(Date = time) # To match other inputs

  return(list(gaugedata = gaugedata, model_with_scaling = model_with_scaling))

}

# simple saver for purrring over
savefun <- function(scenario, data) {
  write_csv(data, file = file.path(hydro_dir, scenario, paste0(names(data)[2], '.csv')))
  return(invisible(NULL))
}


