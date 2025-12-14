# This script creates a map from the georeferenced punctuality data

# Load packages
library(terra)
library(ggplot2)
library(dplyr)
library(tidyr)
library(viridis)
library(lubridate)
library(gganimate)
library(magick)  
library(rnaturalearth)
library(sf)

# Convert coordinates to numeric
daily_punct_train_geo <- daily_punct_train_geo %>%
  mutate(
    E_Koordinate = as.numeric(`E-Koordinate`),
    N_Koordinate = as.numeric(`N-Koordinate`)
  )

# Add hour column based on actual arrival time
daily_punct_train_geo <- daily_punct_train_geo %>%
  mutate(hour = hour(ANKUNFTSZEIT))

# Calculate delay rate and total delay minutes per stop and per hour
delay_rate_hourly <- daily_punct_train_geo %>%
  group_by(BPUIC, HALTESTELLEN_NAME, hour) %>%
  summarise(
    n_trains = n(),
    n_delayed = sum(punct_cat == "delayed", na.rm = TRUE),
    delay_rate = n_delayed / n_trains,
    total_delay_min = sum(diff_arr, na.rm = TRUE),  
    .groups = "drop"
  )

# Join with coordinates
delay_geo_hourly <- delay_rate_hourly %>%
  inner_join(
    stops_selected %>%
      mutate(
        E_Koordinate = as.numeric(`E-Koordinate`),
        N_Koordinate = as.numeric(`N-Koordinate`)
        ),
    by = "BPUIC"
  )

# Convert to terra SpatVector (LV95 → WGS84)
delay_vect <- vect(
  delay_geo_hourly,
  geom = c("E_Koordinate", "N_Koordinate"),
  crs = "EPSG:2056"
)

delay_vect <- project(delay_vect, "EPSG:4326")

# Convert to data.frame for ggplot
delay_df <- as.data.frame(delay_vect)
coords <- crds(delay_vect)            # Extract coordinates as a matrix
delay_df$x <- coords[,1]              # Longitude
delay_df$y <- coords[,2]              # Latitude

# Load Switzerland outline
switzerland <- ne_countries(country = "Switzerland", scale = "medium", returnclass = "sf")
switzerland <- st_transform(switzerland, crs = 4326)

# Create plot for every hour
for (h in 0:23) {
  
  # Filter data for this hour
  delay_hour <- delay_df %>% filter(hour == h)
  
  # Skip hour if no data
  if (nrow(delay_hour) == 0) next
  
  # Create plot
  punct_hour <- ggplot() +
    geom_sf(data = switzerland, fill = "gray95", color = "gray70") +
    geom_point(
      data = delay_hour,
      aes(x = x, y = y, color = delay_rate),
      size = 2,
      alpha = 0.8
    ) +
    scale_color_viridis(
      option = "plasma",
      name = "Delay rate",
      labels = scales::percent,
      limits = c(0, 1)
    ) +
    coord_sf(xlim = c(5.95, 10.5), ylim = c(45.8, 47.9)) +
    labs(
      title = paste("Train Delay Rate at", h, ":00"),
      subtitle = "Share of delayed trains per stop",
      x = "Longitude",
      y = "Latitude"
    ) +
    theme_minimal()
  
  # Format hour with leading zero
  hour_str <- sprintf("%02d", h)
  
  # Save plot
  ggsave(
    filename = paste0("figures/", hour_str, "_punctuality_map.png"),
    plot = punct_hour,
    width = 8,
    height = 6,
    dpi = 300
  )
}

# create gif
# List all hourly PNG files 
files <- list.files("figures", pattern = "^\\d{2}_punctuality_map\\.png$", full.names = TRUE)

# Order files numerically by hour to ensure correct sequence
hours <- as.numeric(str_extract(files, "^\\d{2}"))
files_ordered <- files[order(hours)]

# Read images
imgs <- image_read(files_ordered)

# Create GIF
punct_gif <- image_animate(imgs, fps = 1)

# Save GIF
image_write(punct_gif, "figures/punctuality_map_all_hours.gif")


