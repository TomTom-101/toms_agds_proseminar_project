# This script references names of stops to according geographical coordinates
# The data is available under https://data.opentransportdata.swiss/dataset/service-points-actual-date/resource_permalink/actual_date-swiss-only-service_point-2025-10-20.csv.zip

# Load packages
library(dplyr)
library(tidyr)
library(lubridate)
library(readr)
library(sf)
library(tidyverse)


# Step 1: Read the CSV (unzipping on the fly)
url <- "https://data.opentransportdata.swiss/dataset/c8ed76a6-2960-4529-af6e-069a72c47268/resource/b17ad6e0-cfe7-482c-962f-3ae8cbb33fc2/download/actual_date-swiss-only-service_point-2025-10-20.csv.zip"

# Read directly from zip
temp <- tempfile()
download.file(url, temp)
csv_file <- unzip(temp, list = TRUE)$Name[1]  # assumes first file in zip
stops <- read_delim(unzip(temp, files = csv_file), delim = ";")

