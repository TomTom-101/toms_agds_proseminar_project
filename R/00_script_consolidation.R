# Master script to run the full train delay & precipitation analysis

# Clear environment
rm(list = ls())

#  Install missing packages automatically
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

# Load required packages
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

# Run each script in order (this might take some time)
scripts <- c(
  "R/01_punctuality.R",      # download & process train punctuality
  "R/02_georeferencing.R",   # add coordinates to train data
  "R/03_punctuality_map.R",  # create punctuality map
  "R/04_meteorology.R",      # download & process precipitation
  "R/05_analysis.R"          # combine data, correlation, plots
)

for (s in scripts) {
  if (!file.exists(s)) stop("Script not found: ", s)
  message("Running ", s, " ...")
  source(s, local = FALSE)
  message("Finished ", s)
}


# Completion message
cat("\nMaster script completed \n")
