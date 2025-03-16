make_hydro_csv <- function() {
  if (!dir.exists("hydrobot_scenarios")) {
    dir.create("hydrobot_scenarios")
  }

  file.copy(system.file("extdata/testsmall/hydrographs", package = "HydroBOT"),
    "hydrobot_scenarios",
    recursive = TRUE
  )

  # This destroys it once used
  withr::defer_parent(unlink("hydrobot_scenarios", recursive = TRUE))
}

make_hydro_nc <- function() {
  if (!dir.exists("hydrobot_netcdf")) {
    dir.create("hydrobot_netcdf")
  }

  file.copy(system.file("extdata/ncdfexample/nchydros", package = "HydroBOT"),
    "hydrobot_netcdf",
    recursive = TRUE
  )
  file.copy(system.file("extdata/ncdfexample/zipcdf.zip", package = "HydroBOT"),
    "hydrobot_netcdf",
    recursive = TRUE
  )

  # This destroys it once used
  withr::defer_parent(unlink("hydrobot_scenarios", recursive = TRUE))
}


make_simpleyml <- function(renderfile = "auto") {
  if (renderfile == "auto") {
    if (rstudioapi::isAvailable()) {
      projpath <- rstudioapi::getActiveProject()
      docpath <- rstudioapi::documentPath()
      projdir <- sub(".*/([^/]+)$", "\\1", projpath)
      reldocpath <- sub(paste0(".*", projdir, "/"), "", docpath)
      renderfile <- reldocpath
    } else {
      rlang::inform("Rstudio not running, do not want new profiles created while rendering, skipping")
      return(invisible())
    }
  }


  simple_yaml <- list()
  simple_yaml$project <- list()
  simple_yaml$project$render <- list(renderfile)
  yaml::write_yaml(simple_yaml, "_quarto-singlefile.yml")
}
