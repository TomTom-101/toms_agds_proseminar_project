# This script calculates train punctuality based on daily actual lines ran. 
# The data is available under this URL: https://opendata.swiss/de/dataset/ist-daten-v2
# !!! IF YOU WANT TO CHANGE THE DATE YOU NEED TO SET PARAMETERS MANUALLY 
# IN LINE 21 !!!

# Load packages
library(dplyr)
library(tidyr)
library(lubridate)
library(readr)
library(stringr)
library(httr)

# Increase session timeout time to 3 minutes because of file downloading
set_config(timeout(180))  


# open URL above and choose a date at least three days ago, e.g. 2025-12-07_IstDaten.csv
# click on date, copy download-url and paste below
# read data from online source, this might take some minutes (500MB+)
daily_punct_url <- 'https://data.opentransportdata.swiss/dataset/febff1f3-ee85-470a-9487-2d07f93457c1/resource/96ac8376-bb74-4d02-843c-fc7e688f3f6f/download/2025-12-07_istdaten.csv'

# Local file in /data
destfile <- "data/daily_punct_train.csv"

# Download with progress
GET(
  daily_punct_url,
  write_disk(destfile, overwrite = TRUE),
  progress()
)

# Read downloaded file
daily_punct_raw <- read.csv(destfile, header = TRUE, sep = ';', stringsAsFactors = FALSE)

# Create new dataframe with only train data
daily_punct_raw_train <- daily_punct_raw%>%
  filter(PRODUKT_ID == "Zug")

# Filter for only swiss trains by BPUIC Code 
# Basic format: UIC country code (2-digit) e.g. 85,  UIC stop code (5-digit): e.g. 03000, stop code (optional): e.g. 02. Gives: 850300002

daily_punct_raw_train <- daily_punct_raw_train %>%
  filter(str_starts(BPUIC, "85"))


# Calculate punctuality
daily_punct_raw_train <- daily_punct_raw_train%>%
  # convert times
  mutate(
    ANKUNFTSZEIT = dmy_hm(ANKUNFTSZEIT),
    AN_PROGNOSE  = dmy_hms(AN_PROGNOSE),
    ABFAHRTSZEIT = dmy_hm(ABFAHRTSZEIT),
    AB_PROGNOSE  = dmy_hms(AB_PROGNOSE)
  ) %>%
  # calculate differences between planned and actual arrival and departure
  mutate(
    diff_arr = as.numeric(difftime(ANKUNFTSZEIT, AN_PROGNOSE, units = "mins")),
    diff_dep = as.numeric(difftime(ABFAHRTSZEIT, AB_PROGNOSE, units = "mins"))
  ) %>%
  # assign category
  mutate(
    punct_cat = case_when(
      diff_arr > 0 ~ "delayed",     # delayed if arrival > 0 minutes late
      TRUE ~ "punctual"
    )
  )

# quick summary to check plausibility
punct_summary <- daily_punct_raw_train %>%
  summarise(
    total_trains = n(),
    delayed_trains = sum(punct_cat == "delayed", na.rm = TRUE),
    punctual_trains = sum(punct_cat == "punctual", na.rm = TRUE),
    punctuality_rate = round(100 * punctual_trains / total_trains, 2),
    punctuality_mean_min = mean(diff_arr, na.rm = TRUE)
  )

print(punct_summary)





