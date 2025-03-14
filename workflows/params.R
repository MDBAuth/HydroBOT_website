# parameters that involve R objects/syntax cannot be set in a yaml/json params
# file. It is better to use characters,but sometimes that's not possible

# Aggregation sequence
aggseq <- list(
  ewr_code = c("ewr_code_timing", "ewr_code"),
  env_obj = c("ewr_code", "env_obj"),
  sdl_units = HydroBOT::sdl_units,
  Specific_goal = c("env_obj", "Specific_goal"),
  Objective = c("Specific_goal", "Objective"),
  mdb = HydroBOT::basin,
  target_5_year_2024 = c("Objective", "target_5_year_2024")
)

# Functions for each aggregation
funseq <- list(
  c("CompensatingFactor"),
  c("ArithmeticMean"),
  c("ArithmeticMean"),
  c("ArithmeticMean"),
  c("ArithmeticMean"),
  rlang::quo(list(wm = ~ weighted.mean(.,
    w = area,
    na.rm = TRUE
  ))),
  c("ArithmeticMean")
)
