# this script puts together punctuality and precipitation for all stations and hours

library(terra)
library(dplyr)
library(ggplot2)
library(viridis)
library(magick)
library(stringr)
library(sf)
library(rnaturalearth)

# Load Switzerland outline
switzerland <- ne_countries(
  country = "Switzerland",
  scale = "medium",
  returnclass = "sf"
)
switzerland <- st_transform(switzerland, 4326)

# Convert punctuality data to terra vector for extraction
delay_vect <- vect(
  delay_df,
  geom = c("x", "y"),
  crs = "EPSG:4326"
)

# Global scales for consistency
delay_max  <- 1
precip_max <- max(values(hourly_stack), na.rm = TRUE)

# Create combined plots for every hour

for(h in 0:23){
  
  # Filter stations for this hour
  delay_hour <- delay_df %>% filter(hour == h)
  if(nrow(delay_hour) == 0) next
  
  # Extract precipitation raster
  precip_r <- hourly_stack[[h + 1]]
  
  # Extract precipitation at station locations
  delay_hour_vect <- vect(
    delay_hour,
    geom = c("x", "y"),
    crs = "EPSG:4326"
  )
  
  delay_hour$precip_mm <- terra::extract(
    precip_r,
    delay_hour_vect
  )[, 2]
  
  # Raster to data.frame for ggplot
  precip_df <- as.data.frame(precip_r, xy = TRUE)
  colnames(precip_df) <- c("x", "y", "precip")
  
  # Plot
  combined_hour <- ggplot() +
    geom_raster(
      data = precip_df,
      aes(x = x, y = y, fill = precip)
    ) +
    geom_sf(
      data = switzerland,
      fill = NA,
      color = "gray30",
      size = 0.4
    ) +
    geom_point(
      data = delay_hour,
      aes(x = x, y = y, color = delay_rate),
      size = 2,
      alpha = 0.9
    ) +
    scale_fill_viridis(
      name = "Precipitation [mm]",
      limits = c(0, precip_max),
      na.value = "transparent"
    ) +
    scale_color_viridis(
      option = "plasma",
      name = "Delay rate",
      limits = c(0, delay_max),
      labels = scales::percent
    ) +
    coord_sf(
      xlim = c(5.95, 10.5),
      ylim = c(45.8, 47.9)
    ) +
    labs(
      title = paste("Punctuality & Precipitation at", sprintf("%02d:00", h)),
      subtitle = "Train delay rate (points) and hourly precipitation (raster)",
      x = "Longitude",
      y = "Latitude"
    ) +
    theme_minimal()
  
  # Save plot
  hour_str <- sprintf("%02d", h)
  ggsave(
    filename = paste0("figures/", hour_str, "_combined_map.png"),
    plot = combined_hour,
    width = 8,
    height = 6,
    dpi = 300
  )
}


# Create GIF

files <- list.files(
  "figures",
  pattern = "^\\d{2}_combined_map\\.png$",
  full.names = TRUE
)

hours <- as.numeric(str_extract(files, "^\\d{2}"))
files_ordered <- files[order(hours)]

imgs <- image_read(files_ordered)
combined_gif <- image_animate(imgs, fps = 1)

image_write(
  combined_gif,
  "figures/punct_precip_all_hours.gif"
)

# Investigate Correlation
# Prepare station SpatVector (WGS84)

station_vect <- vect(
  delay_df,
  geom = c("x", "y"),
  crs = "EPSG:4326"
)


# Extract precipitation per station & hour

delay_df$precip_mm <- NA_real_

for (h in 0:23) {
  
  idx <- which(delay_df$hour == h)
  if (length(idx) == 0) next
  
  r <- hourly_stack[[h + 1]]
  
  vals <- terra::extract(r, station_vect[idx, ])[, 2]
  
  delay_df$precip_mm[idx] <- vals
}

# Prepare analysis dataset

delay_df <- delay_df %>%
  filter(!is.na(precip_mm), !is.na(delay_rate))


# Global correlation precip and delay rate

cor_all <- cor(
  delay_df$precip_mm,
  delay_df$delay_rate,
  use = "complete.obs"
)

cat(
  "Global correlation (all stations × all hours):",
  round(cor_all, 3), "\n"
)


# Hourly correlation

cor_hourly <- delay_df %>%
  group_by(hour) %>%
  summarise(
    correlation = cor(precip_mm, delay_rate, use = "complete.obs"),
    n = n(),
    .groups = "drop"
  )

print(cor_hourly)

# Scatterplot: precipitation vs delay rate

p_corr <- ggplot(delay_df, aes(x = precip_mm, y = delay_rate)) +
  geom_point(alpha = 0.25, color = "steelblue") +
  geom_smooth(method = "lm", se = FALSE, color = "red") +
  theme_minimal() +
  labs(
    title = "Correlation between Precipitation and Train Delay Rate",
    subtitle = paste("Global r =", round(cor_all, 3)),
    x = "Precipitation (mm)",
    y = "Delay rate"
  )

ggsave(
  "figures/precipitation_delay_correlation.png",
  plot = p_corr,
  width = 7,
  height = 5,
  dpi = 300
)

# Filter out stations with excessive total delay
delay_df_filter <- delay_df %>% 
  filter(total_delay_min < 1000)

# Global correlation precip and delay minutes
cor_all_2 <- cor(
  delay_df_filter$precip_mm,
  delay_df_filter$total_delay_min,
  use = "complete.obs"
)

# Scatterplot: precipitation vs total delay minutes
pmin_corr <- ggplot(delay_df_filter, aes(x = precip_mm, y = total_delay_min)) +
  geom_point(alpha = 0.25, color = "steelblue") +
  geom_smooth(method = "lm", se = FALSE, color = "red") +
  theme_minimal() +
  labs(
    title = "Correlation between Precipitation and Total Delay Minutes",
    subtitle = paste("Global r =", round(cor_all_2, 3)),
    x = "Precipitation (mm)",
    y = "Delay minutes"
  )

ggsave(
  "figures/precipitation_delaymin_correlation.png",
  plot = pmin_corr,
  width = 7,
  height = 5,
  dpi = 300
)


# Heatmap
p_heat <- ggplot(delay_df, aes(x = precip_mm, y = delay_rate)) +
  stat_bin2d(bins = 40) +
  scale_fill_viridis(
    name = "Count",
    trans = "sqrt"
  ) +
  theme_minimal() +
  labs(
    title = "Precipitation vs Train Delay Rate",
    subtitle = paste("Global correlation r =", round(cor_all, 3)),
    x = "Precipitation (mm)",
    y = "Delay rate"
  )

ggsave(
  "figures/precipitation_delay_heatmap.png",
  plot = p_heat,
  width = 7,
  height = 5,
  dpi = 300
)


# Binned analysis

precip_bins <- delay_df %>%
  mutate(
    precip_class = cut(
      precip_mm,
      breaks = c(0, 0.2, 1, 3, 10, Inf),
      include.lowest = TRUE
    )
  ) %>%
  group_by(precip_class) %>%
  summarise(
    mean_delay = mean(delay_rate, na.rm = TRUE),
    n_obs = n(),
    .groups = "drop"
  )


# Barplot of mean delay per precipitation bin

p_bin <- ggplot(precip_bins, aes(x = precip_class, y = mean_delay)) +
  geom_col(fill = "steelblue") +
  theme_minimal() +
  labs(
    title = "Mean Delay Rate per Precipitation Level",
    x = "Precipitation class (mm)",
    y = "Mean delay rate"
  )

ggsave(
  "figures/precipitation_delay_bins.png",
  plot = p_bin,
  width = 7,
  height = 5,
  dpi = 300
)
