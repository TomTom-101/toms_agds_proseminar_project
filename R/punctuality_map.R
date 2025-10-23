# This script creates a map from the georeferenced punctuality data

# Load packages
library(sf)        
library(ggplot2)   
library(dplyr)
library(ggspatial)
library(prettymapr)

# Convert coordinates to numeric
punctuality_2025_10_11_geo <- punctuality_2025_10_11_geo %>%
  mutate(
    E_Koordinate = as.numeric(`E-Koordinate`),
    N_Koordinate = as.numeric(`N-Koordinate`)
  )

# Convert to sf object
punctuality_sf <- st_as_sf(
  punctuality_2025_10_11_geo,
  coords = c("E_Koordinate", "N_Koordinate"),  # order: x, y
  crs = 2056,                                  # Swiss coordinate system CH1903+ / LV95
  remove = FALSE                               # keep original columns
)

# Plot points on map
ggplot() +
  geom_sf(data = punctuality_sf, aes(color = punct_cat), size = 2) +
  theme_minimal() +
  labs(
    title = "Train Punctuality by Stop",
    color = "Punctuality"
  )

# Add basemap

ggplot() +
  annotation_map_tile("CartoDB.Positron") +  # adds a basemap
  geom_sf(data = punctuality_sf, aes(color = punct_cat), size = 2) +
  theme_minimal()

