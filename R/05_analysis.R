# this script puts together punctuality and precipitation for all stations and hours

library(terra)
library(dplyr)
library(tidyr)
library(sf)

# copy relevant df from punctuality anlysis
station_delay_precip <- delay_sf_hourly_wgs

# reproject station points to LV95
station_lv95 <- st_transform(station_delay_precip, 2056)

# Create SpatVector for extraction
coords <- as.matrix(st_coordinates(station_lv95))
station_vect <- vect(coords, crs = "EPSG:2056")

# Extract precipitation values from hourly raster stack
# hourly_stack: terra SpatRaster in LV95, layers hour_0 ... hour_23
precip_values <- terra::extract(hourly_stack, station_vect)

# Convert to long format
precip_long <- precip_values %>%
  mutate(ID = 1:nrow(station_lv95)) %>%
  pivot_longer(
    cols = starts_with("hour_"),
    names_to = "hour_name",
    values_to = "precip_mm"
  ) %>%
  mutate(hour = as.integer(gsub("hour_", "", hour_name))) %>%
  select(ID, hour, precip_mm)

# Merge precipitation with station_delay_precip
station_delay_precip <- station_delay_precip %>%
  mutate(ID = row_number()) %>%
  left_join(precip_long, by = c("ID", "hour")) %>%
  select(-ID)

# Check
head(station_delay_precip)
