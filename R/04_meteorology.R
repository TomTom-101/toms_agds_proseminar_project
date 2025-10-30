# ===============================
# MeteoSwiss CombiPrecip 25 Oct 2025
# Full workflow: download -> read -> stack -> prepare for plotting
# ===============================

# --- Packages ---
packages <- c("httr", "jsonlite", "stars", "dplyr", "ggplot2", "gganimate")
install.packages(setdiff(packages, rownames(installed.packages())), dependencies=TRUE)

library(httr)
library(jsonlite)
library(stars)
library(dplyr)
library(ggplot2)
library(gganimate)
library(viridis)
library(leaflet)
library(leafem)

# Fetch STAC item for 25 Oct 2025 ---
stac_url <- "https://data.geo.admin.ch/api/stac/v0.9/collections/ch.meteoschweiz.ogd-radar-precip/items/20251025-ch"

resp <- GET(stac_url)
stop_for_status(resp)
item <- fromJSON(content(resp, as="text", encoding="UTF-8"), flatten = TRUE)

# Extract CPC asset URLs
asset_hrefs <- vapply(item$assets, function(a) a$href, FUN.VALUE = character(1))
cpc_urls <- asset_hrefs[grep("/cpc", asset_hrefs)]
length(cpc_urls)


# --- 2. Download CPC files ---
download_dir <- "CPC_2025-10-25"
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

# --- 3. Read CPC HDF5 files as stars objects ---
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

# --- 4. Combine 2D stars objects into a 3D stars object along "time" ---
combined <- do.call(c, c(cpc_list, along = "time"))

# Create 10-min time steps
time_steps <- seq(as.POSIXct("2025-10-25 00:00:00", tz="UTC"),
                  by = "10 min",
                  length.out = length(cpc_list))

# Assign values to the "time" dimension
combined <- st_set_dimensions(combined, "time", values = time_steps)

# --- 5. Convert to dataframe for ggplot ---
df <- as.data.frame(combined, xy=TRUE)
colnames(df)[3] <- "precip"
df$time <- rep(time_steps, each = nrow(df)/length(time_steps))

cat("Dataframe ready for plotting. Rows:", nrow(df), "\n")






# Visualisation for plausibility check
# 1. Aggregate over time
daily_total <- st_apply(combined, c("x","y"), sum, na.rm = TRUE)

# 2. Keep CRS as LV95 (EPSG:2056)
st_crs(daily_total) <- 2056

# 3. Create color palette
pal <- colorNumeric(palette = "plasma", domain = as.vector(daily_total[[1]]), na.color = "transparent")

# 4. Leaflet map with stars object directly
leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addStarsImage(daily_total, colors = pal, opacity = 0.8) %>%
  addLegend(pal = pal, values = as.vector(daily_total[[1]]),
            title = "Total Precipitation [mm]",
            position = "bottomright")

