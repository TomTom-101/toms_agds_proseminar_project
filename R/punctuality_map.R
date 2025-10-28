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

# --- 3. Plot map ---

library(ggplot2)
library(ggspatial)
library(viridis)
library(sf)
library(rosm) 



ggplot() +
  # Grey/light basemap
  annotation_map_tile(type = "cartolight") +  
  # Plot punctuality points / mean delay
  geom_sf(data = mean_delay_sf_wgs, aes(color = mean_delay_min), size = 2, alpha = 0.8) +
  scale_color_viridis_c(
    option = "plasma",
    name = "Mean Delay (min)",
    na.value = "grey80"
  ) +
  labs(
    title = "Mean Train Delay per Stop (2025-10-11)",
    subtitle = "Computed from actual vs planned arrival times",
    caption = "Data: opentransportdata.swiss / stop-points-today"
  ) +
  theme_minimal() +
  theme(
    legend.position = "right",
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 10)
  )
