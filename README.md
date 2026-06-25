# SANE XS4ALL Software List

This repository contains files that define which software packages are available in KB's XS4ALL SANE environment.

Use this repo to track and update the set of accessible software and packages for the XS4ALL configuration.

## Python packages

Our list of installed [python packages](requirements.txt) is based on the [default list of python packages in SANE](https://gitlab.com/rsc-surf-nl/co-create-plugins/sane-tinker-python-packages/-/raw/main/requirements.txt). However, we have disabled all packages used exclusively for Deep Learning, as we currently do not allow this application with our dataset.

## R packages

The SANE default R packages are available in the XS4ALL environment, these are:

- data.table
- dplyr
- ggplot2
- readr
- tidyr
- stringr
- lubridate
- tibble
- purrr
- jsonlite
- httr
- DBI
- RSQLite
