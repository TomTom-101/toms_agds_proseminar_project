# Master script to run the full train delay & precipitation analysis

# Clear environment

rm(list = ls())

# Load required packages
library(renv)
library(dplyr)
library(sf)
library(terra)
library(leaflet)
library(viridis)
library(lubridate)
library(ggplot2)
library(tidyr)

# Activate the project-local environment (renv will use Rproj folder)
renv::activate()

# Run each script in order

source("01_punctuality.R")      # download & process train punctuality
source("02_georeferencing.R")   # add coordinates to train data
source("03_punctuality_map.R")  # create punctuality map
source("04_meteorology.R")      # download & process precipitation
source("05_analysis.R")         # combine data, correlation, plots

# 5. Completion message

cat("\nMaster script completed successfully.\n")
