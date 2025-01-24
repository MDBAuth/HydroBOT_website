# Getting set up to use Windows

The steps here should be run *once per machine*. They set up git and install python. Some of them have likely been done already if you use R or git. I haven't made this a script because it adjusts user settings and some parts may already have been done.

I assume you have [Rstudio](https://posit.co/downloads/) (recommended) or VScode and have [git set up](set_up_git.md), including SSH to access the MDBA repo. If you use VS, install the R and Quarto extensions (and quarto- it comes with Rstudio).

All the commands here should be entered in a powershell terminal, though most work in bash as well.

## Install python with pyenv

*NOTE*- All of the python/pyenv/poetry setup can be skipped and the {werptoolkitr} package will auto-install what it needs. That's easy, but the steps here allow you to control your python environments yourself. If you want to skip installing python, jump all the way to the bottom and double check R is installed.

Install [pyenv-win](https://github.com/pyenv-win/pyenv-win)

``` powershell
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" -OutFile "./install-pyenv-win.ps1"; &"./install-pyenv-win.ps1"
```

Restart powershell. You might have to add pyenv to PATH, but there are not instructions for that.

Install new python

```         
pyenv install 3.11
```

## Poetry

Install [poetry](https://python-poetry.org/) to manage python environments.

``` powershell
(Invoke-WebRequest -Uri https://install.python-poetry.org -UseBasicParsing).Content | py -
```

Add poetry to PATH: search for "Advanced System Settings", then in the bottom right, click Environment Variables, then in the System Variables box, click on Path, then Edit button, then New. That creates a blank line, paste in the path that the installation spits out, or use the one from their website, %APPDATA%\Python\Scripts. OK out of all the system settings boxes.

Set an option

```         
poetry config virtualenvs.prefer-active-python true
```

```         
poetry --version
```

## R

Assume the user has R, if not, get [R](https://www.r-project.org/) and [Rtools](https://cran.r-project.org/bin/windows/Rtools/). Or use [rig](https://github.com/r-lib/rig).

```         
R --version
```

or, if you use rig

``` powershell
rig list
```
