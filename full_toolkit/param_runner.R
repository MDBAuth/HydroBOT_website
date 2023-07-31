run_toolkit_params <- function(yamlpath,
                               passed_commands = commandArgs(trailingOnly = TRUE),
                               defaults = system.file('yml/default_params.yml', package = 'werptoolkitr')) {

  # I could have a 'defaults' file and then a params that just changes some.
  # Maybe later. Might make a lot of sense if the only thing being passed in is
  # one value.

  arglist <- yaml::read_yaml(defaults)

  # Read in yaml params file
  arglist <- yaml::read_yaml(yamlpath)

  # Allow user to pass yaml at the command line
  comargs <- yaml::yaml.load(passed_commands)

  # Replace the arglist vals with passed args from command line
  arglist <- modifyList(arglist, comargs)

  # R file contains the aggregation definition, since it may need R types
  source(arglist$aggregation_def)

  # Some default modifications need R functions
  arglist <- make_args(arglist)

  ewr_out <- prep_run_save_ewrs_R(scenario_dir = arglist$hydro_dir,
                                  output_dir = arglist$project_dir,
                                  outputType = arglist$outputType,
                                  returnType = arglist$returnType,
                                  climate = arglist$climate)

  aggout <- read_and_agg(datpath = arglist$ewr_results,
                         type = arglist$aggType,
                         geopath = werptoolkitr::bom_basin_gauges,
                         causalpath = werptoolkitr::causal_ewr,
                         groupers = arglist$agg_groups,
                         aggCols = arglist$agg_var,
                         aggsequence = aggseq,
                         funsequence = funseq,
                         saveintermediate = TRUE,
                         namehistory = arglist$namehistory,
                         keepAllPolys = arglist$keepAllPolys,
                         returnList = arglist$aggReturn,
                         savepath = arglist$agg_results)

}

# Use this to allow making the directory structure programatically from the base directory
make_args <- function(arglist) {
  if (arglist$hydro_dir == 'default' | is.null(arglist$hydro_dir)) {
    hydro_dir = file.path(arglist$project_dir, 'hydrographs')
  }

  if (arglist$ewr_dir == 'default' | is.null(arglist$ewr_dir)) {
    ewr_dir <- file.path(arglist$project_dir, 'module_output', 'EWR')
  }

  if (arglist$agg_dir == 'default' | is.null(arglist$ag_dir)) {
    agg_dir <- file.path(arglist$project_dir, 'aggregator_output')
  }

  if (arglist$agg_dir == 'default' | is.null(arglist$ag_dir)) {
    agg_dir <- file.path(arglist$project_dir, 'aggregator_output')
  }

  return(arglist)
}
