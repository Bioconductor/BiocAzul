#' @importFrom AnVIL Terra
.get_terra <- local({
    terra <- NULL
    renew <- NULL
    function() {
        if (is.null(terra) || Sys.time() > renew) {
            renew <<- Sys.time() + 3600L
            terra <<- Terra()
        }
        terra
    }
})

#' @importFrom httr status_code
.create_workspace <-
    function(namespace, name)
{
    createWorkspace <- .get_terra()$createWorkspace
    response <- createWorkspace(
        namespace = namespace,
        name = name,
        attributes = list(
            description = jsonlite::unbox(
                "Workspace created programmatically by BiocAzul"
            )
        )
    )
    if (status_code(response) >= 400L)
        .stop(response, namespace, name, "create workspace failed")
}

#' @importFrom httr status_code http_status content
.stop <-
    function(response, namespace, name, text)
{
    message <- content(response)$message
    if (is.null(message))
        message <- paste(as.character(content(response)), collapse = "\n")
    stop(
        text,
        "\nworkspace: ", namespace, "/", name,
        "\nstatus code: ", status_code(response),
        "\nhttp status: ", http_status(response)$message,
        "\nresponse content:\n", message,
        call. = FALSE
    )
}
