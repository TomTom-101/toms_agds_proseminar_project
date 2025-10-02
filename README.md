# The Best Project Ever

## Project overview

Ideas: 
- Correlation of weather variables and paragliding cross country flying potential
- development of snow coverage in the alps
- Mobility Data

Contains data and code for creating:

-   Homogenised time series of atmospheric CO<sub>2</sub> and temperature from multiple sources, together covering the past (800 ka), until today, and the future (climate scenario to 2100). Outputs (homogenised time series) are stored in `data/`
-   Visualisation of the parallel evolution of temperature and CO<sub>2</sub>. Outputs (figure files) are stored in `figures/`.

The full workflow can be reproduced by running `vignettes/past_to_future_CO2_temperature.Rmd`.

## Data

The following data were obtained from external sources and are contained in this repository, stored in `data-raw/`.

### CO<sub>2</sub>

-   Bereiter et al., 2015
-   Meinshausen et al., 2011

### Temperature (based on d<sup>18</sup>O)

-   Jouzel et al., 2007
-   Neukom et al., 2009

## Project structure

```         
├── README.md                <- The top-level README includes instructions to use this repository
|                               and the project proposal for the Proseminar
│
├── inaug_demo.Rproj.        <- R project file
| 
├── .gitignore               <- file indicating which files should be ignored when pushing
|
├── data-raw/                <- folder for data downloaded from the external sources, unprocessed
|
├── data/                    <- folder for data produced by the repository
│
├── figures/                 <- folder for figure files produced by the repository 
│
├── vignettes/               <- R markdown files
│   ├── past_to_future_co2_temperature.Rmd  <- Contains the full workflow of data read, processing, and visualisation.
│   └── references.bib       <- bibliography file
|
└── R/                       <- R functions used in the project, contains one function per script
```

## Dependencies

Install all required R libraries by:

``` r
use_pkgs <- c(
  "dplyr",
  "tidyr",
  "purrr",
  "lubridate",
  "readr",
  "ggplot2",
  "gganimate",
  "gifski",
  "here",
  "readr"
  )

new_pkgs <- use_pkgs[!(use_pkgs %in% installed.packages()[, "Package"])]
if (length(new_pkgs) > 0) install.packages(new_pkgs)
```

## License

This is published under a [CC BY-SA license](https://creativecommons.org/licenses/by-sa/4.0/).

## References

-   albert einstein
-   Humboldt
-   Ernest Shackleton
