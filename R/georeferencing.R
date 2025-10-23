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

# Rename the column
stops <- stops %>%
  rename(BPUIC = `DiDok-Code`)

# Convert to character and trim
stops <- stops %>%
  mutate(BPUIC = str_trim(as.character(BPUIC)))

# Select relevant columns
stops_selected <- stops %>%
  select(BPUIC, "E-Koordinate", "N-Koordinate", "Link auf Karte")

# Join with punctuality, keeping only the selected columns
punctuality_2025_10_11_geo <- punctuality_2025_10_11 %>%
  full_join(stops_selected, by = "BPUIC", relationship = "many-to-many")


# Check for missing coordinates. Should be 0
punctuality_2025_10_11_geo %>%
  summarise(n_missing_E = sum(is.na(`E-Koordinate`)),
            n_missing_N = sum(is.na(`N-Koordinate`)))


