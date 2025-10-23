# This script calculates train punctuality based on daily actual lines ran. 
# The data is available under this URL: https://opendata.swiss/de/dataset/ist-daten-v2

# Load packages
library(dplyr)
library(tidyr)
library(lubridate)
library(readr)
library(stringr)

# Read data from online source
ist_2025_10_11 <- 'https://data.opentransportdata.swiss/dataset/febff1f3-ee85-470a-9487-2d07f93457c1/resource/42fafc47-199d-4626-ae1e-edb34abdc382/download/2025-10-11_istdaten.csv'
ist_2025_10_11 <- read.csv(ist_2025_10_11, header = TRUE, sep = ';', stringsAsFactors = FALSE)

# Create new dataframe with only train data
punctuality_2025_10_11 <- ist_2025_10_11%>%
  filter(PRODUKT_ID == "Zug")

# Filter for only swiss trains by BPUIC Code 
# Basic format: UIC country code (2-digit) e.g. 85,  UIC stop code (5-digit): e.g. 03000, stop code (optional): e.g. 02. Gives: 850300002

punctuality_2025_10_11 <- punctuality_2025_10_11 %>%
  filter(str_starts(BPUIC, "85"))


# Calculate punctuality
punctuality_2025_10_11 <- punctuality_2025_10_11%>%
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
punct_summary <- punctuality_2025_10_11 %>%
  summarise(
    total_trains = n(),
    delayed_trains = sum(punct_cat == "delayed", na.rm = TRUE),
    punctual_trains = sum(punct_cat == "punctual", na.rm = TRUE),
    punctuality_rate = round(100 * punctual_trains / total_trains, 2)
  )

print(punct_summary)





