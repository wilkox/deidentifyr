context("deidentify()")

MRNs <- 1:10
ages <- 18:27
times_in_hospital <- 1:10
patient_data <- data.frame(MRN = MRNs, age = ages, 
                           time_in_hospital = times_in_hospital)
deidentified <- deidentify(patient_data, MRN, age)

test_that("Cryptographic hashes are created from identifying columns", {
  expect_true(is.character(deidentified$id))
  expect_equal(unique(nchar(deidentified$id)), 10)
})

deidentified <- deidentify(patient_data, MRN, age, drop = F)

test_that("Columns are not dropped if requested", {
  expect_equal(names(deidentified), c("id", "MRN", "age", "time_in_hospital"))
})

deidentified <- deidentify(patient_data, MRN, age, key = "hash")

test_that("Hash column takes a custom name", {
  expect_equal(names(deidentified)[1], "hash")
})
