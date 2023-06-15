# Developing

This repo is intended to contain demonstration/template examples of using the toolkit. It contains an R project for the work and a Quarto project, intended to provie the capacity for not only writing notebooks but presenting them as documentation. Users would typically re-create the structure by creating the R project from Rstudio and may or may not use a Quarto project with `quarto create-project` in terminal. Development proceeding in this repo itself should not need to do either of these tasks.

## Github

This is just a straightforward git clone, but due to issues with installing the same way across this and {werptoolkitr} itself, things will work best if we use the ssh from git, at least while the repo is private.

The instructions for that are in the {werptoolkitr} developer page for both Linux and Windows.

## Python environment

The python actually needs to come first, or the renv dies on install because it looks for `py-ewr` to get werptoolkitr installed.

Use `pyenv` [to manage python versions](https://github.com/pyenv/pyenv). Follow instructions there. On Windows, that means using [pyenv-win](https://github.com/pyenv-win/pyenv-win) and following instructions there. On Linux, install with `curl https://pyenv.run | bash`. That tells you to add somethign to `.bashrc`, do that.

Then close and restart bash, and run `pyenv install 3.11.0` or whatever version we're using. I needed to `sudo apt-get install libffi-dev` to get it to compile some C bits on Azure. Poetry doesn't actually recognize the defaults, but this still works to install versions. We just end up needing to use `poetry env use VERSION`- see below.

At present, we do most of the work in R, but {werptoolkitr} wraps some python, and we also use some (predominantly from [py-ewr](https://pypi.org/project/py-ewr/) and [mdba gauge-getter](https://pypi.org/project/mdba-gauge-getter/)). To manage this, we need to create a python environment. I have already run `poetry new WERP_toolkit_demo` to create the project.

To install poetry, follow the [docs](https://python-poetry.org/docs/), with some more step-by-step and issue-solving [in my notes](https://galenholt.github.io/RpyEnvs/python_setup.html)

Once poetry is installed, cd to the repo and:

To ensure we have the venv in the project, set `poetry config virtualenvs.in-project true`

`poetry config virtualenvs.prefer-active-python true`, which doesn't seem to work, so then run

`poetry env use 3.11` or whatever version is in the lock

then `poetry install`.

To create the python environment from the `pyproject.toml` and `poetry.lock` files, run `poetry install`.

To add python packages, use `poetry add packagename`. Then, committing the `toml`and `lock`files will let others rebuild the environment.

To add a specific version, `poetry add packagename==1.0.1`. This is sometimes necessary with things like py-ewr that change frequently.

To call the python from R, as long as the venv is in the base project directory, {reticulate} seems to find it. Otherwise, need to tell it where it is with `reticulate::use_virtualenv`. There's more detail about this sort of thing in the developer note in {werptoolkitr}- here, the venv is in the outer directory and just works.

**ON AZURE**- when you first start a vscode session, the bash at the bottom does not use the poetry environment, and so if you try to install or use werptoolkitr, it will try to auto-build one with the right dependencies using miniconda (or just fail with cryptic errors). That might work (but usually doesn't). Instead, *start a new bash terminal*, which will activate the venv, and open R from there. At that point, installing werptoolkitr (or `renv::restore()` generally), and using the code should work.

## R

Use `rig` to manage R versions. See developer note for {werptoolkitr} and [my notes](https://galenholt.github.io/RpyEnvs/rig.html)

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

If you're installing this repo and rebuilding the R environment with `renv`, it will fail to install {werptoolkitr} if you don't do either of the methods above to pass credentials to github. If you'e connected with HTTPS, you'll need to setup a github PAT in github, and then use `credentials::set_github_pat()`. If using SSH, `install_git` passes your ssh key. This happens automatically on Linux, but Windows is a pain.

The catch with using `renv` is it doesn't give you the choice- the `renv.lock` has the address for the repo as either the SSH or HTTPS path, depending on how it was installed. And so if the lock has HTTPS, but you're on a system setup with SSH, it'll still try to get werptoolkitr with HTTPS. That's fine, but we can't create github PATs for repos we don't own (e.g. anything in the MDBA group). So, until werptoolkitr is public, the easiest way to do this is to be on SSH everywhere, so the renv points to the ssh path, which we should be able to access from everywhere. Otherwise we have to bypass `renv` to install werptoolkitr, which then installs its dependencies (and upgrades by default), causing all sorts of issues with werptoolkitr working, and stomps on package management here as well.

SO: **Please use `install_git` with the ssh path before taking a `renv::snapshot`- that is the only way that captures a version out of github (and so accessible to everyone), and works cross-platform. If there's been a lot of active building using `load_all` or `install_local`, that's fine, but before updating the renv version, push those changes and `install_git`.**

#### Windows note

This seems to be working now, as long as the `renv.lock` was generated from a location that used `install_git` to install it. Make sure to create both the profile and bashrc as in the {werptoolkitr} notes- they both seem to be needed to install. And it's unclear why, since those are for bash, and `install_git` calls cmd. cmd must be calling git bash internally. Then, we also need to install the `git2r` package, or `install_git` will still fail, but we *cannot* pass the `credentials` argument, even though that seems like what we should do.

#### Azure note

I occasionally get a weird error that `py-ewr` can't be found, which I *think* happens for two reasons- we have a `Config/reticulate` in the `DESCRIPTION` file, which says we need `py-ewr`. But the first terminal that opens in Azure doesn't activate the venv, so it's not there. The solution is to open a new bash terminal, and then try to install again. It is a bit strange that it doesn't try to install py-ewr when it can't find it, but honestly that might be for the best.

## Quarto setup

This has mostly been done- but here's what I did. Set a common output dir in the `_quarto.yml`. I have a `_quarto.yaml.local` to control caching, but be aware that caching can cause issues with some of the notebooks. Currently the ones that fail are some of the scenario creaters and the controllers, with the chunks running the EWR hanging on render. The solution when that happens is just to put `cache: false` in either the yaml header or chunk comment.

On Azure, I had to [install quarto](https://docs.posit.co/resources/install-quarto/), following instructions for .deb-

```         
sudo curl -LO https://quarto.org/download/latest/quarto-linux-amd64.deb
sudo apt-get install gdebi-core
sudo gdebi quarto-linux-amd64.deb
```

### Rebuilding data

Rebuilding data across the notebooks is done with params to avoid overwriting data unless we mean to. To rebuild, at the terminal in WERP_toolkit_demo run `quarto render path/to/notebook_to_rebuild.qmd -P REBUILD_DATA:TRUE`. To rebuild *everything* in the project, run `quarto render -P REBUILD_DATA:TRUE`. Running these commands without the parameters will re-render but not rebuild.

**TODO** - Use {targets} to manage this workflow. - put the params in a yaml file, and then have a read-in chunk with {yaml}. - this end-runs quarto though, so depends on use-case.
