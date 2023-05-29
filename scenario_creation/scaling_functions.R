
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
    dplyr::mutate(sdl = stringr::str_extract(path, "SS[0-9]+")) %>%
    # We only need Month, not year or day, and we need it to not be numeric
    dplyr::mutate(Date = lubridate::make_date(Year, Month, Day),
                  Month = lubridate::month(Date, label = TRUE)) %>%
    dplyr::select(sdl, Month, tidyselect::starts_with('Sim')) %>%
    tidyr::pivot_longer(cols = tidyselect::starts_with('Sim'),
                 names_to = 'scenario', values_to = 'runoff')

  # Quantile means
  q_s <- stackdf %>%
    dplyr::group_by(scenario, Month) %>%
    dplyr::summarise(qmean = get_qmean(runoff), .groups = 'drop') %>%
    # reframe is the new way, but needs dplyr 1.1 which breaks lots of the functions
    # reframe(qmean = get_qmean(runoff)) %>%
    tidyr::unnest(cols = qmean)

  # Get the relative change
  q_s <- q_s %>%
    # dplyr::group_by(scenario, Month) %>%
    baseline_compare(compare_col = 'scenario',
                     base_lev = 'SimR0',
                     values_col = 'mean',
                     group_cols = c('Month', 'quantile'),
                     comp_fun = `/`) %>%
    dplyr::ungroup() %>%
    dplyr::rename(relative_change = `/_mean`)
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

  # We only need Month, not year or day, and we need it to not be numeric
  model <- model %>%
    dplyr::mutate(Date = lubridate::make_date(Year, Month, Day),
                  Month = lubridate::month(Date, label = TRUE))


  # Allow monthly or overall matching
  # if (monthly) {monthgroup <- rlang::quo(Month)} else {monthgroup = NULL}

  if (monthly) {monthgroup <- "Month"} else {monthgroup = NULL}

  uniquemodel <- model %>%
    tidyr::pivot_longer(cols = tidyselect::starts_with('Sim')) %>%
    dplyr::group_by(name, across(any_of(monthgroup))) %>%
    dplyr::summarise(nunique = dplyr::n_distinct(value), .groups = 'drop')

  uniquehydro <- hydro %>%
    dplyr::group_by(across(any_of(monthgroup))) %>%
    dplyr::summarise(nunique = dplyr::n_distinct(value), .groups = 'drop')

  fewest <- min(min(uniquehydro$nunique),
                min(uniquemodel$nunique))

  # Rank the hydrograph
  hydro <- hydro %>%
    dplyr::group_by(across(any_of(monthgroup))) %>%
    dplyr::mutate(ranks = get_q_unique(value, 1/fewest)) %>%
    dplyr::ungroup()

  model_rankvals <- model %>%
    tidyr::pivot_longer(cols = tidyselect::starts_with('Sim'), names_to = 'scenario') %>%
    dplyr::group_by(scenario, across(any_of(monthgroup))) %>%
    dplyr::mutate(ranks = get_q_unique(value, 1/fewest)) %>%
    dplyr::group_by(scenario, across(any_of(monthgroup)), ranks) %>%
    dplyr::summarise(mod_vals = median(value), .groups = 'drop')

  # replace (really, add another column)
  rank_hydro <- dplyr::left_join(hydro, model_rankvals, by = c('ranks', monthgroup))

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
#' @param savedata logical- save the csvs into scenario folders
#' @param saverds logical- save rds files for each gauge
#' @param returnR logical- return the output to R session, or if FALSE, return NULL invisibly
#'
#' @return
#' @export
#'
#' @examples
scale_gauges <- function(gaugedata, gaugename, all_sdl_scenario_list, qc_limit = 150,
                         regression = 'linear',
                         reg_rank_prop = 0.05, lower_limit = 1,
                         savedata = FALSE,
                         saverds = FALSE,
                         returnR = FALSE) {


  if ((!savedata) & (!saverds) & (!returnR)) {
    rlang::abort('Not returning anything.
                 Set either `savedata`, `saverds`, or `returnR`')
    }


  suppressWarnings(gauge_units <- werptoolkitr::bom_basin_gauges %>%
    dplyr::filter(gauge == gaugename) %>%
    sf::st_intersection(werptoolkitr::sdl_units))

  sdl_name <- gauge_units$SWSDLID

  # catch potential double-matches
  if (length(sdl_name) > 1) {
    rlang::abort(glue::glue('\n\nGauge {gaugename} matches to multiple sdl units: {sdl_name}\n\n'))
  }

  # If the sdl unit for the gauge isn't in the scaling scenarios, return NULL.
  # THis only happens for one gauge (422027) in the Barwon-Darling Watercourse (SS19)
  if (!(sdl_name %in% names(all_sdl_scenario_list))) {
    return(NULL)
  }

  # rlang::inform(glue::glue('starting gauge {gaugename} in SDL {sdl_name}\n'))

  # Clean the data and scale the scenario- we only need one of the all_sdl_scenario_list
  datalist <- clean_to_scale(gaugedata = gaugedata, gaugename = gaugename,
                             sdl_runoff_scenarios = all_sdl_scenario_list[[sdl_name]],
                             qc_limit = qc_limit)

  if (is.null(datalist)) {return(NULL)}
  # do the transforms

  # qq all the data- this is cleaner and easier to check than doing it piecewise
  qq_gauge <- datalist$gaugedata %>%
    dplyr::group_by(Month) %>%
    # get quantiles- make a dummy so NA quantiles exist and get join-crossed with scenarios
    dplyr::mutate(quantile = get_q(value, q_perc = 0.02)) %>%
    dplyr::ungroup() %>%
    # join to correct sdl unit for the scalings
    dplyr::left_join(datalist$model_with_scaling,
              by = c('Month', 'quantile'),
              multiple = 'all') %>% # Says it's OK to duplicate rows x scenarios
    # get the adjusted levels
    dplyr::mutate(adj_val = value*relative_change) %>%
    # Just the needed cols
    dplyr::select(scenario, site, Date, adj_val)

  if (!is.null(regression)) {
    rank_data <- get_matched_ranks(hydro = datalist$gaugedata,
                                   model = all_sdl_scenario_list[[sdl_name]],
                                   monthly = TRUE)

    # For the regression, we toss everything below lower_limit, so we need to know how many ranks are above this- those below shouldn't be included in the data to feed to the regression.
    rank_summary <- rank_data %>%
      dplyr::filter(scenario == 'SimR0') %>%
      dplyr::group_by(Month) %>%
      dplyr::filter(value >= lower_limit) %>%
      dplyr::summarise(mingoodrank = min(ranks), maxrank = max(ranks)) %>%
      dplyr::mutate(nrankbottom = ceiling((maxrank - mingoodrank) * reg_rank_prop),
             bottom_ranks = mingoodrank + nrankbottom)


    # bottom_ranks <- max(rank_data$ranks, na.rm = TRUE)*reg_rank_prop

    # Some of the gauges just don't have enough data to fit by month. In that case, re-rank ignoring months

    # If insufficient data (at least 10 ranks with values above lower_limit and under reg_rank_prop of the total), re-rank overall, and set a monthly flag
    if (min(rank_summary$nrankbottom) < 10) {
      monthly <- FALSE
      rank_data <- get_matched_ranks(hydro = datalist$gaugedata,
                                     model = all_sdl_scenario_list[[sdl_name]],
                                     monthly = monthly)

      rank_summary <- rank_data %>%
        dplyr::filter(scenario == 'SimR0') %>%
        dplyr::filter(value >= lower_limit) %>%
        dplyr::summarise(mingoodrank = min(ranks), maxrank = max(ranks)) %>%
        dplyr::mutate(nrankbottom = ceiling((maxrank - mingoodrank) * reg_rank_prop),
               bottom_ranks = mingoodrank + nrankbottom)
      # bottom_ranks <- max(rank_data$ranks, na.rm = TRUE)*reg_rank_prop

      # Cut to those ranks and above the lower values we don't trust and the baseline runoff model

      rank_data <- bind_cols(rank_data, rank_summary)


    } else {
        monthly <- TRUE
        # Cut to those ranks and above the lower values we don't trust and the baseline runoff model- differs by month
        rank_data <- rank_data %>%
          dplyr::left_join(rank_summary, by = 'Month')

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


      # In some situations, the fits are flat enough and the realised values
      # work out such that the predictions yield values slightly above 0 even
      # for the baseline case where we know there are 0s, and we end up making
      # chunks of postivie numbers. So, we can force this by finding the model
      # values that map to zeros in the data (rank 1) for each month, and then
      # use those as an enforced 0-limit.

      if (all(rank_data_0$value > 0)) {zeroranks <- tibble(Month = unique(rank_data_0$Month), mod_limit =  NA)}

      if (any(rank_data_0$value == 0)) {
        zeroranks <- rank_data_0 %>%
          dplyr::filter(value <= 0) %>%
          dplyr::group_by(Month) %>%
          dplyr::summarise(mod_limit = min(unique(mod_vals))) # Should be unique, but just in case, use the lowest
      }

      bottom_rank_fit <- rank_data %>%
        dplyr::filter(ranks <= bottom_ranks) %>%
        modelr::add_predictions(regression_bottom, 'pred_hyd') %>%
        # Threshold with the zero-limit from the rankings
        dplyr::left_join(zeroranks, by = "Month") %>%
        # Deal with months that don't have a mod_limit (e.g. no zeros in the data)
        dplyr::mutate(mod_limit = ifelse(is.na(mod_limit), 0, mod_limit)) %>%
        dplyr::mutate(pred_hyd = ifelse(mod_vals <= mod_limit, 0, pred_hyd)) %>%
        # Threshold for 0- make it 1 for log, 0 for linear.
        dplyr::mutate(pred_hyd = ifelse(pred_hyd > 0, pred_hyd, 0)) %>%
        dplyr::select(Date, scenario, pred_hyd)
    }

    if (regression == 'log') {
      rank_data_0 <- rank_data_0 %>%
        dplyr::mutate(log_mod = log(mod_vals),
               log_hyd = log(value))

      rank_data <- rank_data %>%
        dplyr::mutate(log_mod = log(mod_vals),
               log_hyd = log(value))

      if (monthly) {
        regression_bottom <- lm(log_hyd ~ log_mod + Month + log_mod*Month, data = rank_data_0)
      }
      if (!monthly) {
        regression_bottom <- lm(log_hyd ~ log_mod, data = rank_data_0)
      }


      bottom_rank_fit <- rank_data %>%
        dplyr::filter(ranks <= bottom_ranks) %>%
        modelr::add_predictions(regression_bottom, 'pred_hyd') %>%
        dplyr::mutate(pred_hyd = exp(pred_log_hyd)) %>%
        # Threshold for 0- make it 1 for log, 0 for linear.
        dplyr::mutate(pred_hyd = ifelse(pred_hyd > 1, pred_hyd_from_log, 0)) %>%
        dplyr::select(Date, scenario, pred_hyd)
    }

    # swap the values
    qq_gauge <- qq_gauge %>%
      dplyr::left_join(bottom_rank_fit, by = c('Date', 'scenario')) %>%
      dplyr::mutate(adj_val = ifelse(is.na(pred_hyd), adj_val, pred_hyd))

  }


  # Format cleanup

  # add the actual gauge data
  ingauge <- datalist$gaugedata %>%
    dplyr::select(Date, site, value) %>%
    dplyr::mutate(scenario = 'Historical')

  qq_gauge <-  qq_gauge  %>%
    dplyr::select(-matches('pred_hyd'), -matches('Month'), value = adj_val) %>%
    bind_rows(ingauge) %>%
    # pivot so the gauge name is col name
    tidyr::pivot_wider(names_from = site, values_from = value) %>%
    # collapse to a list-tibble with one row per scenario This allows pmap-ing
    # over the rows (scenarios) to save each into a different folder
    dplyr::group_by(scenario) %>%
    tidyr::nest() %>%
    dplyr::ungroup()

  # Save the csvs
  if (savedata) {
    purrr::pmap(qq_gauge, savefun)
  }

  # Save the individual rdses
  if (saverds) {
    if (!dir.exists(file.path(hydro_dir, 'rds_outputs'))) {
      dir.create(file.path(hydro_dir, 'rds_outputs'),
                 recursive = TRUE)
    }

    saveRDS(qq_gauge, file = file.path(hydro_dir, 'rds_outputs', paste0(gaugename, '.rds')))
  }

  # rlang::inform(glue::glue('\n\nfinished gauge {gaugename} in SDL {sdl_name}\n\n'))
  # Not sure this is a good idea- might want to return NULL
  # It's useful for diagnostics, I think.

  if (returnR) {
    return(qq_gauge)
  } else {
    return(invisible(NULL))
  }

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
      dplyr::distinct(scenario, Month) %>%
      dplyr::mutate(quantile = NA, mean = NA, ref_mean = NA, relative_change = NA)

    model_with_scaling <- bind_rows(model_with_scaling, nafill)
  }

  gaugedata <- gaugedata %>%
    # get the time units right
    dplyr::mutate(Month = lubridate::month(time, label = TRUE)) %>%
    dplyr::rename(Date = time) # To match other inputs

  return(list(gaugedata = gaugedata, model_with_scaling = model_with_scaling))

}

# simple saver for purrring over
savefun <- function(scenario, data) {
  readr::write_csv(data, file = file.path(hydro_dir, scenario, paste0(names(data)[2], '.csv')))
  return(invisible(NULL))
}


