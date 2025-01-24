#!/bin/bash

# THIS SHOULD BE DONE ONCE PER PROJECT
# Expects python, pyenv, and poetry exist. Use py_install.sh
# This should work on Linux or on Windows with git bash

## set up the python
# this is not actually necessary, since the package will auto-install python packages.
# But this lets the user control their own environment.
# assume the user has python, pyenv, and poetry
# Could do those installs in another script
# Should we assume pyenv? or poetry, for that matter? I will for now.
pyenv local 3.11.0

# Create a .venv in the directory on Azure.
# `poetry install` should do this, but it doesn't work on azure
if [[ "$(uname)" == 'Linux' ]]; then
  python3 -m venv .venv

  # activate that venv
  source .venv/bin/activate
fi

# now install packages from poetry.lock
poetry install


## R
# pak should handle this in R_setup, but it's failing for some machines. I think pak only checks installed packages, but renv won't install without the C.
# I now do it in R_setup.R so it will be responsive to changes
# sudo apt-get -y update
# sudo apt-get -y install libssl-dev libgdal-dev gdal-bin libgeos-dev libproj-dev libsqlite3-dev libudunits2-dev libicu-dev make libglpk-dev libgmp3-dev libxml2-dev pandoc zlib1g-dev

# rather than a bunch of `Rscript -e 'stuff'` here, just put it in an R file
Rscript "R_setup.R"

