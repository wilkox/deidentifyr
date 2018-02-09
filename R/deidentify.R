#' Deidentify a data frame.
#'
#' `deidentify()` will generate a unique ID from personally identifying
#' information. Because the IDs are generated with the SHA-256 algorithm, they
#' are a) very unlikely to be the same for people with different identifying
#' information, and b) nearly impossible to recover the identifying information
#' from.
#'
#' This function uses non-standard evaluation for column names in `data`, so
#' there's no need to surround them with quotation marks.
#'
#' @param data A data frame (or tibble).
#' @param ... A list of the columns in `data` that contain personally
#' identifying information, from which the unique IDs will be generated.
#' @param key The name of the column to create containing unique IDs, "id" by
#' default.
#' @param drop A logical value, TRUE by default, indicating whether to remove
#' the personally identifying columns after the IDs are created.
#'
#' @export
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
  names(data)[1] <- key

  # Drop the identifying columns, if wanted
  if (drop) {
    data[columns] <- NULL
  }

  # Return data
  data
}
