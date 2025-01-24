# Toolkit template

This repo provides a template to get set up and use the toolkit. It is set up as an R project. It provides some environment setup help and a template Quarto notebook that uses the toolkit. Quarto comes with Rstudio or you can use quarto from the command line or VScode; to use it with VScode more easily, install the Quarto extension.

The recommended way to use the toolkit is to manage your own python environments. This is particularly the case if using on Azure. However, it is possible to just use R and it will auto-manage the python, but with less control for the user.

Either way, once you're set up, run the Quarto notebook `full_toolkit.qmd`, and if it renders, everything's working.

## Setup

### git

The package and this repo are currently private to the MDBA github. You'll need to ensure [git and github are set up](set_up_git.md) to access them.

### Managing python or Azure environments

If you need to set up python environments or run on Azure or similar, use the setup files.

1.  Set up your system and ensure you have all dependencies for managing your python environment (and on Linux, the C libraries for R packages). The series of steps to follow for Linux and Windows are here:

    -   LINUX: [initial_azure_setup](initial_azure_setup.md)

    -   WINDOWS: [initial_windows_setup](initial_windows_setup.md)

2.  Set up the project environments. This can be done with scripts:

    -   LINUX: Running `./project_setup.sh` at a bash terminal should then set up the project itself on Linux.

    -   WINDOWS: Running `project_setup.bat` by double clicking it or at the command prompt will do the same on Windows.

### Simple- just R

If you have R and don't care about managing your own python environments, just open R from the terminal or R project file from Rstudio, install the packages `renv` tells you to, and get going.

------------------------------------------------------------------------

> ::: {#Azure-linux-note style="color: gray"}
>
> If you're on Linux, you'll want to run `Rscript 'R_setup.R'` in a terminal first to deal with C libraries, and to use notebooks install [quarto](https://quarto.org/) - instructions in [initial_azure_setup](initial_azure_setup.md).
>
> Ubuntu \>= 20.0 *highly* recommended, older versions have outdated geoprocessing libraries. To update your OS,
>
> ```         
> sudo apt-get update sudo apt-get upgrade
> ```
>
> :::

------------------------------------------------------------------------

If you want to install the toolkit or update it, use

```         
renv::install('git@github.com:MDBAuth/WERP_toolkit.git', ref = 'master', force = TRUE, upgrade = 'ask', git = 'external', rebuild = TRUE)
```

## Run examples

We provide a couple examples of use

-   Run Quarto notebook `full_toolkit.qmd` that runs a simple set of analyses through the toolkit.
    -   Run this by opening it in VScode (install the Quarto extension first). You can run chunks or push the 'Preview' button to render. Otherwise, at the terminal `quarto render full_toolkit.qmd`.
    -   This (or parts of it) can be modified for your use.
-   The Quarto notebook `toolkit_params.qmd` is an example of a run with parameter files, using both external `yml` files and Quarto headers. Run it as before to test, and then modify as desired.
