# Master script to run the full train delay & precipitation analysis

# Clear environment
rm(list = ls())

#  Install missing packages automatically
required_packages <- c(
  "dplyr", "sf", "terra", "leaflet", "viridis",
  "lubridate", "ggplot2", "tidyr", "httr", "jsonlite", "renv"
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
  library(renv)
})

# Activate the project-local environment (renv will use Rproj folder)
renv::activate()
renv::restore(prompt = FALSE)

# Run each script in order
scripts <- c(
  "01_punctuality.R",      # download & process train punctuality
  "02_georeferencing.R",   # add coordinates to train data
  "03_punctuality_map.R",  # create punctuality map
  "04_meteorology.R",      # download & process precipitation
  "05_analysis.R"          # combine data, correlation, plots
)

for (s in scripts) {
  if (!file.exists(s)) {
    warning("Script not found: ", s, " – skipping.")
    next
  }
  message("Running ", s, " ...")
  tryCatch(
    source(s),
    error = function(e) {
      message("Error in ", s, ": ", e$message)
    }
  )
}

# Completion message
cat("\nMaster script completed successfully.\n")
