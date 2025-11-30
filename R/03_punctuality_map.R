# This script creates a map from the georeferenced punctuality data

# Load packages
library(ggspatial)
library(prettymapr)
library(ggplot2)
library(tidyr)
library(tidyverse)
library(ggspatial)
library(viridis)
library(sf)
library(rosm)
library(leaflet)

# Convert coordinates to numeric
daily_punct_train_geo <- daily_punct_train_geo %>%
  mutate(
    E_Koordinate = as.numeric(`E-Koordinate`),
    N_Koordinate = as.numeric(`N-Koordinate`)
  )


# Calculate delay rate per stop
delay_rate_per_stop <- daily_punct_train_geo %>%
  group_by(BPUIC, HALTESTELLEN_NAME) %>%
  summarise(
    n_trains = n(),
    n_delayed = sum(punct_cat == "delayed", na.rm = TRUE),
    delay_rate = n_delayed / n_trains,  # fraction of delayed trains
    .groups = "drop"
  )

# join with coordinates
delay_geo <- delay_rate_per_stop %>%
  inner_join(
    stops_selected %>%
      mutate(E_Koordinate = as.numeric(`E-Koordinate`),
             N_Koordinate = as.numeric(`N-Koordinate`)),
    by = "BPUIC"
  )

# convert to simple features (sf)
delay_sf <- st_as_sf(
  delay_geo,
  coords = c("E_Koordinate", "N_Koordinate"),
  crs = 2056,
  remove = FALSE
)

# Reproject to WGS84 for leaflet
delay_sf_wgs <- st_transform(delay_sf, crs = 4326)


# plot
leaflet(delay_sf_wgs) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%  # grey basemap
  addCircleMarkers(
    radius = 4,
    color = ~viridis(100, option = "plasma")[cut(delay_rate, breaks = 100)],
    stroke = FALSE,
    fillOpacity = 0.8,
    popup = ~paste0(
      "<b>", HALTESTELLEN_NAME, "</b><br>",
      "Delay rate: ", round(delay_rate * 100, 1), " %<br>",
      "Trains delayed: ", n_delayed, " / ", n_trains
    )
  ) %>%
  addLegend(
    position = "bottomright",
    pal = colorNumeric(palette = "plasma", domain = delay_sf_wgs$delay_rate),
    values = delay_sf_wgs$delay_rate,
    title = "Delay rate"
  )
