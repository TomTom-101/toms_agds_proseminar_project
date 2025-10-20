# This script references names of stops to according geographical coordinates
# The data is available under https://data.opentransportdata.swiss/dataset/service-points-actual-date/resource_permalink/actual_date-swiss-only-service_point-2025-10-20.csv.zip

# Load packages
library(dplyr)
library(tidyr)
library(lubridate)
library(readr)
library(sf)
library(tidyverse)


# Read file
stops <- read_delim("https://raw.githubusercontent.com/TomTom-101/toms_agds_proseminar_project/refs/heads/main/data/stop-points-today.csv", delim = ";")


# Matching
stops_selected <- stops %>%
  select(stop_point_id, latitude, longitude)

# Join with your train data, keeping only the selected columns
train_data_with_coords <- train_data %>%
  left_join(stop_coords_selected, by = c("stop_id" = "stop_point_id"))

# Check the result
head(train_data_with_coords)