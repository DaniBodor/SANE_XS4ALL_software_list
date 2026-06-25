# SANE XS4ALL Software Lists

This repository contains files that define which software packages are available in KB's XS4ALL SANE environment.

Use this repo to track and update the set of accessible software and packages for the XS4ALL configuration.

## SolrWayback

The main tool for working with WARC files is [SolrWayback](https://github.com/netarchivesuite/solrwayback). This tool is installed in the environment using the included [powershell script](install_solrwayback.ps1). This step will also install Java in the process, but does not currently include the chrome/chromium installation for page previews.

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
