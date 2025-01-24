# Getting set up to use Azure

The steps here should be run *once per azure VM*. They set up git and install python, quarto, and R. I haven't made this a script because it adjusts user settings and some parts may already have been done.

I assume you have an Azure machine and VScode and have [git set up](set_up_git.md), including SSH to access the MDBA repo.

All the commands here should be entered in a bash terminal.

*Optional, but highly recommended*:

-   Install the Quarto extension for VScode

-   Install the R extension for VScode

To test whether you already have what you need, run

```         
R --version
quarto --version
```

If you want to let the toolkit manage python, you're ready to go if that returns 4.3.x (or probably 4.2.x) and 1.x.x

If you want to manage your own python (*recommeded*), check

```         
python --version
poetry --version
```

And if those return 3.11.x and 1.x.x, you should be ready to go. The azure machines often have a system python of 3.8. That is not new enough, so if that's all you see, install pyenv and python below.

Otherwise, follow instructions below to install needed programs.

## Quarto

You'll also want [Quarto](https://quarto.org/) for the notebooks to work. This isn't necessary if you have Rstudio. To install, run these in the terminal:

```         
sudo curl -LO https://quarto.org/download/latest/quarto-linux-amd64.deb
sudo apt-get install gdebi-core
sudo gdebi quarto-linux-amd64.deb
```

Check and remove install file

```         
quarto --version
rm quarto-linux-amd64.deb
```

## Install python with pyenv

*NOTE*- All of the python/pyenv/poetry setup can be skipped and the {werptoolkitr} package will auto-install what it needs. That's easy, but the steps here allow you to control your python environments yourself. If you want to skip installing python, jump all the way to the bottom and double check R is installed.

Install [pyenv](https://github.com/pyenv/pyenv)

```         
curl https://pyenv.run | bash
```

add to PATH in .bashrc and .profile

```         
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
```

```         
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.profile
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.profile
echo 'eval "$(pyenv init -)"' >> ~/.profile
```

restart shell to get that PATH and have the rest work

```         
exec "$SHELL"
```

Setup pyenv build environment

```         
sudo apt update

sudo apt install build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
```

Install new python- this *should* work, but if fails, see next.

```         
pyenv install 3.11.0
```

------------------------------------------------------------------------

> ::: {#pyenv-install-workaround style="color: gray"}
>
> If the above gets stuck with errors, there's a new issue related to the system python (3.8). There are conda environments in the ML machines with newer python. Try:
>
> set up bash to hit conda
>
> ```         
> conda init bash
> ```
>
> restart shell
>
> ```         
> exec "$SHELL"
> ```
>
> then install with pyenv
>
> ```         
> pyenv install 3.11
> ```
>
> Reduce complexity by getting rid of conda again
>
> ```         
> conda init --reverse
> exec "$SHELL"
> ```
>
> :::

------------------------------------------------------------------------

Set the python to 3.11

```         
pyenv global 3.11
```

## Poetry

Install [poetry](https://python-poetry.org/) to manage python environments.

```         
curl -sSL https://install.python-poetry.org | python3 -
echo 'export PATH="/home/azureuser/.local/bin:$PATH"'  >> ~/.bashrc
exec "$SHELL"
```

```         
poetry --version
```

## R

Seems to already be there, but check. Should be version 4.3.

If R is *not* there, this should install it

```         
sudo apt-get update
sudo apt-get install r-base r-base-dev
```

I can change this to use [rig](https://github.com/r-lib/rig) if needed later and unable to update in the usual way.

Check it worked.

```         
R --version
```
