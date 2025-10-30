# This script loads weather data
# The data is available under this URL: 

# Load packages
library(dplyr)
library(tidyr)
library(lubridate)
library(readr)
library(stringr)

# Read data from online source
weather_today <- "https://data.geo.admin.ch/ch.meteoschweiz.messwerte-aktuell/VQHA80.csv"
weather_today <- read.csv(weather_today, header = TRUE, sep = ';', stringsAsFactors = FALSE)

smn_stations <- "https://data.geo.admin.ch/ch.meteoschweiz.ogd-smn/ogd-smn_meta_stations.csv"
smn_stations <- read.csv(smn_stations, header = TRUE, sep = ';', stringsAsFactors = FALSE)


smn_meta <- read.csv(
  "https://data.geo.admin.ch/ch.meteoschweiz.ogd-smn/ogd-smn_meta_parameters.csv",
  header = TRUE,
  sep = ";",
  fileEncoding = "UTF-8",
  stringsAsFactors = FALSE
)


# change date format
weather_today <- weather_today %>%
  mutate(Date = ymd_hm(Date, tz = "UTC"))

# Join weather data with station names
weather_today <- weather_today %>%
  left_join(
    smn_stations %>% select(station_abbr, station_name, station_coordinates_wgs84_lat, station_coordinates_wgs84_lon),
    by = c("Station.Location" = "station_abbr")
  )
