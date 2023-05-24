
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
#' @param unitdf a dataframe for runoff scenarios for an sdl unit
#'
#' @return
#' @export
#'
#' @examples
get_scalings <- function(unitdf) {
  # Stack
  stackdf <- unitdf %>%
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


# DO THE SCALING ----------------------------------------------------------
scale_gauges <- function(gaugedata, gaugename, scaled_units, qc_limit = 150) {

  # Clean the data
  datalist <- clean_to_scale(gaugedata, gaugename, scaled_units, qc_limit)

  if (is.null(datalist)) {return(NULL)}
  # do the transforms

  gaugedata <- datalist$gaugedata %>%
    # get the time units right
    mutate(Month = lubridate::month(time)) %>%
    rename(Date = time) %>%  # To match other inputs
    group_by(Month) %>%
    # get quantiles- make a dummy so NA quantiles exist and get join-crossed with scenarios
    mutate(quantile = get_q(value, q_perc = 0.02)) %>%
    ungroup() %>%
    # join to correct sdl unit for the scalings
    left_join(datalist$scaled_units,
              by = c('Month', 'quantile'),
              multiple = 'all') %>% # Says it's OK to duplicate rows x scenarios
    # get the adjusted levels
    mutate(adj_val = value*relative_change) %>%
    # Just the needed cols
    dplyr::select(scenario, site, Date, adj_val) %>%
    # pivot so the gauge name is col name
    tidyr::pivot_wider(names_from = site, values_from = adj_val) %>%
    # collapse to a list-tibble with one row per scenario
    group_by(scenario) %>%
    tidyr::nest() %>%
    ungroup()

  # Save the csvs
  if (REBUILD_DATA) {
    purrr::pmap(gaugedata, savefun)
  }
  # Not sure this is a good idea- might want to return NULL
  return(gaugedata)
}

# Scaling helpers ---------------------------------------------------------

clean_to_scale <- function(gaugedata, gaugename, scaled_units, qc_limit) {
  # if they are level gauges, return NULL- the scaling doesn't make sense
  if (gaugename %in% gauge_cats$level) {return(NULL)}

  # Get the sdl name
  sdl_name <- gauge_units$SWSDLID[gauge_units$gauge == gaugename]

  # If the sdl unit for the gauge isn't in the scaling scenarios, return NULL.
  # THis only happens for one gauge (422027) in the Barwon-Darling Watercourse (SS19)
  if (!(sdl_name %in% names(scaled_units))) {
    return(NULL)
  }

  # There is one gauge (currently- 412036) that returns duplicated dates from 1990-2004. I've had a long look, and the values differ on each day, with no apparent pattern. They do tend to track together, but the difference can be large. It's not obvious which to keep (if any). I'll just keep the first of each pair, but this should be revisited.
  gaugedata <- gaugedata[!duplicated(gaugedata$time), ]

  # Set bad data to NA
  gaugedata[gaugedata$quality_codes_id > qc_limit, 'value'] <- NA

  # There's one gauge 414209 with ALL bad data. return NULL
  if (all(is.na(gaugedata$value))) {return(NULL)}

  # make an NA quantile for each scenario so the join works properly
  if (any(is.na(gaugedata$value))) {
    nafill <- scaled_units[[sdl_name]] %>%
      distinct(scenario, Month) %>%
      mutate(quantile = NA, mean = NA, ref_mean = NA, relative_change = NA)

    scaled_units[[sdl_name]] <- bind_rows(scaled_units[[sdl_name]], nafill)
  }

  return(list(gaugedata = gaugedata, scaled_units = scaled_units[[sdl_name]]))

}

# simple saver for purrring over
savefun <- function(scenario, data) {
  write_csv(data, file = file.path(hydro_dir, scenario, paste0(names(data)[2], '.csv')))
}


