# this script downloads, reads, stacks and prepares for plotting the radar precipitation data
# The data is available under this URL: https://data.geo.admin.ch/browser/index.html#/collections/ch.meteoschweiz.ogd-radar-precip?.language=en
# !!! IF YOU WANT TO CHANGE THE DATE YOU NEED TO SET PARAMETERS MANUALLY
# IN LINE 17 AND ONCE IN 63 !!! 

library(httr)
library(jsonlite)
library(stars)
library(dplyr)
library(ggplot2)
library(gganimate)
library(viridis)
library(leaflet)
library(leafem)

# adjust URL below and insert the same date as for 01_punctuality.R, eg. /20251127-ch
# read data from online source

stac_url <- "https://data.geo.admin.ch/api/stac/v0.9/collections/ch.meteoschweiz.ogd-radar-precip/items/20251125-ch"

resp <- GET(stac_url)
stop_for_status(resp)
item <- fromJSON(content(resp, as="text", encoding="UTF-8"), flatten = TRUE)

# Extract CPC asset URLs
asset_hrefs <- vapply(item$assets, function(a) a$href, FUN.VALUE = character(1))
cpc_urls <- asset_hrefs[grep("/cpc", asset_hrefs)]
length(cpc_urls)


# download CPC files only
# This might take a while (ca. 150 individual files)
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

# read CPC HDF5 files as stars objects
cpc_list <- list()
for(f in files){
  s <- tryCatch({
    read_stars(f, sub="data")
  }, error=function(e){
    warning("Failed to read ", f)
    NULL
  })
  if(!is.null(s)){
    st_crs(s) <- 2056
    cpc_list[[basename(f)]] <- s
  }
}

# Combine 2D stars objects into a 3D stars object along time
combined <- do.call(c, c(cpc_list, along = "time"))

# Set date chosen above to create time steps
# Create 10-min time steps
time_steps <- seq(as.POSIXct("2025-11-25 00:00:00", tz="UTC"),
                  by = "10 min",
                  length.out = length(cpc_list))

# Assign values to time dimension
combined <- st_set_dimensions(combined, "time", values = time_steps)

# Convert to dataframe for ggplot
df <- as.data.frame(combined, xy=TRUE)
colnames(df)[3] <- "precip"
df$time <- rep(time_steps, each = nrow(df)/length(time_steps))

cat("Dataframe ready for plotting. Rows:", nrow(df), "\n")

# Create hourly breaks and labels
hourly_breaks <- seq(from = min(time_steps), to = max(time_steps) + 1, by = "1 hour")  # +1 to include last interval
hour_labels <- hourly_breaks[-length(hourly_breaks)]

# Initialize list to store hourly slices
hourly_list <- list()

for (i in seq_along(hour_labels)) {
  idx <- which(time_steps >= hourly_breaks[i] & time_steps < hourly_breaks[i+1])
  # Sum 10-min slices within the hour
  hourly_slice <- apply(combined[,,,idx][[1]], c(1,2), sum, na.rm = TRUE)
  hourly_list[[i]] <- hourly_slice
}

# Convert list of hourly matrices to stars object
hourly_total <- do.call(c, lapply(hourly_list, function(mat) {
  st_as_stars(mat, dimensions = st_dimensions(combined)[1:2])
}))

# Assign hourly time dimension
st_dimensions(hourly_total)$time <- hour_labels
st_crs(hourly_total) <- 2056

# -------------------------------
# Leaflet map: visualize first hour
pal_precip <- colorNumeric(
  palette = "viridis",
  domain = c(0, max(as.numeric(hourly_total[[1]]), na.rm = TRUE)),
  na.color = "transparent"
)

leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addStarsImage(hourly_total[,,,1], colors = pal_precip, opacity = 0.8) %>%
  addLegend(
    pal = pal_precip,
    values = as.vector(hourly_total[,,,1][[1]]),
    title = "Hourly Precipitation [mm]",
    position = "bottomright"
  )