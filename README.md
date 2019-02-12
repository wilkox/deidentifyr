
[![CRAN
status](https://www.r-pkg.org/badges/version/deidentifyr)](https://cran.r-project.org/package=deidentifyr)
[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)

# Important message

This package is still under development and hasn’t yet been extensively
tested. Use due diligence when handling sensitive or confidential data.

# Installation

‘deidentifyr’ isn’t on CRAN yet. You can install it from github with
‘devtools’:

``` r
devtools::install_github('wilkox/deidentifyr')
```

# Walkthrough

Here’s an example dataset containing some patient data.

There are two variables in this data frame containing personally
identifying information: `MRN` and `DOB`. We could just remove these
columns and generate a random ID number for each patient, but that would
make it difficult to match the patients if we wanted to merge two data
frames together. The solution is to generate a unique ID code, a
cryptographic hash (SHA-256), from the identifying columns. This type of
hash has two useful properties: it is very unlikely that the same hash
would be generated for two people who have different information; and it
is near impossible to recover the personal information from the hash
(though in certain circumstances it might be very easy; see
[Salting](#salting), below). For most datasets, using only the first ten
characters of the hash is sufficient to generate unique IDs.

We can generate these unique IDs with the `deidentify()` function. The
first argument to `deidentify()` is the data frame, and after that we
can list the columns from which to generate the IDs.

``` r
library(deidentifyr)
patient_data <- deidentify(patient_data, MRN, DOB)
patient_data
#>            id days_in_hospital
#> 1  f58a379a54               94
#> 2  cce440c5bd               22
#> 3  dc670951be               66
#> 4  234f0adeb4               13
#> 5  184cde82b6               27
#> 6  1f2a3527a0               39
#> 7  bce298677f                2
#> 8  41582e0e27               39
#> 9  46e1c69542               87
#> 10 6d93cb09ee               35
```

The `MRN` and `DOB` columns have been removed, and replaced with a new
column called `id` containing a unique hash for each patient. If you
don’t want to remove the original columns, `deidentify()` can be
called with the argument `drop = FALSE`. You can also choose a different
name for the ID column with `key = "name"`.

The same identifying details will always generate the same hash. This
means that a different data frame deidentified in the same way will have
the same IDs for each patient.

``` r
patient_data2
#>         MRN        DOB sex
#> 1  33895779 1985-02-20   F
#> 2  43491150 1987-02-20   M
#> 3  61556802 1945-03-02   F
#> 4  91738701 1970-02-24   F
#> 5  28151373 1938-03-04   M
#> 6  90855071 1961-02-26   M
#> 7  95020774 1943-03-03   M
#> 8  69471801 1920-03-08   F
#> 9  66620263 1970-02-24   M
#> 10 15560764 1938-03-04   F
patient_data2 <- deidentify(patient_data2, DOB, MRN)
patient_data2
#>            id sex
#> 1  f58a379a54   F
#> 2  cce440c5bd   M
#> 3  dc670951be   F
#> 4  234f0adeb4   F
#> 5  184cde82b6   M
#> 6  1f2a3527a0   M
#> 7  bce298677f   M
#> 8  41582e0e27   F
#> 9  46e1c69542   M
#> 10 6d93cb09ee   F
```

Note that it didn’t matter that we listed the identifying columns in a
different order the second time we called `deidentify()`. We can now
match patients between the data frames without needing to reidentify
them.

``` r
combined_data <- merge(patient_data, patient_data2, by = "id")
combined_data
#>            id days_in_hospital sex
#> 1  184cde82b6               27   M
#> 2  1f2a3527a0               39   M
#> 3  234f0adeb4               13   F
#> 4  41582e0e27               39   F
#> 5  46e1c69542               87   M
#> 6  6d93cb09ee               35   F
#> 7  bce298677f                2   M
#> 8  cce440c5bd               22   M
#> 9  dc670951be               66   F
#> 10 f58a379a54               94   F
```

## Salting

In certain circumstances, there is a potential method somebody could use
to reidentify the patients. Suppose a bad actor happened to have access
to a master list of all the patients who had ever been admitted to the
hospital. If they could guess which columns (i.e. which pieces of
personally identifying information) you used to create the unique IDs,
they could generate IDs from this master list using the same hashing
method. They could then compare their IDs to the ones you created, and
figure out who each patient is in the deidentified dataset.

A solution to this is to add an extra piece of information to the hash,
which is not personally identifying information about the patients but a
secret known only to you. By adding this extra piece, called a “salt”,
completely different unique IDs will be generated. You will be able to
regenerate the same IDs from a different dataset if you wanted, by
adding the same salt, so your ability to match patients between
deidentified datasets will not be lost. However, unless the bad actor
manages to discover your secret salt, they will not be able to generate
a list of potential IDs from which to reidentify the patients. You can
add a salt by calling `deidentify()` with the extra argument `salt =
"mysalt"`.

Decisions about using or not using a salt, how to keep the salt a
secret, and what personally identifying information to include in the
hash will depend on the nature of the dataset and the context in which
it will be used. Having access to confidential data, particularly about
people’s health, is a privilege and a responsibility. Take some time to
make these decisions carefully.

# Similar packages

  - [anonymizer](https://github.com/paulhendricks/anonymizer) takes a
    different approach to the same problem.
