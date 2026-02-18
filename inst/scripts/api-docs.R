# setwd("~/bioc/BiocAzul")
file_loc <- "inst/service/azul/api.json"

download.file(
    url = "https://service.azul.data.humancellatlas.org/openapi.json",
    destfile = file_loc
)

apilines <- readLines("R/Azul.R")

.AZUL_LINE <- ".AZUL_API_REFERENCE_VERSION <-"

versionline <- grep(
    pattern = .AZUL_LINE,
    x = apilines,
    fixed = TRUE,
    value = TRUE
)
oldver <- unlist(strsplit(versionline, "\""))[[2L]]
newver <-
    jsonlite::fromJSON(file_loc, simplifyVector = FALSE)[[c("info", "version")]]

## success -- updated API files and MD5
if (!identical(oldver, newver)) {
    lineIdx <- grep(pattern = .AZUL_LINE, x = apilines, fixed = TRUE)
    apilines[lineIdx] <- paste0(.AZUL_LINE, " \"", newver, "\"")
    writeLines(apilines, con = file("R/Azul.R"))

    ## update the API file
    oldwd <- setwd("inst/service/azul")
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
