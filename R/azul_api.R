.parse_token <- function(token_file) {
    token <- try({
        as.character(read.dcf(token_file, fields = "token"))
    })
    if (is(token, "try-error"))
        token <- readLines(token_file)
    token
}

.handle_token <- function(token) {
    if (file.exists(token))
        token <- .parse_token(token)
    else if (grepl(.Platform$file.sep, token, fixed = TRUE))
        stop("The token filepath is not valid")
    token <- gsub("token: ", "", token)
    c(Authorization = paste("Bearer", token))
}

.api <- header <- function(x) x@api_header

.Azul <- setClass(
    "Azul",
    contains = "Service",
    slots = c(api_header = "character")
)

#' @export
Azul <- function(
    hostname = "service.azul.data.humancellatlas.org",
    protocol = "https",
    api. = "/openapi.json",
    token = character()
) {
    if (length(token))
        token <- .handle_token(token)
    apiUrl <- paste0(protocol, "://", hostname, api.)
    service <- withCallingHandlers({
        Service(
            service = "Azul",
            host = hostname,
            config = httr::config(
                ssl_verifypeer = 0L,
                ssl_verifyhost = 0L,
                http_version = 0L
            ),
            authenticate = FALSE,
            api_reference_url = apiUrl,
            api_reference_headers = token,
            package = "cBioPortalData",
            schemes = protocol
        )
    }, warning = function(w) {
        if (!grepl("incomplete final line", w))
            warning(w)
        invokeRestart("muffleWarning")
    })
    .Azul(
        service, api_header = token
    )
}
