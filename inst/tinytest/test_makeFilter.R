# Basic equality filter
expect_equal(
    makeFilter(~ projectId == "74b6d569-3b11-42ef-b6b1-a0454522b4a0"),
    list(projectId = list(is = "74b6d569-3b11-42ef-b6b1-a0454522b4a0"))
)

# Multiple values for equality filter
expect_equal(
    makeFilter(~ fileFormat == c("fastq", "fastq.gz")),
    list(fileFormat = list(is = c("fastq", "fastq.gz")))
)

# Combined filters with '&'
expect_equal(
    makeFilter(
        ~ projectId == "74b6d569-3b11-42ef-b6b1-a0454522b4a0" &
            genusSpecies == "Mus musculus" &
            fileFormat == "h5"
    ),
    list(
        projectId = list(is = "74b6d569-3b11-42ef-b6b1-a0454522b4a0"),
        genusSpecies = list(is = "Mus musculus"),
        fileFormat = list(is = "h5")
    )
)

# Within operator with nested list/vector
expect_equal(
    makeFilter(~ donorCount %within% list(c(1, 5), c(5, 10))),
    list(donorCount = list(within = matrix(c(1, 5, 5, 10), 2L, 2L, TRUE)))
)
# Within operator with matrix
expect_equal(
    makeFilter(~ donorCount %within% matrix(c(1, 5, 5, 10), 2L, 2L, TRUE)),
    list(donorCount = list(within = matrix(c(1, 5, 5, 10), 2L, 2L, TRUE)))
)

# Complex accessions filter
expect_equal(
    makeFilter(~ accessions == list(namespace = "array_express")),
    list(
        accessions = list(
            is = data.frame(namespace = "array_express")
        )
    )
)

expect_equal(
    makeFilter(~ accessions == list(accession = "ERP112843")),
    list(
        accessions = list(
            is = data.frame(accession = "ERP112843")
        )
    )
)

expect_equal(
    makeFilter(
        ~ accessions == list(
            namespace = "array_express", accession = "E-AAAA-000"
        )
    ),
    list(
        accessions = list(
            is = data.frame(
                namespace = "array_express",
                accession = "E-AAAA-000"
            )
        )
    )
)

# Organism age filter with NULL
expect_equal(
    makeFilter(~ organismAge == NULL),
    list(organismAge = list(is = NA))
)

# Organism age filter with NA
expect_equal(
    makeFilter(~ organismAge == NA),
    list(organismAge = list(is = NA))
)

# Organism age filter with value and unit
expect_equal(
    makeFilter(~ organismAge == list(value = "20", unit = "year")),
    list(
        organismAge = list(
            is = data.frame(value = "20", unit = "year")
        )
    )
)

# %contains% operator
expect_error(
    makeFilter(~ fileFormat %contains% "fastq")
)
expect_equal(
    makeFilter(~ donorCount %contains% list(c(1, 5), c(5, 10))),
    list(donorCount = list(contains = matrix(c(1, 5, 5, 10), 2L, 2L, TRUE)))
)

# %intersect% operator
expect_equal(
    makeFilter(~ donorCount %intersect% list(c(1, 5), c(5, 10))),
    list(donorCount = list(intersect = matrix(c(1, 5, 5, 10), 2L, 2L, TRUE)))
)

# Error cases for %within%
expect_error(
    makeFilter(~ donorCount %within% "not a list"),
    "Right-hand side of '%within%' operator must be a list of length 2 vectors or a matrix"
)

expect_error(
    makeFilter(~ donorCount %within% list(c(1, 2, 3))),
    "Right-hand side of '%within%' operator must be a list of length 2 vectors or a matrix"
)
