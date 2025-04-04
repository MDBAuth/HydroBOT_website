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

make_ewr_output <- function() {
  project_dir <- file.path("hydrobot_scenarios")
  hydro_dir <- file.path(project_dir, "hydrographs")

  ewr_out <- HydroBOT::prep_run_save_ewrs(
    hydro_dir = hydro_dir,
    output_parent_dir = project_dir,
    outputType = list('yearly'),
    returnType = list('none')
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

find_missing_pages <- function(files = NULL, pattern = "_quarto.*.yml") {

  if (is.null(files)) {
    files <- list.files(pattern = pattern)
  }

  qmd_in_proj <- list.files(pattern = "*.qmd", recursive = TRUE)

  qmd_in_yml <- vector(mode = 'character')
  for (f in files) {
    qmd_in_file <- readLines(f) |>
      purrr::keep(\(x) grepl(".qmd", x)) |>
      gsub('\\s', '', x = _) |>
      gsub('-', '', x = _) |>
      gsub('href:', '', x = _)

    qmd_in_yml <- c(qmd_in_yml, qmd_in_file)
  }

  qmd_in_yml <- unique(qmd_in_yml)

  # The values in the `render` section are still there, but that's ok

  not_present <- which(!(qmd_in_proj %in% qmd_in_yml))

  missing_pages <- qmd_in_proj[not_present]

  no_file <- which(!(qmd_in_yml %in% qmd_in_proj))

  broken_links <- qmd_in_yml[no_file]


  return(list(missing_pages = missing_pages, no_file_present = broken_links))
}
