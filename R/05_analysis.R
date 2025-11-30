# This script matches punctuality and precipitation data and investigates correlation

# Load packages
library(sf)
library(dplyr)
library(ggplot2)
library(stars)
library(leaflet)
library(leafem)
library(viridis)

# ----------------------------------------
# Ensure CRS match (LV95 / EPSG:2056)
delay_sf <- st_transform(delay_sf, 2056)
st_crs(daily_total) <- 2056

# Extract precipitation at station locations
precip_values <- st_extract(daily_total, delay_sf)
delay_sf$precip_mm <- as.numeric(precip_values[[1]])

# Remove stations with missing values
delay_data <- delay_sf %>%
  filter(!is.na(precip_mm))

# ----------------------------------------
# LEAFLET MAP: precipitation raster + delay rate at stations

# Create color palettes
pal_precip <- colorNumeric(palette = "viridis", domain = as.vector(daily_total[[1]]), na.color = "transparent")
pal_delay <- colorNumeric(palette = "plasma", domain = delay_data$delay_rate, na.color = "transparent")

# Transform to WGS84 for Leaflet
delay_data_wgs <- st_transform(delay_data, 4326)
daily_total_wgs <- st_transform(daily_total, 4326)

# Leaflet map
leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  
  # Add precipitation raster
  addStarsImage(daily_total_wgs, colors = pal_precip, opacity = 0.7) %>%
  
  # Add station delay points
  addCircleMarkers(
    data = delay_data_wgs,
    radius = 5,
    color = ~pal_delay(delay_rate),
    stroke = FALSE,
    fillOpacity = 0.8,
    popup = ~paste0(
      "<b>", HALTESTELLEN_NAME, "</b><br>",
      "Delay rate: ", round(delay_rate * 100, 1), " %<br>",
      "Precipitation: ", round(precip_mm, 1), " mm"
    )
  ) %>%
  
  # Legends
  addLegend(
    position = "bottomright",
    pal = pal_precip,
    values = as.vector(daily_total_wgs[[1]]),
    title = "Total Daily Precipitation [mm]"
  ) %>%
  addLegend(
    position = "bottomleft",
    pal = pal_delay,
    values = delay_data_wgs$delay_rate,
    title = "Delay rate per station"
  )

# ----------------------------------------
# CORRELATION ANALYSIS

# Convert to dataframe for correlation and plotting
delay_df <- delay_data_wgs %>% st_drop_geometry()

# Pearson correlation
cor_test <- cor.test(delay_df$delay_rate, delay_df$precip_mm, method = "pearson")
print(cor_test)

# Spearman correlation
cor_test_s <- cor.test(delay_df$delay_rate, delay_df$precip_mm, method = "spearman")
print(cor_test_s)

# Scatter plot
ggplot(delay_df, aes(x = precip_mm, y = delay_rate)) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm", se = TRUE, color = "red") +
  labs(
    title = "Relationship between Precipitation and Train Delay Rate",
    x = "Daily total precipitation [mm]",
    y = "Delay rate per station"
  ) +
  theme_minimal()

# Simple linear model
model <- lm(delay_rate ~ precip_mm, data = delay_df)
summary(model)

# Polynomial model (optional)
model2 <- lm(delay_rate ~ poly(precip_mm, 2), data = delay_df)
summary(model2)