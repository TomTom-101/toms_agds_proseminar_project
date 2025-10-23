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
stops <- read_delim("https://raw.githubusercontent.com/TomTom-101/toms_agds_proseminar_project/refs/heads/main/data/linie-mit-betriebspunkten.csv", delim = ";")

# Convert BPUIC to character
punctuality_2025_10_11 <- punctuality_2025_10_11 %>%
  mutate(BPUIC = str_trim(as.character(BPUIC)))

stops <- stops %>%
  mutate(BPUIC = str_trim(as.character(BPUIC)))

# Filter
stops_selected <- stops %>%
  select(BPUIC, Geoposition)

# Join with punctuality, keeping only the selected columns
punctuality_2025_10_11_geo <- punctuality_2025_10_11 %>%
  full_join(stops_selected, by = "BPUIC", relationship = "many-to-many")


head(punctuality_2025_10_11_geo)



