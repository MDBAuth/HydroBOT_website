# Developing

In general, let's start by making a repo with an R project and Quarto project. Creating the R project is easy from Rstudio. Quarto project is created with `quarto create-project` in terminal. Set a common output dir in the `_quarto.yml`. 

## Python environment
At present, we do most of the work in R, but that wraps some python, and in the analysis setup steps we will likely need more. So, we need to create a python environment. I have already run `poetry new WERP_toolkit_demo` to create the project.

To create the python environment from the `pyproject.toml` and `poetry.lock` files, run `poetry install`. 

To add python packages, use `poetry add packagename`. Then, committing the `toml`and `lock`files will let others rebuild the environment.

To add a specific version, `poetry add packagename==1.0.1`. This is sometimes necessary with things like py-ewr that are changing a lot.




