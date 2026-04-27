# setwd("~/bioc/BiocAzul")
## service <- "hca"
## service <- "anvil"
file_loc <- glue::glue("inst/service/{service}/openapi.json")

service_url <- switch(
    service,
    hca = "service.azul.data.humancellatlas.org",
    anvil = "service.explore.anvilproject.org"
)

download.file(
    url = glue::glue("https://{service_url}/openapi.json"),
    destfile = file_loc
)

apilines <- readLines("R/Azul.R")

.API_LINE <- glue::glue(".{toupper(service)}_API_REFERENCE_VERSION <-")

versionline <- grep(
    pattern = .API_LINE,
    x = apilines,
    fixed = TRUE,
    value = TRUE
)
oldver <- unlist(strsplit(versionline, "\""))[[2L]]
newver <-
    jsonlite::fromJSON(file_loc, simplifyVector = FALSE)[[c("info", "version")]]

## success -- updated API files and MD5
if (!identical(oldver, newver)) {
    lineIdx <- grep(pattern = .API_LINE, x = apilines, fixed = TRUE)
    apilines[lineIdx] <- paste0(.API_LINE, " \"", newver, "\"")
    writeLines(apilines, con = file("R/Azul.R"))

    ## update the API file
    oldwd <- setwd(glue::glue("inst/service/{service}"))
    on.exit(setwd(oldwd))
    system2(
        command = "api-spec-converter",
        args = "-f openapi_3 -t swagger_2 openapi.json > api.json",
        stdout = TRUE
    )

    quit(status = 0)
} else {
    ## failure -- API the same
    quit(status = 1)
}
