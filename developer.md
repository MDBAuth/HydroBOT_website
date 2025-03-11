# Developing

This repo is intended to contain demonstration/template examples of using HydroBOT. It contains an R project for the work and a Quarto project, enabling the provision of quarto notebooks and their display as the documentation website. Users may want to re-create the structure by creating the R project from Rstudio and may or may not use a Quarto project with `quarto create-project` in terminal, or if only some components are needed for a particular set of analysis (e.g. the full explorations of capacity are not needed), single notebooks can be copied. Development proceeding in this repo itself should not need to do either of these tasks.

## Github

Obtaining the repo for dev should be a straightforward git clone. However, maintaining robust environment management requires we all install the same way, and while the {HydroBOT} package is private, that means [ssh from github](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/).

::: {#Local install note}

The current version of `git2R`, which is used by `devtools::install_git()` to install over ssh is broken in R 4.3.

There are two solutions. One is clone the HydroBOT repo and use `devtools::install_local()`. The other is to use external (system) git, which is cleaner, but might mean setting up new SSH keys. R uses a different Home directory than standard (typically `~/Documents`), and so for this to work, you need to [set up SSH keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) in that location as well (e.g. in `~/Documents/.ssh/`) and [connect them to github](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account). Then this should work:

``` r

# install.packages("devtools")

devtools::install_git("git\@github.com:MDBAuth/HydroBOT.git", ref = 'master', force = TRUE, upgrade = 'ask', git = 'external')
```

:::

Some pitfalls with cloning encountered in working across local and MDBA systems are covered in more detail in the [{HydroBOT}](https://github.com/MDBAuth/HydroBOT) developer page for both Linux and Windows.

## Python environment

On first use, the {HydroBOT} package will auto-install a python environment and necessary packages if it does not find them already.

If you would like to set up your own development environment for python, there is a `pyproject.toml` and a `poetry.lock` file in the repo that should allow you to build an environment with [poetry](https://python-poetry.org/docs/).

Use `pyenv` [to manage python versions](https://github.com/pyenv/pyenv). Follow instructions there. On Windows, that means using [pyenv-win](https://github.com/pyenv-win/pyenv-win) and following instructions there. On Linux, install with `curl https://pyenv.run | bash`. That tells you to add somethign to `.bashrc`, do that.

Then close and restart bash, and run `pyenv install 3.11.0` or whatever version we're using. I needed to `sudo apt-get install libffi-dev` to get it to compile some C bits on Azure. Poetry doesn't actually recognize the defaults, but this still works to install versions. We just end up needing to use `poetry env use VERSION`- see below.

At present, we do most of the work in R, but {HydroBOT} wraps some python, and we also use some (predominantly from [py-ewr](https://pypi.org/project/py-ewr/) and [mdba gauge-getter](https://pypi.org/project/mdba-gauge-getter/)). To manage this, we need to create a python environment. I have already run `poetry new HydroBOT_website` to create the project.

To install poetry, follow the [docs](https://python-poetry.org/docs/), with some more step-by-step and issue-solving [in my notes](https://galenholt.github.io/RpyEnvs/python_setup.html)

## R

Use `rig` to manage R versions. See developer note for [{HydroBOT}](https://github.com/MDBAuth/HydroBOT) and [my notes](https://galenholt.github.io/RpyEnvs/rig.html)

Use `renv` to manage R environments. See the developer note for [{HydroBOT}](https://github.com/MDBAuth/HydroBOT).

The EWR tool is written in python, and so while we have wrapped the necessary functions in the [{HydroBOT}](https://github.com/MDBAuth/HydroBOT) R package, we need to be careful about data type translations. To have an R object that works as a dict in python, for example, use a named list (see a few more translation options at [my github](https://galenholt.github.io/RpyEnvs/R_py_type_passing.html)). The names can be quoted or unquoted; keep quoted to be most like python specs.

### HydroBOT updates

We expect that [{HydroBOT}](https://github.com/MDBAuth/HydroBOT) will change frequently since we're simultaneously developing it. To reload and rebuild, there are several options, ranging from more structured (github) to local package install, to just loading the scripts into memory for rapid changes. Note that while the `load_all` option is tempting and very useful, it often works differently than a real package install and so all code should be tested with one of the other two methods. By default, this loads from `master`, include the argument `ref = BRANCH_NAME` to install from a branch. For `devtools::install_git()` to work with SSH, first install the {git2r} package (though even this doesn't work in R 4.3).

```         
## GITHUB INSTALL

# SSH- preferred

devtools::install_git("git@github.com:MDBAuth/HydroBOT.git", ref = 'master', force = TRUE, upgrade = 'ask')

## LOCAL INSTALL- easier for quick iterations, but need a path.
devtools::install_local("path/to/HydroBOT/HydroBOT", force = TRUE)

# And for very fast iteration (no building, but exposes too much, often)
devtools::load_all("path/to/HydroBOT")
```

If you're installing this repo and rebuilding the R environment with `renv`, it will fail to install {HydroBOT} if you haven't set up SSH for github.

Using `renv` to manage installations enforces the same install of [{HydroBOT}](https://github.com/MDBAuth/HydroBOT) when the environment is rebuilt. The `renv.lock` has the address for the repo as either the SSH or HTTPS path, and the hash. And so if trying to `renv::restore` the package locally or with HTTPS instead of SSH, it will get mad. That's fine, we can still `install` it, but keeping environments synced gets annoying. Until HydroBOT is public, the easiest way to do this is to be on SSH everywhere, but this is not currently possible with R 4.3.

**If possible, please use `install_git` with the ssh path before taking a `renv::snapshot`- that is the only way that captures a version out of github (and so accessible to everyone), and works cross-platform. If there's been a lot of active building using `load_all` or `install_local`, that's fine, but before updating the renv version, push those changes and `install_git`.**

#### Windows note

This seems to be working now, as long as the `renv.lock` was generated from a location that used `install_git` to install it. Make sure to create both the profile and bashrc as in the [{HydroBOT}](https://github.com/MDBAuth/HydroBOT) dev notes- they both seem to be needed to install. Then, we also need to install the `git2r` package, or `install_git` will still fail, but we *cannot* pass the `credentials` argument, even though that seems like what we should do.

#### Azure note

I occasionally get a weird error that `py-ewr` can't be found, which I *think* happens for two reasons- we have a `Config/reticulate` in the `DESCRIPTION` file, which says we need `py-ewr`. But the first terminal that opens in Azure doesn't activate the venv, so it's not there. The solution is to open a new bash terminal, and then try to install again. It is a bit strange that it doesn't try to install py-ewr when it can't find it, but honestly that might be for the best.

## Quarto setup

Setting up the quarto project should already be done, but here's what I did. Set a common output dir in the `_quarto.yml`. I have a `_quarto.yaml.local` to control caching, but be aware that caching can cause issues with some of the notebooks. Currently the ones that fail are some of the scenario creaters and the controllers, with the chunks running the EWR hanging on render. The solution when that happens is just to put `cache: false` in either the yaml header or chunk comment.

On Azure, I had to [install quarto](https://docs.posit.co/resources/install-quarto/), following instructions for .deb-

```         
sudo curl -LO https://quarto.org/download/latest/quarto-linux-amd64.deb
sudo apt-get install gdebi-core
sudo gdebi quarto-linux-amd64.deb
```

Strange render errors could be due to out-of-date quarto versions, currently using 1.3.

## Rebuilding data

Rebuilding data across the notebooks is done with params to avoid overwriting data unless we mean to. To rebuild, at the terminal in HydroBOT_website run `quarto render path/to/notebook_to_rebuild.qmd -P REBUILD_DATA:TRUE`. To rebuild *everything* in the project, run `quarto render -P REBUILD_DATA:TRUE`. Running these commands without the parameters will re-render but not rebuild.

The only documents with `REBUILD_DATA: TRUE` by default are the `provided_data/scenario_creation.qmd` notebook and the `workflows/workflow_save_steps.qmd`, to avoid having multiple notebooks rebuild the same data when we render the site. Because `quarto render` runs in alphabetical order, it is usually best to run those two files first manually so the data exists for all downstream uses.

## Building website

The `quarto.yml` project structure is set up to [build a website](https://quarto.org/docs/publishing/github-pages.html) using the `gh-pages` branch. The branch exists already, so publishing happens with `quarto publish gh-pages --no-browser` (because the site is private). Once public, `quarto publish gh-pages` should work.

If there is unexpected behaviour, e.g. changes not reflected in the output, check the \_cache files and probably throw them out. Caching speeds up by not re-running code and is supposed to notice changes and re-evaluate, but sometimes hangs on when it shouldn't.
