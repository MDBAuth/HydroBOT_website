params <- list(REBUILD_DATA = TRUE)

library(werptoolkitr)
library(dplyr)
library(readr)
library(tidyr)
library(lubridate)
library(ggplot2)

source('scenario_creation/scaling_functions.R')

scenario_dir <- '../flow_scaling_data'
hydro_dir <- file.path(scenario_dir, 'hydrographs')
scaling_dir <- file.path(scenario_dir, 'CC_Scenarios_WRPs')


rain_multiplier <- seq(from = 0.8, to = 1.1, by = 0.05) %>%
  setNames(paste0('SimR', 1:7))

scenario_meta <- list(
  PE_multiplier = c(1, 1, 1.07),
  rain_multiplier = c(1, 1, rain_multiplier),
  scenario_name = c('Historical', 'SimR0', names(rain_multiplier))
)

# I don't know the format we'll be using, but this works to create yaml metadata
yaml::write_yaml(scenario_meta, file = file.path(hydro_dir, 'metadata.yml'))

CCSc_FileList <- list.files(scaling_dir, pattern = '.csv',
                            full.names = TRUE)

scenario_list <- purrr::map(CCSc_FileList,
                            \(x) read_csv(file = x, id = 'path')) %>%
  setNames(stringr::str_extract(CCSc_FileList, "SS[0-9]+"))

# get_q <- function(vals, q_perc) {
#   qs <- quantile(vals, probs = seq(0,1, q_perc), type = 5, na.rm = TRUE)
#   # cut fails with lots of zeros (well, any duplicate bins)
#   # binvec <- cut(vals, qs, include.lowest = TRUE, labels = FALSE)
#   # findInterval is OK with duplicate bins, but combines them, eg. if there are 10 bins that are all 0, it will call them all q10.
#   binvec <- findInterval(vals, qs, rightmost.closed = TRUE)
#   return(binvec)
# }

# get_qmean <- function(vals, q_perc = 0.02) {
#   binvec <- get_q(vals, q_perc)
#   qmean <- aggregate(x = vals, by = list(binvec), FUN = mean) %>%
#     setNames(c('quantile', 'mean'))
# }

# get_scalings <- function(unitdf) {
#   # Stack
#   stackdf <- unitdf %>%
#   mutate(sdl = stringr::str_extract(path, "SS[0-9]+")) %>%
#   select(sdl, Year, Month, Day, starts_with('Sim')) %>%
#   pivot_longer(cols = starts_with('Sim'),
#                names_to = 'scenario', values_to = 'runoff')
#
#   # Quantile means
#   q_s <- stackdf %>%
#   group_by(scenario, Month) %>%
#     summarize(qmean = get_qmean(runoff)) %>%
#     # reframe is the new way, but needs dplyr 1.1 which breaks lots of the functions
#  # reframe(qmean = get_qmean(runoff)) %>%
#   tidyr::unnest(cols = qmean)
#
#   # Get the relative change
#   q_s <- q_s %>%
#   group_by(scenario, Month) %>%
#   baseline_compare(compare_col = 'scenario', base_lev = 'SimR0',
#                    values_col = 'mean',
#                    comp_fun = `/`) %>%
#   ungroup() %>%
#   select(scenario = scenario.x, everything(),
#          relative_change = `/_mean`,
#          -scenario.y)
# }



scaled_units <- purrr::map(scenario_list, get_scalings)

# just look at a couple quantiles
scaled_units$SS20 %>%
  filter(quantile %in% c(1,25,50)) %>%
ggplot(mapping = aes(x = scenario, y = mean, fill = as.factor(quantile))) + geom_col(position = position_dodge())

scaled_units$SS20 %>%
ggplot(mapping = aes(x = as.factor(quantile), y = mean, fill = scenario)) + geom_col(position = position_dodge()) + facet_grid(Month ~ scenario)

scaled_units$SS20 %>%
  ggplot(mapping = aes(x = quantile,
                       y = mean, color = scenario)) +
  geom_line() +
  facet_wrap('Month')

scaled_units$SS20 %>%
  filter(quantile %in% c(1,25,50)) %>%
ggplot(mapping = aes(x = scenario,
                     y = relative_change,
                     fill = as.factor(quantile))) +
  geom_col(position = position_dodge())

scaled_units$SS20 %>%
  ggplot(mapping = aes(x = quantile,
                       y = relative_change, color = scenario)) +
  geom_line() +
  facet_wrap('Month')

orig_hydro <- readRDS(file.path(hydro_dir, 'extracted_flows.rds'))

purrr::map(scenario_meta$scenario_name,
           \(x) if (!dir.exists(file.path(hydro_dir, x))) {
             dir.create(file.path(hydro_dir, x),
                        recursive = TRUE)
             })

# savefun <- function(scenario, data) {
#   write_csv(data, file = file.path(hydro_dir, scenario, paste0(names(data)[2], '.csv')))
# }


thesegauges <- names(orig_hydro)

## from py_ewr.observed_handling import categorise_gauges

## catgauges = categorise_gauges(r.thesegauges)

cg <- reticulate::import("py_ewr.observed_handling")
gauge_cats <- cg$categorise_gauges(thesegauges)
names(gauge_cats) <- c('flow', 'level', 'stage')

gauge_units <- bom_basin_gauges %>%
  filter(gauge %in% names(orig_hydro)) %>%
  sf::st_intersection(sdl_units)

all_codes <- orig_hydro %>%
  purrr::map(\(x) x %>%
               group_by(quality_codes,
                        quality_codes_id) %>%
               summarise(n_records = n())) %>%
  bind_rows() %>%
  group_by(quality_codes,
           quality_codes_id) %>%
  summarise(n_records = sum(n_records)) %>%
  arrange(desc(quality_codes_id))

all_codes

# scale_gauges <- function(gaugedata, gaugename, qc_limit = 150) {
#
#   # if they are level gauges, return NULL- the scaling doesn't make sense
#   if (gaugename %in% gauge_cats$level) {return(NULL)}
#
#   # Get the sdl name
#   sdl_name <- gauge_units$SWSDLID[gauge_units$gauge == gaugename]
#
#   # If the sdl unit for the gauge isn't in the scaling scenarios, return NULL.
#   # THis only happens for one gauge (422027) in the Barwon-Darling Watercourse (SS19)
#   if (!(sdl_name %in% names(scaled_units))) {
#     return(NULL)
#   }
#
#   # There is one gauge (currently- 412036) that returns duplicated dates from 1990-2004. I've had a long look, and the values differ on each day, with no apparent pattern. They do tend to track together, but the difference can be large. It's not obvious which to keep (if any). I'll just keep the first of each pair, but this should be revisited.
#   gaugedata <- gaugedata[!duplicated(gaugedata$time), ]
#
#   # Set bad data to NA
#   gaugedata[gaugedata$quality_codes_id > qc_limit, 'value'] <- NA
#
#   # There's one gauge 414209 with ALL bad data. return NULL
#   if (all(is.na(gaugedata$value))) {return(NULL)}
#
#   # make an NA quantile for each scenario so the join works properly
#   if (any(is.na(gaugedata$value))) {
#     nafill <- scaled_units[[sdl_name]] %>%
#       distinct(scenario, Month) %>%
#       mutate(quantile = NA, mean = NA, ref_mean = NA, relative_change = NA)
#
#     scaled_units[[sdl_name]] <- bind_rows(scaled_units[[sdl_name]], nafill)
#   }
#
#
#   # do the transforms
#
#   gaugedata <- gaugedata %>%
#     # get the time units right
#     mutate(Month = lubridate::month(time)) %>%
#     rename(Date = time) %>%  # To match other inputs
#     group_by(Month) %>%
#     # get quantiles- make a dummy so NA quantiles exist and get join-crossed with scenarios
#     mutate(quantile = get_q(value, q_perc = 0.02)) %>%
#     ungroup() %>%
#     # join to correct sdl unit for the scalings
#     left_join(scaled_units[[sdl_name]],
#               by = c('Month', 'quantile'),
#               multiple = 'all') %>% # Says it's OK to duplicate rows x scenarios
#     # get the adjusted levels
#     mutate(adj_val = value*relative_change) %>%
#     # Just the needed cols
#     dplyr::select(scenario, site, Date, adj_val) %>%
#     # pivot so the gauge name is col name
#     tidyr::pivot_wider(names_from = site, values_from = adj_val) %>%
#     # collapse to a list-tibble with one row per scenario
#     tidyr::nest(.by = scenario)
#
#   # Save the csvs
#   if (REBUILD_DATA) {
#     purrr::pmap(gaugedata, savefun)
#   }
#   # Not sure this is a good idea- might want to return NULL
#   return(gaugedata)
# }

system.time(scaled_hydro <- purrr::map2(orig_hydro,
                                        names(orig_hydro),
                                        \(x,y) scale_gauges(x, y, all_sdl_scenario_list = scenario_list, savedata = params$REBUILD_DATA)))

# library(foreach)
# system.time(
#   scaled_hydro <- foreach(i = 1:length(orig_hydro), .inorder = TRUE) %do% {
#     scale_gauges(orig_hydro[[i]], names(orig_hydro)[i],
#                  all_sdl_scenario_list = scenario_list,
#                  savedata = params$REBUILD_DATA)
#
#   }
# )
# # Only needed for foreach
# names(scaled_hydro) <- names(orig_hydro)[1:length(orig_hydro)]

if (params$REBUILD_DATA) {
  saveRDS(scaled_hydro, file = file.path(hydro_dir, 'scaled_hydrographs.rds'))
}

# plot_hydrographs(scaled_hydro[['409003']] %>%
#   # filter(scenario %in% c('SimR1', 'SimR4', 'SimR7')) %>%
#   unnest(cols = data) %>%
#   pivot_longer(cols = 3, names_to = 'gauge', values_to = 'flow'),
#   y_col = 'flow', transy = scales::pseudo_log_trans(sigma = 1, base = 10))
#
# plot_hydrographs(scaled_hydro[['409003']] %>%
#   # filter(scenario %in% c('SimR1', 'SimR4', 'SimR7')) %>%
#   unnest(cols = data) %>%
#   pivot_longer(cols = 3, names_to = 'gauge', values_to = 'flow'),
#   y_col = 'flow') +
#   facet_wrap('scenario')
#
# scaled_hydro[['409003']] %>%
#   # filter(scenario %in% c('SimR1', 'SimR4', 'SimR7')) %>%
#   unnest(cols = data) %>%
#   group_by(scenario) %>%
#   summarise(n_zeros = sum(`409003` == 0, na.rm = TRUE))
