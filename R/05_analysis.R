# this script puts together punctuality and precipitation for all stations and hours

library(terra)
library(dplyr)
library(tidyr)
library(sf)
library(leaflet)
library(viridis)
library(ggplot2)

# Visualisation
# Choose hour to display
hour_to_plot <- 8  # 0–23

# Filter stations for that hour 
delay_hour_subset <- delay_sf_hourly_wgs %>%
  filter(hour == hour_to_plot)

# Extract precipitation raster for that hour 
precip_r <- hourly_stack_wgs[[hour_to_plot + 1]]

#  Extract precipitation at station locations 
station_vect <- vect(delay_hour_subset)          # convert sf to terra vector
delay_hour_subset$precip_mm <- terra::extract(precip_r, station_vect)[,2]

#  Color palettes 
pal_precip <- colorNumeric("viridis", values(precip_r), na.color = "transparent")
pal_delay  <- colorNumeric("plasma", delay_hour_subset$delay_rate)

#  Leaflet map 
leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  
  # Raster layer for precipitation
  addRasterImage(
    precip_r,
    colors = pal_precip,
    opacity = 0.6,
    group = "Precipitation"
  ) %>%
  
  # Delay points layer
  addCircleMarkers(
    data = delay_hour_subset,
    radius = 5,
    color = ~pal_delay(delay_rate),
    stroke = FALSE,
    fillOpacity = 0.9,
    popup = ~paste0(
      "<b>", HALTESTELLEN_NAME, "</b><br>",
      "Hour: ", hour, ":00<br>",
      "Delay rate: ", round(delay_rate * 100, 1), "%<br>",
      "Precipitation: ", round(precip_mm, 2), " mm"
    ),
    group = "Delay rate"
  ) %>%
  
  
  # Legends
  addLegend(
    "bottomright", pal = pal_delay, values = delay_hour_subset$delay_rate,
    title = paste0("Delay rate @ ", hour_to_plot, ":00")
  ) %>%
  addLegend(
    "bottomleft", pal = pal_precip, values = values(precip_r),
    title = paste0("Hourly precipitation (mm) @ ", hour_to_plot, ":00")
  )


# Investigate Correlation
# copy relevant df from punctuality analysis
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


# Remove rows with missing precipitation or delay_rate
analysis_df <- station_delay_precip %>%
  st_drop_geometry() %>%
  filter(!is.na(precip_mm), !is.na(delay_rate))

# 1. Global correlation (all stations × all hours)
cor_all <- cor(analysis_df$precip_mm, analysis_df$delay_rate, use = "complete.obs")
cat("Global correlation (all stations × all hours):", round(cor_all, 3), "\n")

# 2. Hourly correlation
cor_hourly <- analysis_df %>%
  group_by(hour) %>%
  summarise(correlation = cor(precip_mm, delay_rate, use = "complete.obs"))

print(cor_hourly)

# 3. Scatterplot: precipitation vs delay rate (all hours)
ggplot(analysis_df, aes(x = delay_rate, y = precip_mm)) +
  geom_point(alpha = 0.3, color = "steelblue") +
  geom_smooth(method = "lm", se = FALSE, color = "red") +
  theme_minimal() +
  labs(
    title = "Correlation between Precipitation and Train Delay Rate",
    x = "Precipitation (mm)",
    y = "Delay rate"
  )

# 4. Binned analysis: average delay per precipitation class
precip_bins <- analysis_df %>%
  mutate(precip_class = cut(precip_mm, breaks = c(0, 0.2, 1, 3, 10, Inf))) %>%
  group_by(precip_class) %>%
  summarise(
    mean_delay = mean(delay_rate, na.rm = TRUE),
    n_stations = n()
  )

print(precip_bins)

# 5. Optional: barplot of mean delay per precipitation bin
ggplot(precip_bins, aes(x = precip_class, y = mean_delay)) +
  geom_col(fill = "steelblue") +
  theme_minimal() +
  labs(
    title = "Mean Delay Rate per Precipitation Level",
    x = "Precipitation class (mm)",
    y = "Mean delay rate"
  )

