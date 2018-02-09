
**Please note:** this package is new and hasn’t yet been extensively
tested. Use due diligence when handling sensitive or confidential data.

# Installation

‘deidentifyr’ isn’t on CRAN yet. You can install it from github with
‘devtools’:

``` r
devtools::install_github('wilkox/deidentifyr')
```

# Walkthrough

Here’s an example dataset containing some patient data.

``` r
set.seed(1)
n <- 10
MRNs <- sample(10000000:99999999, n)
DOBs <- lubridate::today() - lubridate::dyears(sample(18:99, n, replace = T))
times_in_hospital <- sample(1:100, n, replace = T)
patient_data <- data.frame(MRN = MRNs, DOB = DOBs, 
                           time_in_hospital = times_in_hospital)
patient_data
#>         MRN        DOB time_in_hospital
#> 1  33895779 1984-02-18               94
#> 2  43491150 1986-02-17               22
#> 3  61556802 1944-02-28               66
#> 4  91738701 1969-02-21               13
#> 5  28151373 1937-03-01               27
#> 6  90855071 1960-02-24               39
#> 7  95020774 1942-02-28                2
#> 8  69471801 1919-03-06               39
#> 9  66620263 1969-02-21               87
#> 10 15560764 1937-03-01               35
```

There are two variables in this data frame containing personally
identifying information: `MRN` and `DOB`. We could just remove these
columns and generate a random ID number for each patient, but that would
make it difficult to match the patients if we wanted to merge two data
frames together. The solution is to generate a unique ID code, a
cryptographic hash (SHA-256), from the identifying columns. This type of
hash has two useful properties: it is very unlikely that the same hash
would be generated for two people who have different information; and it
is near impossible to recover the personal information from the hash.

We can generate these unique IDs with the `deidentify()` function. The
first argument to `deidentify()` is the data fame, and after that we can
list the columns from which to generate the IDs.

``` r
library(deidentifyr)
patient_data <- deidentify(patient_data, MRN, DOB)
patient_data
#>            id time_in_hospital
#> 1  7c99da8378               94
#> 2  769acfc516               22
#> 3  0f437bde45               66
#> 4  e236830e21               13
#> 5  7f04ba20cc               27
#> 6  ed312918e2               39
#> 7  097ae04e49                2
#> 8  d4a731d59f               39
#> 9  44f5ec49a4               87
#> 10 cfac1d6216               35
```

The `MRN` and `DOB` columns have been removed, and replaced with a new
column called `id` containing a unique hash for each patient. If you
don’t want to remove the original columns, `deidentify()` can be
called with the argument `drop = FALSE`. You can also choose a different
name for the ID column with `key = "name"`.

The same values for each identifying column will always generate the
same hash. This means that a different data frame deidentified in the
same way will have the same IDs for each patient.

``` r
sexes <- sample(c("F", "M"), n, replace = T)
patient_data2 <- data.frame(MRN = MRNs, DOB = DOBs, 
                           sex = sexes)
patient_data2
#>         MRN        DOB sex
#> 1  33895779 1984-02-18   F
#> 2  43491150 1986-02-17   M
#> 3  61556802 1944-02-28   F
#> 4  91738701 1969-02-21   F
#> 5  28151373 1937-03-01   M
#> 6  90855071 1960-02-24   M
#> 7  95020774 1942-02-28   M
#> 8  69471801 1919-03-06   F
#> 9  66620263 1969-02-21   M
#> 10 15560764 1937-03-01   F
patient_data2 <- deidentify(patient_data2, DOB, MRN)
patient_data2
#>            id sex
#> 1  7c99da8378   F
#> 2  769acfc516   M
#> 3  0f437bde45   F
#> 4  e236830e21   F
#> 5  7f04ba20cc   M
#> 6  ed312918e2   M
#> 7  097ae04e49   M
#> 8  d4a731d59f   F
#> 9  44f5ec49a4   M
#> 10 cfac1d6216   F
```

Note that the ID hashes are identical in `patient_data` and
`patient_data2` even though we listed the identifying columns in a
different order the second time we called `deidentify()`. We can now
match patients between the data frames without needing to reidentify
them.

``` r
combined_data <- merge(patient_data, patient_data2, by = "id")
combined_data
#>            id time_in_hospital sex
#> 1  097ae04e49                2   M
#> 2  0f437bde45               66   F
#> 3  44f5ec49a4               87   M
#> 4  769acfc516               22   M
#> 5  7c99da8378               94   F
#> 6  7f04ba20cc               27   M
#> 7  cfac1d6216               35   F
#> 8  d4a731d59f               39   F
#> 9  e236830e21               13   F
#> 10 ed312918e2               39   M
```

# Similar packages

  - [anonymizer](https://github.com/paulhendricks/anonymizer) takes a
    slightly different approach to the same problem.
