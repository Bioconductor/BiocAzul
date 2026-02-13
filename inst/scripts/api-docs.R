# setwd("~/bioc/BiocAzul")
file_loc <- "inst/service/Azul/api.json"

download.file(
    url = "https://service.azul.data.humancellatlas.org/openapi.json",
    destfile = file_loc
)

md5 <- digest::digest(file_loc, file = TRUE)
apilines <- readLines("R/Azul.R")
mdline <- grep("\"[0-9a-f]{32}\"", apilines, value = TRUE)
oldmd5 <- unlist(strsplit(mdline, "\""))[[2]]
updatedlines <- gsub("\"[0-9a-f]{32}\"", dQuote(md5, FALSE), apilines)

## success -- updated API files and MD5
if (!identical(oldmd5, md5)) {
    writeLines(updatedlines, con = file("R/Azul.R"))
    quit(status = 0)
} else {
    ## failure -- API the same
    quit(status = 1)
}
