# I don't think the renv install is necessary-it should auto-install since there's a project skeleton
# install.packages('renv')

# use pak to handle system dependencies on linux
if (grepl("unix", .Platform$OS.type)) {
  install.packages('pak', repos = sprintf('https://r-lib.github.io/p/pak/stable/%s/%s/%s', .Platform['pkgType'], R.Version()['os'], R.Version()['arch']))

    renv::install('yaml')
    deps <- renv::dependencies()
    depchars <- c(deps$Package, 'scico', 'ggthemes', 'furrr', 'git2r')
    depchars <- depchars[depchars != 'R']
    depchars <- depchars[depchars != 'HydroBOT']
    depchars <- unique(depchars)
    sysdeps <- pak::pkg_sysreqs(depchars)

    # build and run those
    system2(command = 'sudo', args = sysdeps$pre_install)
    system2(command = 'sudo', args = sysdeps$install_scripts)
    if (length(sysdeps$post_install) > 0) {
        system2(command = 'sudo', args = sysdeps$post_install)
    }

    # Should work, but doesn't always. I think because it only fixes *installed* packages, and renv won't install if they fail
    # pak::sysreqs_fix_installed(depchars)
}

# install R packages
# renv is much faster than remotes because it takes advantage of caching
renv::restore()

# There are occasionally issues, so here are some other ways of getting the package

# Direct install of the package
# renv::install('git@github.com:MDBAuth/HydroBOT.git',
#               dependencies = 'all',
#               rebuild = TRUE,
#               upgrade = 'always',
#               git = 'external',
#               prompt = FALSE)

# Branch
# renv::install('git@github.com:MDBAuth/HydroBOT.git@galen_working',
#               dependencies = 'all',
#               rebuild = TRUE,
#               upgrade = 'always',
#               git = 'external',
#               prompt = FALSE)



# Install from DESCRIPTION
# renv::install()

# renv sometimes struggles with rebuilding and non-main branhes.
# renv::install('remotes')
# remotes::install_git('git@github.com:MDBAuth/HydroBOT.git',
#                      ref = 'galen_working', force = TRUE,
#                      upgrade = 'always', git = 'external')

# For HPC, where we just ignore the spatial stuff
# renv::install('git@github.com:MDBAuth/HydroBOT.git', rebuild = TRUE, upgrade = 'always', git = 'external', prompt = FALSE)
# renv::install()
# # Some extras
# # renv without {remotes} will only install from main. So if we want to use a branch, we need to go with remotes directly
# renv::install(c('scico', 'ggthemes', 'furrr', 'git2r', 'rmarkdown'))
