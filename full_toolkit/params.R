# parameters that involve R objects/syntax, and so cannot be set in a yaml/json params file (yet)

# The goal is to slowly work on making these able to be referenced in params.yml or json

# Aggregation sequence
aggseq <- list(ewr_code = c('ewr_code_timing', 'ewr_code'),
               env_obj =  c('ewr_code', "env_obj"),
               sdl_units = werptoolkitr::sdl_units,
               Specific_goal = c('env_obj', "Specific_goal"),
               catchment = werptoolkitr::cewo_valleys,
               Objective = c('Specific_goal', 'Objective'),
               mdb = werptoolkitr::basin,
               target_5_year_2024 = c('Objective', 'target_5_year_2024'))

# Functions for each aggregation
funseq <- list(c('CompensatingFactor'),
               c('ArithmeticMean'),
               c('ArithmeticMean'),
               c('ArithmeticMean'),
               rlang::quo(list(wm = ~weighted.mean(., w = area,
                                                   na.rm = TRUE))),
               c('ArithmeticMean'),

               rlang::quo(list(wm = ~weighted.mean(., w = area,
                                                   na.rm = TRUE))),
               c('ArithmeticMean'))
