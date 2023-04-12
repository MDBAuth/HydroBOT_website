# Developing

This repo is intended to contain demonstration/template examples of using the toolkit. It contains an R project for the work and a Quarto project, intended to provie the capacity for not only writing notebooks but presenting them as documentation. Users would typically re-create the structure by creating the R project from Rstudio and may or may not use a Quarto project with `quarto create-project` in terminal. Development proceeding in this repo itself should not need to do either of these tasks. 

## R
Use `renv` to manage R environments. See the developer note for {werptoolkitr}.

### werptoolkitr
We expect that {werptoolkitr} will change frequently since we're simultaneously developing it. To reload and rebuild, there are several options, ranging from more structured (github) to local package install, to just loading the scripts into memory for rapid changes. Note that while the `load_all` option is tempting and very useful, it often works differently than a real package install and so all code should be tested with one of the other two methods.

```
## GITHUB INSTALL
credentials::set_github_pat()
devtools::install_github("MDBAuth/WERP_toolkit", ref = 'packaging', subdir = 'werptoolkitr', force = TRUE)

## LOCAL INSTALL- easier for quick iterations, but need a path.
devtools::install_local("path/to/WERP_toolkit/werptoolkitr", force = TRUE)

# And for very fast iteration (no building, but exposes too much, often)
devtools::load_all("path/to/WERP_toolkit/werptoolkitr")
```


## Python environment
At present, we do most of the work in R, but {werptoolkitr} wraps some python, and we also use some (predominantly from [py-ewr](https://pypi.org/project/py-ewr/) and [mdba gauge-getter](https://pypi.org/project/mdba-gauge-getter/)). To manage this, we need to create a python environment. I have already run `poetry new WERP_toolkit_demo` to create the project.

To create the python environment from the `pyproject.toml` and `poetry.lock` files, run `poetry install`. 

To add python packages, use `poetry add packagename`. Then, committing the `toml`and `lock`files will let others rebuild the environment.

To add a specific version, `poetry add packagename==1.0.1`. This is sometimes necessary with things like py-ewr that change frequently.

To call the python from R, as long as the venv is in the base project directory, {reticulate} seems to find it. Otherwise, need to tell it where it is with `reticulate::use_virtualenv`. *Now that we have nested directories, I set the RETICULATE_PYTHON env variable in* `.Rprofile` . There's more detail about this sort of thing in the developer note in {werptoolkitr}.

## Quarto setup
Set a common output dir in the `_quarto.yml`.

### Rebuilding data

Rebuilding data across the notebooks is done with params to avoid overwriting data unless we mean to. To rebuild, at the terminal in WERP_toolkit_demo run `quarto render path/to/notebook_to_rebuild.qmd -P REBUILD_DATA:TRUE`. To rebuild *everything* in the project, run `quarto render -P REBUILD_DATA:TRUE`.
Running these commands without the parameters will re-render but not rebuild.

**TODO** 
- Use {targets} to manage this workflow.
- put the params in a yaml file, and then have a read-in chunk with {yaml}. 
    - this end-runs quarto though, so depends on use-case.

