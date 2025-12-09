# this script downloads, reads, stacks and prepares for plotting the radar precipitation data
# The data is available under this URL: https://data.geo.admin.ch/browser/index.html#/collections/ch.meteoschweiz.ogd-radar-precip?.language=en
# !!! IF YOU WANT TO CHANGE THE DATE YOU NEED TO SET PARAMETERS MANUALLY
# IN LINE 17 AND ONCE IN 63 !!! 

library(httr)
library(jsonlite)
library(terra)
library(dplyr)
library(leaflet)
library(viridis)
library(leafem)

# adjust URL below and insert the same date as for 01_punctuality.R, eg. /20251206-ch
# read data from online source

stac_url <- "https://data.geo.admin.ch/api/stac/v0.9/collections/ch.meteoschweiz.ogd-radar-precip/items/20251206-ch"
resp <- GET(stac_url)
stop_for_status(resp)
item <- fromJSON(content(resp, as="text", encoding="UTF-8"), flatten = TRUE)

asset_hrefs <- vapply(item$assets, function(a) a$href, FUN.VALUE = character(1))
cpc_urls <- asset_hrefs[grep("/cpc", asset_hrefs)]

download_dir <- "CPC_daily_precip"
dir.create(download_dir, showWarnings = FALSE)

files <- character(0)
for(url in cpc_urls){
  destfile <- file.path(download_dir, basename(url))
  if(!file.exists(destfile)){
    message("Downloading ", basename(url))
    download.file(url, destfile, mode="wb")
  }
  files <- c(files, destfile)
}

# Read HDF5 CPC files as terra raster 
r_list <- list()
for(f in files){
  r <- tryCatch({
    rast(f, subds="data")  # select the "data" subdataset
  }, error=function(e){ warning("Failed: ", f); NULL })
  if(!is.null(r)) r_list[[basename(f)]] <- r
}

# Stack all 10-min rasters 
combined <- rast(r_list)

# Create 10-min timestamps
time_steps <- seq(as.POSIXct("2025-11-25 00:00:00", tz="UTC"),
                  by="10 min", length.out = length(r_list))

# Aggregate to hourly precipitation
# 1 hour = 6 x 10-min layers
hourly_stack <- rast()
for(h in 0:23){
  idx <- (h*6 + 1):(h*6 + 6)
  hourly_stack <- c(hourly_stack, sum(combined[[idx]], na.rm=TRUE))
}
names(hourly_stack) <- paste0("hour_", 0:23)

# Reproject to WGS84 for Leaflet
hourly_stack_wgs <- project(hourly_stack, "EPSG:4326")

# Plot on Leaflet
hour_to_plot <- 8  # choose hour 0-23
first_hour <- hourly_stack_wgs[[hour_to_plot + 1]]

# Color palette
pal_precip <- colorNumeric(palette="viridis", values(first_hour), na.color="transparent")

leaflet() %>%
  addProviderTiles(providers$OpenStreetMap) %>%
  addRasterImage(first_hour, colors = pal_precip, opacity = 0.7) %>%
  addLegend(pal = pal_precip, values = values(first_hour),
            title = paste0("Hourly Precipitation [mm] (Hour ", hour_to_plot, ")"))
