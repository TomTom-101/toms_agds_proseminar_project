# This script creates a map from the georeferenced punctuality data

# Load packages
library(ggspatial)
library(ggplot2)
library(tidyr)
library(tidyverse)
library(viridis)
library(sf)
library(leaflet)
library(lubridate)  

# Convert coordinates to numeric
daily_punct_train_geo <- daily_punct_train_geo %>%
  mutate(
    E_Koordinate = as.numeric(`E-Koordinate`),
    N_Koordinate = as.numeric(`N-Koordinate`)
  )

# Add hour column based on actual arrival time
daily_punct_train_geo <- daily_punct_train_geo %>%
  mutate(hour = hour(ANKUNFTSZEIT))

# Calculate delay rate per stop and per hour*
delay_rate_hourly <- daily_punct_train_geo %>%
  group_by(BPUIC, HALTESTELLEN_NAME, hour) %>%
  summarise(
    n_trains = n(),
    n_delayed = sum(punct_cat == "delayed", na.rm = TRUE),
    delay_rate = n_delayed / n_trains,
    .groups = "drop"
  )

# Join with coordinates
delay_geo_hourly <- delay_rate_hourly %>%
  inner_join(
    stops_selected %>%
      mutate(E_Koordinate = as.numeric(`E-Koordinate`),
             N_Koordinate = as.numeric(`N-Koordinate`)),
    by = "BPUIC"
  )

# Convert to simple features (sf)
delay_sf_hourly <- st_as_sf(
  delay_geo_hourly,
  coords = c("E_Koordinate", "N_Koordinate"),
  crs = 2056,
  remove = FALSE
)

# Reproject to WGS84 for Leaflet
delay_sf_hourly_wgs <- st_transform(delay_sf_hourly, crs = 4326)

# Leaflet Map for specific hour
hour_to_plot <- 8   # choose the hour you want to display
delay_hour_subset <- delay_sf_hourly_wgs %>%
  filter(hour == hour_to_plot)

leaflet(delay_hour_subset) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addCircleMarkers(
    radius = 4,
    color = ~viridis(100, option = "plasma")[cut(delay_rate, breaks = 100)],
    stroke = FALSE,
    fillOpacity = 0.8,
    popup = ~paste0(
      "<b>", HALTESTELLEN_NAME, "</b><br>",
      "Hour: ", hour, ":00<br>",
      "Delay rate: ", round(delay_rate * 100, 1), " %<br>",
      "Trains delayed: ", n_delayed, " / ", n_trains
    )
  ) %>%
  addLegend(
    position = "bottomright",
    pal = colorNumeric(palette = "plasma", domain = delay_hour_subset$delay_rate),
    values = delay_hour_subset$delay_rate,
    title = paste0("Delay rate @ ", hour_to_plot, ":00")
  )