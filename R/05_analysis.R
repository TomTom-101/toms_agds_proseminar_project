# This script matches punctuality and precipitation data and investigates correlation

# Load packages
library(sf)
library(dplyr)
library(ggplot2)
library(stars)
library(tidyr)

# Ensure CRS match
delay_sf <- st_transform(delay_sf, 2056)

# Extract precipitation for each station
# stars::st_extract returns raster values at point locations
precip_values <- st_extract(daily_total, delay_sf)

# precip_values is a stars object → convert to numeric vector
delay_sf$precip_mm <- as.numeric(precip_values[[1]])

# Inspect merged dataset
head(delay_sf)

# Remove stations with NA precipitation (e.g. outside radar domain)
delay_data <- delay_sf %>%
  st_drop_geometry() %>%
  filter(!is.na(precip_mm))

# ---------- CORRELATION ANALYSIS ----------

# 1) Simple Pearson correlation
cor_test <- cor.test(delay_data$delay_rate, delay_data$precip_mm, method = "pearson")
print(cor_test)

# 2) Spearman (robust against non-linearity)
cor_test_s <- cor.test(delay_data$delay_rate, delay_data$precip_mm, method = "spearman")
print(cor_test_s)

# ---------- VISUALISATION ----------
ggplot(delay_data, aes(x = precip_mm, y = delay_rate)) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm", se = TRUE, color = "red") +
  labs(
    title = "Relationship between Precipitation and Train Delay Rate",
    x = "Daily total precipitation [mm]",
    y = "Delay rate per station"
  ) +
  theme_minimal()

# ---------- OPTIONAL: SIMPLE LINEAR MODEL ----------
model <- lm(delay_rate ~ precip_mm, data = delay_data)
summary(model)

# ---------- OPTIONAL: NON-LINEAR (e.g., log + polynomial) ----------
model2 <- lm(delay_rate ~ poly(precip_mm, 2), data = delay_data)
summary(model2)
