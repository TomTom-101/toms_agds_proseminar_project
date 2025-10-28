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
punctuality_2025_10_11_geo <- punctuality_2025_10_11_geo %>%
  mutate(
    E_Koordinate = as.numeric(`E-Koordinate`),
    N_Koordinate = as.numeric(`N-Koordinate`)
  )

# Calculate mean punctuality (delay) per stop (only delay upon arrival)
mean_delay_per_stop <- punctuality_2025_10_11_geo %>%
  group_by(BPUIC, HALTESTELLEN_NAME) %>%
  summarise(
    mean_delay_min = mean(c(diff_arr), na.rm = TRUE),
    .groups = "drop"
  )

# Join with stop coordinates (keep coordinates and metadata)
mean_delay_geo <- mean_delay_per_stop %>%
  left_join(
    stops_selected %>%
      mutate(E_Koordinate = as.numeric(`E-Koordinate`),
             N_Koordinate = as.numeric(`N-Koordinate`)),
    by = "BPUIC"
  )

# --- 2. Convert to sf object ---
mean_delay_sf <- st_as_sf(
  mean_delay_geo,
  coords = c("E_Koordinate", "N_Koordinate"),
  crs = 2056,
  remove = FALSE
)


# Reproject to WGS84 (required for annotation_map_tile)
mean_delay_sf_wgs <- st_transform(mean_delay_sf, crs = 4326)

# Create Leaflet map
leaflet(mean_delay_sf_wgs) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%  # light grey basemap
  addCircleMarkers(
    radius = 4,
    color = ~viridis::viridis(100, option = "plasma")[cut(mean_delay_min, breaks = 100)],
    stroke = FALSE,
    fillOpacity = 0.8,
    popup = ~paste0(
      "<b>", HALTESTELLEN_NAME, "</b><br>",
      "Mean delay: ", round(mean_delay_min, 1), " min"
    )
  ) %>%
  addLegend(
    position = "bottomright",
    pal = colorNumeric(palette = "plasma", domain = mean_delay_sf_wgs$mean_delay_min),
    values = mean_delay_sf_wgs$mean_delay_min,
    title = "Mean Delay (min)"
  )