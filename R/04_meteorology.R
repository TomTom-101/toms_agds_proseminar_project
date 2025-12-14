# this script downloads, reads, stacks and prepares for plotting the radar precipitation data
# The data is available under this URL: https://data.geo.admin.ch/browser/index.html#/collections/ch.meteoschweiz.ogd-radar-precip?.language=en
# !!! IF YOU WANT TO CHANGE THE DATE YOU NEED TO SET PARAMETERS MANUALLY
# IN LINE 17 AND ONCE IN 63 !!! 

library(httr)
library(jsonlite)
library(terra)
library(ggplot2)
library(viridis)
library(magick)
library(stringr)
library(rnaturalearth)
library(sf)

# Download radar CPC data
# adjust URL below and insert the same date as for 01_punctuality.R, eg. /20251207-ch
# read data from online source

download_dir <- "data/CPC_daily_precip"
dir.create(download_dir, showWarnings = FALSE)

stac_url <- "https://data.geo.admin.ch/api/stac/v0.9/collections/ch.meteoschweiz.ogd-radar-precip/items/20251207-ch"
resp <- GET(stac_url)
stop_for_status(resp)
item <- fromJSON(content(resp, as="text", encoding="UTF-8"), flatten = TRUE)

asset_hrefs <- vapply(item$assets, function(a) a$href, FUN.VALUE = character(1))
cpc_urls <- asset_hrefs[grep("/cpc", asset_hrefs)]

files <- character(0)
for(url in cpc_urls){
  destfile <- file.path(download_dir, basename(url))
  if(!file.exists(destfile)){
    message("Downloading ", basename(url))
    download.file(url, destfile, mode="wb")
  }
  files <- c(files, destfile)
}

# Read CPC HDF5 files as terra raster
r_list <- list()
for(f in files){
  r <- tryCatch({
    rast(f, subds="data")
  }, error=function(e){ warning("Failed: ", f); NULL })
  if(!is.null(r)) r_list[[basename(f)]] <- r
}

# Stack all 10-min rasters
combined <- rast(r_list)

# Aggregate to hourly precipitation (1h = 6 x 10-min)
hourly_stack <- rast()
for(h in 0:23){
  idx <- (h*6 + 1):(h*6 + 6)
  hourly_stack <- c(hourly_stack, sum(combined[[idx]], na.rm=TRUE))
}
names(hourly_stack) <- paste0("hour_", 0:23)

# Reproject to WGS84 for plotting
hourly_stack <- project(hourly_stack, "EPSG:4326")

# Load Switzerland outline
switzerland <- ne_countries(country = "Switzerland", scale = "medium", returnclass = "sf")
switzerland <- st_transform(switzerland, crs = 4326)

# Determine max precipitation across all hours for consistent scale
all_values <- values(hourly_stack)
precip_max <- max(all_values, na.rm = TRUE)

# Static hourly plots with consistent color scale
for(h in 0:23){
  
  r <- hourly_stack[[h+1]]
  
  # Convert raster to data.frame for ggplot
  df <- as.data.frame(r, xy=TRUE)
  colnames(df) <- c("x", "y", "precip")
  
  # Skip if all NA
  if(all(is.na(df$precip))) next
  
  # Plot
  precip_hour <- ggplot() +
    geom_raster(data = df, aes(x=x, y=y, fill=precip)) +
    geom_sf(data = switzerland, fill = NA, color = "gray30", size = 0.5) +
    scale_fill_viridis(
      name="Precipitation [mm]",
      limits = c(0, precip_max),  # <-- fixed color scale
      na.value="transparent"
    ) +
    coord_sf(xlim=c(5.95, 10.5), ylim=c(45.8, 47.9)) +
    labs(
      title=paste("Hourly Precipitation (Hour", h, ")"),
      x="Longitude",
      y="Latitude"
    ) +
    theme_minimal()
  
  # Save plot with leading zero
  hour_str <- sprintf("%02d", h)
  ggsave(
    filename=paste0("figures/", hour_str, "_precipitation.png"),
    plot=precip_hour,
    width=8,
    height=6,
    dpi=300
  )
}

# Create GIF from PNGs
files <- list.files("figures", pattern="^\\d{2}_precipitation\\.png$", full.names=TRUE)
hours <- as.numeric(str_extract(files, "^\\d{2}"))
files_ordered <- files[order(hours)]

imgs <- image_read(files_ordered)
precip_gif <- image_animate(imgs, fps=1)
image_write(precip_gif, "figures/precipitation_all_hours.gif")
