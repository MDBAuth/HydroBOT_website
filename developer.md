# Developing

This repo is intended to contain demonstration/template examples of using the toolkit. It contains an R project for the work and a Quarto project, intended to provie the capacity for not only writing notebooks but presenting them as documentation. Users would typically re-create the structure by creating the R project from Rstudio and may or may not use a Quarto project with `quarto create-project` in terminal. Development proceeding in this repo itself should not need to do either of these tasks.

## R

Use `renv` to manage R environments. See the developer note for {werptoolkitr}.

The EWR tool is written in python, and so while we have wrapped the necessary functions in the [{werptoolkitr}](https://github.com/MDBAuth/WERP_toolkit) R package, we need to be careful about data type translations. To have an R object that works as a dict in python, for example, use a named list (see a few more translation options at [my github](https://galenholt.github.io/RpyEnvs/R_py_type_passing.html)). The names can be quoted or unquoted; keep quoted to be most like python specs.

### werptoolkitr

We expect that {werptoolkitr} will change frequently since we're simultaneously developing it. To reload and rebuild, there are several options, ranging from more structured (github) to local package install, to just loading the scripts into memory for rapid changes. Note that while the `load_all` option is tempting and very useful, it often works differently than a real package install and so all code should be tested with one of the other two methods. By default, this loads from `master`, include `ref = BRANCH_NAME` to install from a branch.

```         
## GITHUB INSTALL

# HTTPS
credentials::set_github_pat()
devtools::install_github("MDBAuth/WERP_toolkit", ref = 'BRANCH_NAME', subdir = 'werptoolkitr', force = TRUE)

# SSH
devtools::install_git("git@github.com:MDBAuth/WERP_toolkit.git", ref = 'master', subdir = 'werptoolkitr', force = TRUE, upgrade = 'ask')

## LOCAL INSTALL- easier for quick iterations, but need a path.
devtools::install_local("path/to/WERP_toolkit/werptoolkitr", force = TRUE)

# And for very fast iteration (no building, but exposes too much, often)
devtools::load_all("path/to/WERP_toolkit/werptoolkitr")
```

### Installing this repo

If you're installing this repo and rebuilding the R environment with `renv`, it will fail to install {werptoolkitr} if you don't do either of the methods above to pass credentials to github. If you'e connected with HTTPS, you'll need to setup a github PAT in github, and then use `credentials::set_github_pat()`, and if using SSH, `install_git` passes your ssh key. The catch with using `renv` is it doesn't give you the choice- the `renv.lock` has the address for the repo as either the SSH or HTTPS path, depending on how it was installed. And so if the lock has HTTPS, but you're on a system setup with SSH, it'll still try to get werptoolkitr with HTTPS. That's fine, but we can't create github PATs for repos we don't own (e.g. anything in the MDBA group). So, until werptoolkitr is public, the easiest way to do this is to be on SSH everywhere, so the renv points to the ssh path, which we should be able to access from everywhere. Otherwise we have to bypass `renv` to install werptoolkitr, which then installs its dependencies (and upgrades by default), causing all sorts of issues with werptoolkitr working, and stomps on package management here as well.

## Python environment

At present, we do most of the work in R, but {werptoolkitr} wraps some python, and we also use some (predominantly from [py-ewr](https://pypi.org/project/py-ewr/) and [mdba gauge-getter](https://pypi.org/project/mdba-gauge-getter/)). To manage this, we need to create a python environment. I have already run `poetry new WERP_toolkit_demo` to create the project.

To create the python environment from the `pyproject.toml` and `poetry.lock` files, run `poetry install`.

To add python packages, use `poetry add packagename`. Then, committing the `toml`and `lock`files will let others rebuild the environment.

To add a specific version, `poetry add packagename==1.0.1`. This is sometimes necessary with things like py-ewr that change frequently.

To call the python from R, as long as the venv is in the base project directory, {reticulate} seems to find it. Otherwise, need to tell it where it is with `reticulate::use_virtualenv`. *Now that we have nested directories, I set the RETICULATE_PYTHON env variable in* `.Rprofile` . There's more detail about this sort of thing in the developer note in {werptoolkitr}.

## Quarto setup

Set a common output dir in the `_quarto.yml`. I have a `_quarto.yaml.local` to control caching, but be aware that caching can cause issues with some of the notebooks. Currently the ones that fail are the controllers, with the chunks running the EWR hanging on render. The solution when that happens is just to put `cache: false` in either the yaml header or chunk comment.

### Rebuilding data

Rebuilding data across the notebooks is done with params to avoid overwriting data unless we mean to. To rebuild, at the terminal in WERP_toolkit_demo run `quarto render path/to/notebook_to_rebuild.qmd -P REBUILD_DATA:TRUE`. To rebuild *everything* in the project, run `quarto render -P REBUILD_DATA:TRUE`. Running these commands without the parameters will re-render but not rebuild.

**TODO** - Use {targets} to manage this workflow. - put the params in a yaml file, and then have a read-in chunk with {yaml}. - this end-runs quarto though, so depends on use-case.
