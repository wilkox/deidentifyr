# Some example data
library(tidyverse)
library(lubridate)
set.seed(1)
n <- 10000
MRNs <- sample(10000000:99999999, n)
DOBs <- today() - dyears(sample(18:99, n, replace = T))
times_in_hospital <- sample(1:100, n, replace = T)
patient_data <- data.frame(MRN = MRNs, DOB = DOBs, time_in_hospital = times_in_hospital)

data <- patient_data
columns <- c("MRN", "DOB")

patient_data <- as.tibble(patient_data)
deidentify(patient_data, MRN, DOB)

# Function to deidentify information
deidentify <- function(data, ..., key = "id", drop = TRUE) {

  # Capture columns with the magic of NSE
  columns <- as.character(eval(substitute(alist(...))))

  # Ensure the data doesn't already contain a column with the key name
  if (key %in% names(data)) {
    stop("data already contains a column named ", key)
  }

  # Check that observations are unique for the selected columns
  unique_obs <- nrow(unique(data[, columns]))
  if (unique_obs != nrow(data)) {
    warning("Duplicate rows found in selected columns - duplicate ids will be produced")
  }

  # Sort columns, to reduce the chance of creating different hashes from
  # different data frames by accidentally listing the columns in the wrong order
  columns <- sort(columns)

  # Paste and hash columns, keeping only 10 characters of the hash
  # Using the SHA-256 algorithm
  input <- apply(data[, columns], 1, paste, collapse = "")
  hashes <- sapply(input, digest::digest, algo = "sha256", USE.NAMES = F)
  hashes <- substr(hashes, 0, 10)

  # Warn if there is a hash collision
  unique_hashes <- length(unique(hashes))
  if (unique_hashes != length(input)) {
    warning("A hash collision (duplicate ids) was produced")
  }

  # Add hashes column to left side of the data frame, using dplyr::bind_cols if
  # it is a tibble
  # We don't need to require the tibble package, as if the user is working with
  # a tibble, it is reasonable to assume it is available
  if ("tbl_df" %in% class(data)) {
    data <- tibble::add_column(data, id = hashes, .before = 1)
  } else {
    data <- cbind(data.frame(id = hashes, stringsAsFactors = F), data)
  }

  # Drop the identifying columns, if wanted
  if (drop) {
    data[columns] <- NULL
  }

  # Return data
  data
}
