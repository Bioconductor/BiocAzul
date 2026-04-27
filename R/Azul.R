.api_header <- function(x) x@api_header
.HCA_API_REFERENCE_VERSION <- "16.1"
.ANVIL_API_REFERENCE_VERSION <- "16.1"

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

.create_service <- function(provider, hostname, protocol, api.) {
    api_ref_version <- switch(
        provider,
        hca = .HCA_API_REFERENCE_VERSION,
        anvil = .ANVIL_API_REFERENCE_VERSION
    )
    withCallingHandlers({
        Service(
            service = provider,
            host = hostname,
            api_reference_version = api_ref_version,
            api_reference_url = paste0(protocol, "://", hostname, api.),
            package = "BiocAzul",
            schemes = protocol
        )
    }, warning = function(w) {
        if (!grepl("incomplete final line", w))
            warning(w)
        invokeRestart("muffleWarning")
    })
}

#' @rdname Azul
#'
#' @param provider `character(1)` The data provider to connect to. Options
#'   include "hca" for the Human Cell Atlas and "anvil" for the AnVIL Data
#'   Explorer (default: "hca").
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
#' hca <- Azul(provider = "hca")
#' @export
Azul <- function(
    provider = c("hca", "anvil"),
    protocol = "https",
    api. = "/openapi.json",
    token = character()
) {
    if (length(token))
        token <- .handle_token(token)
    provider <- match.arg(provider)
    hostname <- switch(
        provider,
        hca = "service.azul.data.humancellatlas.org",
        anvil = "service.explore.anvilproject.org"
    )
    service <- .create_service(provider, hostname, protocol, api.)
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
