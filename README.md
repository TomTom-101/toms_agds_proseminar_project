# Tracking Delays:
Analysing the Impact of Weather and Seasonal Factors on Swiss Railway Punctuality

## Project overview

This project investigates how precipitation affects train punctuality across 
the Swiss railway network. Using open data on train operations and weather, 
delay metrics are derived and geographically mapped and correlation is analysed
through simple statistical methods. An existing script for punctuality calculation will be adapted for 
national data. 

To view just the results, `vignettes/tracking_delays_project_report.Rmd` can be
displayed without running all the complete analysis script. The code segments 
to perform the punctuality analysis are stored in `R/`. Each segment represents 
a sub-workflow. The segments build on each other and need therefore be executed
one after the other, 1 through 5. Alternatively, `00_script_consolidation.R` can 
benexecuted. Substantial amount of data is downloaded and processed and 
therefore patience is needed for the script to run until the end.


## Data

The following data is obtained from external sources 

### Daily train operation data

-   https://opendata.swiss/de/dataset/ist-daten-v2

### Train stop coordinates

-   https://data.oev-info.ch/explore/dataset/stop-points-today/information/?disjunctive.cantonabbreviation&disjunctive.localityname&disjunctive.businessorganisation&disjunctive.businessorganisationnumber&disjunctive.businessorganisationabbreviationde&disjunctive.businessorganisationdescriptionde&disjunctive.status&disjunctive.verkehrsmittel&disjunctive.isocountrycode&disjunctive.means_of_transport

### Radar Precipitation data

-   https://data.geo.admin.ch/browser/index.html#/collections/ch.meteoschweiz.ogd-radar-precip?.language=en



## Project structure

```         
├── README.md                              <- The top-level README includes instructions to use this repository
|                                             and the project proposal for the Proseminar
│
├── toms_agds_proseminar_project.Rproj.    <- R project file
| 
├── .gitignore                             <- file indicating which files should be ignored when pushing
|
├── data/                                  <- folder for data produced by the repository
│
├── figures/                               <- folder for figure files produced by the repository 
│
├── vignettes/                             <- Contains the full workflow of data read, processing, and visualisation.
|
└── R/                                     <- R scripts used in the project, contains one script per sub-workflow
|
└── renv/                                  <- contains environment management files
```

## Dependencies

Install all required R libraries by:

``` r
required_packages <- c(
  "dplyr", "sf", "terra", "leaflet", "viridis",
  "lubridate", "ggplot2", "tidyr", "httr", "jsonlite",
  "readr", "ggspatial", "leafem", "tidyverse", "httr"
)

installed <- installed.packages()[, "Package"]
to_install <- setdiff(required_packages, installed)

if (length(to_install) > 0) {
  message("Installing missing packages: ", paste(to_install, collapse = ", "))
  install.packages(to_install)
}

suppressPackageStartupMessages({
  library(dplyr)
  library(sf)
  library(terra)
  library(leaflet)
  library(viridis)
  library(lubridate)
  library(ggplot2)
  library(tidyr)
  library(httr)
  library(jsonlite)
  library(readr)
  library(ggspatial)
  library(leafem)
  library(httr)
  
  })
```

## License

This is published under a [CC BY-SA license](https://creativecommons.org/licenses/by-sa/4.0/).
