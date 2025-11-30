# -----------------------------------------
# Hourly precipitation map (fast raster tiles)
# -----------------------------------------

library(httr)
library(jsonlite)
library(terra)
library(dplyr)
library(leaflet)
library(viridis)
library(leafem)

# ---- 1. Download CPC radar files ----
stac_url <- "https://data.geo.admin.ch/api/stac/v0.9/collections/ch.meteoschweiz.ogd-radar-precip/items/20251125-ch"
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

# ---- 2. Read HDF5 CPC files as terra raster ----
r_list <- list()
for(f in files){
  r <- tryCatch({
    rast(f, subds="data")  # select the "data" subdataset
  }, error=function(e){ warning("Failed: ", f); NULL })
  if(!is.null(r)) r_list[[basename(f)]] <- r
}

# ---- 3. Stack all 10-min rasters ----
combined <- rast(r_list)

# ---- 4. Create 10-min timestamps ----
time_steps <- seq(as.POSIXct("2025-11-25 00:00:00", tz="UTC"),
                  by="10 min", length.out = length(r_list))

# ---- 5. Aggregate to hourly precipitation ----
# 1 hour = 6 x 10-min layers
hourly_stack <- rast()
for(h in 0:23){
  idx <- (h*6 + 1):(h*6 + 6)
  hourly_stack <- c(hourly_stack, sum(combined[[idx]], na.rm=TRUE))
}
names(hourly_stack) <- paste0("hour_", 0:23)

# ---- 6. Reproject to WGS84 for Leaflet ----
hourly_stack_wgs <- project(hourly_stack, "EPSG:4326")

# ---- 7. Plot on Leaflet ----
hour_to_plot <- 8  # choose hour 0-23
first_hour <- hourly_stack_wgs[[hour_to_plot + 1]]

# Color palette
pal_precip <- colorNumeric(palette="viridis", values(first_hour), na.color="transparent")

leaflet() %>%
  addProviderTiles(providers$OpenStreetMap) %>%
  addRasterImage(first_hour, colors = pal_precip, opacity = 0.7) %>%
  addLegend(pal = pal_precip, values = values(first_hour),
            title = paste0("Hourly Precipitation [mm] (Hour ", hour_to_plot, ")"))
