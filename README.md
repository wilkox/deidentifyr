
**IMPORTANT MESSAGE:** this package is still under development and
hasn’t yet been extensively tested. Use due diligence when handling
sensitive or confidential data.

# Installation

‘deidentifyr’ isn’t on CRAN yet. You can install it from github with
‘devtools’:

``` r
devtools::install_github('wilkox/deidentifyr')
```

# Walkthrough

Here’s an example dataset containing some patient data.

``` r
patient_data
#>         MRN        DOB days_in_hospital
#> 1  33895779 1984-02-19               94
#> 2  43491150 1986-02-18               22
#> 3  61556802 1944-02-29               66
#> 4  91738701 1969-02-22               13
#> 5  28151373 1937-03-02               27
#> 6  90855071 1960-02-25               39
#> 7  95020774 1942-03-01                2
#> 8  69471801 1919-03-07               39
#> 9  66620263 1969-02-22               87
#> 10 15560764 1937-03-02               35
```

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
#> 1  9d806810e3               94
#> 2  4dade63947               22
#> 3  8d170f05bd               66
#> 4  fc0a11c502               13
#> 5  15414c15be               27
#> 6  babc064c8b               39
#> 7  48bf63758e                2
#> 8  73589a05c5               39
#> 9  2a1af5d030               87
#> 10 53a943e617               35
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
#> 1  33895779 1984-02-19   F
#> 2  43491150 1986-02-18   M
#> 3  61556802 1944-02-29   F
#> 4  91738701 1969-02-22   F
#> 5  28151373 1937-03-02   M
#> 6  90855071 1960-02-25   M
#> 7  95020774 1942-03-01   M
#> 8  69471801 1919-03-07   F
#> 9  66620263 1969-02-22   M
#> 10 15560764 1937-03-02   F
patient_data2 <- deidentify(patient_data2, DOB, MRN)
patient_data2
#>            id sex
#> 1  9d806810e3   F
#> 2  4dade63947   M
#> 3  8d170f05bd   F
#> 4  fc0a11c502   F
#> 5  15414c15be   M
#> 6  babc064c8b   M
#> 7  48bf63758e   M
#> 8  73589a05c5   F
#> 9  2a1af5d030   M
#> 10 53a943e617   F
```

Note that it didn’t matter that we listed the identifying columns in a
different order the second time we called `deidentify()`. We can now
match patients between the data frames without needing to reidentify
them.

``` r
combined_data <- merge(patient_data, patient_data2, by = "id")
combined_data
#>            id days_in_hospital sex
#> 1  15414c15be               27   M
#> 2  2a1af5d030               87   M
#> 3  48bf63758e                2   M
#> 4  4dade63947               22   M
#> 5  53a943e617               35   F
#> 6  73589a05c5               39   F
#> 7  8d170f05bd               66   F
#> 8  9d806810e3               94   F
#> 9  babc064c8b               39   M
#> 10 fc0a11c502               13   F
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
a list of potential IDs from which to reidentify the patients.

Decisions about using or not using a salt, how to keep the salt a
secret, and what personally identifying information to include in the
hash will depend on the nature of the dataset and the context in which
it will be used. Having access to confidential data, particularly about
people’s health, is a privilege and a responsibility. Take some time to
make these decisions carefully.

# Similar packages

  - [anonymizer](https://github.com/paulhendricks/anonymizer) takes a
    different approach to the same problem.
