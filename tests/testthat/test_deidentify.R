context("deidentify()")

MRNs <- 1:10
ages <- 18:27
times_in_hospital <- 1:10
patient_data <- data.frame(MRN = MRNs, age = ages, 
                           time_in_hospital = times_in_hospital)


test_that("Cryptographic hashes are created from identifying columns", {
  expect_silent(deidentified <- deidentify(patient_data, MRN, age))
  expect_true(is.character(deidentified$id))
  expect_equal(unique(nchar(deidentified$id)), 10)
})

test_that("Columns are not dropped if requested", {
  expect_silent(deidentified <- deidentify(patient_data, MRN, age, drop = F))
  expect_equal(names(deidentified), c("id", "MRN", "age", "time_in_hospital"))
})

test_that("Hash column takes a custom name", {
  expect_silent(deidentified <- deidentify(patient_data, MRN, age, key = "hash"))
  expect_equal(names(deidentified)[1], "hash")
})

test_that("Salting works", {
  expect_silent(deidentified_salt <- deidentify(patient_data, MRN, age, salt = "kosher", 
                                                key = "hash"))
  deidentified <- deidentify(patient_data, MRN, age, key = "hash")
  expect_false(all(deidentified$hash == deidentified_salt$hash))
})
