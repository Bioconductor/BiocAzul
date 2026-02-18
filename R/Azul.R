.api_header <- function(x) x@api_header

#' @importFrom methods is
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

#' @name Azul
#'
#' @docType class
#'
#' @aliases Azul-class
#'
#' @title The R Interface to the Human Cell Atlas Data Portal
#'
#' @description The `Azul` class provides an interface to the Human Cell Atlas
#'   Data Portal API, allowing users to access and query the data portal
#'   programmatically. The class establishes a connection to the API and
#'   retrieves the OpenAPI specification, which defines the available endpoints
#'   and their parameters. Users can then use this connection to make requests
#'   to the API and retrieve data from the Human Cell Atlas Data Portal.
#'
#' @importFrom methods new
#'
#' @return An `Azul` object that can be used to interact with the Human Cell
#'   Atlas API
#'
#' @seealso [AnVIL::Service-class]
#'
#' @examples
#' showClass("Azul")
#'
#' @exportClass Azul
.Azul <- setClass(
    "Azul",
    contains = "Service",
    slots = c(api_header = "character")
)

#' @rdname Azul
#'
#' @param hostname `character(1)` The internet location of the service (default:
#'   'service.azul.data.humancellatlas.org').
#'
#' @param protocol `character(1)` The internet protocol used to access the
#'   hostname (default: 'https')
#'
#' @param api. `character(1)` The directory location of the API protocol within
#'   the hostname (default: '/openapi.json').
#'
#' @param token `character(1)` The Authorization Bearer token e.g.,
#'   "63eba81c-2591-4e15-9d1c-fb6e8e51e35d" or a path to text file.
#'
#' @importFrom AnVIL Service
#'
#' @examples
#' azul <- Azul()
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
            api_reference_md5sum = "5927c881b5ffced463f47b65c8662a16",
            api_reference_headers = token,
            package = "BiocAzul",
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

#' @rdname Azul
#'
#' @details `operations`: List all the `operations` available with the Azul
#'   API object, e.g., `api$operation`
#'
#' @importFrom AnVIL operations
#'
#' @importFrom methods callNextMethod
#'
#' @param x An `Azul` instance or API representation as
#'   given by the [Azul()] function.
#'
#' @inheritParams AnVIL::operations
#'
#' @exportMethod operations
setMethod(
    "operations", "Azul",
    function(x, ..., .deprecated = FALSE)
    {
        callNextMethod(
            x, .headers = .api_header(x), ..., .deprecated = .deprecated
        )
    }
)
