.dotter <- function(ndots, maxlength) {
    paste0(
        paste0(rep(".", times = ndots), collapse = ""),
        paste0(rep(" ", times = maxlength-ndots), collapse = ""),
        collapse = ""
    )
}

#' @title Import Data from the Human Cell Atlas Data Portal or the AnVIL Data
#'   Repository to a Terra Workspace
#'
#' @description This function is intended to facilitate the import of data from
#'   the Human Cell Atlas Data Portal or the AnVIL Data Repository. It is
#'   designed to create a manifest for the specified filters and format, and
#'   then import the data into a Terra workspace. The function takes advantage
#'   of the `Azul` class to interact with the Human Cell Atlas API and the
#'   `AnVIL` package to manage the Terra workspace and import job.
#'
#' @inheritParams Azul-utils
#'
#' @param namespace `character(1)` AnVIL workspace namespace as returned by,
#'   e.g., `AnVILGCP::avworkspace_namespace()`, where the data will be imported.
#'
#' @param name `character(1)` AnVIL workspace name as returned by, e.g.,
#'   `AnVILGCP::avworkspace_name()`, where the data will be imported.
#'
#' @param filters `list()` A list of filters to apply when preparing the
#'   manifest. The filters should be structured according to the requirements of
#'   the Human Cell Atlas API, and will be converted to JSON format before being
#'   sent in the request to the API. See the details section for more
#'   information on the expected structure of the filters.
#'
#' @param format `character(1)` The format of the manifest to be prepared.
#'   Currently, only "terra.pfb" is supported, which prepares the manifest in a
#'   format suitable for import into Terra.
#'
#' @details The `filters` parameter should be a list that specifies the criteria
#'   for selecting the data to be imported.
#'
#'   Each filter consists of a field name, a relation (relational operator), and
#'   an array of field values. The available relations are "is", "within",
#'   "contains", and "intersects". Multiple filters are combined using "and"
#'   logic. An entity must match all filters to be included in the response. How
#'   multiple field values within a single filter are combined depends on the
#'   relation.
#'
#'   For the "is" relation, multiple values are combined using "or"
#'   logic. For example, `list(fileFormat = list(is = c("fastq", "fastq.gz")))`
#'   selects entities where the file format is either "fastq" or "fastq.gz". For
#'   the "within", "intersects", and "contains" relations, the field values must
#'   come in nested pairs specifying upper and lower bounds, and multiple pairs
#'   are combined using "and" logic. For example,
#'   `list(donorCount = list(within = matrix(c(1, 5, 5, 10), 2L, 2L, TRUE)))`
#'   selects entities whose donor organism count falls within both ranges, i.e.,
#'   is exactly 5. The accessions field supports filtering for a specific
#'   accession and/or namespace within a project. For example,
#'   ```r
#'   list(
#'       accessions = list(
#'           is = data.frame(namespace = "array_express")
#'       )
#'   )
#'   ```
#'   will filter for projects that have an `array_express`
#'   accession. Similarly,
#'   ```r
#'   list(
#'       accessions = list(
#'           is = data.frame(accession = "ERP112843")
#'       )
#'   )
#'   ```
#'   will filter for projects that have the accession `ERP112843` while
#'
#'   ```r
#'   list(
#'       accessions = list(
#'           is = data.frame(
#'               namespace = "array_express",
#'               accession = "E-AAAA-000"
#'           )
#'       )
#'   )
#'   ```
#'   will filter for projects that match both values. The `organismAge` field is
#'   special in that it contains two property keys: `value` and `unit`. For
#'   example,
#'
#'   ```r
#'   list(
#'       organismAge = list(
#'           is = data.frame(value = "20", unit = "year")
#'       )
#'   )
#'   ```
#'   Both keys are required. `list(organismAge = list(is = NA))` selects
#'   entities that have no organism age.
#'
#' @importFrom AnVIL Terra
#'
#' @seealso [makeFilter()]
#'
#' @examplesIf interactive()
#' azul <- Azul()
#' importToTerra(
#'     azul,
#'     namespace = "anvil-namespace",
#'     name = "my-anvil-workspace",
#'     catalog = "dcp56",
#'     filters = list(
#'         projectId = list(is = "74b6d569-3b11-42ef-b6b1-a0454522b4a0")
#'     )
#' )
#'
#' @export
importToTerra <- function(
    api, namespace, name, filters,
    catalog = c("dcp56", "dcp57", "lm10"),
    format = "terra.pfb"
) {
    catalog <- match.arg(catalog)
    stopifnot(
        "Only 'terra.pfb' is currently supported" =
            identical(format, "terra.pfb")
    )
    jfilters <- jsonlite::toJSON(filters)
    prep_manif <- api$Initiate_the_preparation_of_a_manifest_via_XHR(
        catalog = catalog,
        filters = jfilters,
        format = format
    )

    service_url <- httr::content(prep_manif)[["Location"]]

    if (grepl("service.azul.data", service_url))
        service_url <- httr::GET(service_url) |>
            httr::content() |>
            `[[`(_, "Location")

    terra <- Terra()
    tryCatch({
        AnVILPublish:::.create_workspace(
            namespace = namespace,
            name = name
        )
    }, error = function(e) {
        if (!grepl("already exists", conditionMessage(e)))
            stop("Failed to create workspace: ", conditionMessage(e))
        else
            message("Workspace already exists: ", namespace, "/", name)
    })
    job_result <- terra$createImportJob(
        workspaceNamespace = namespace,
        workspaceName = name,
        filetype = "pfb",
        url = service_url
    )
    jobId <- httr::content(job_result)[["jobId"]]
    message("Import job created with jobId: ", jobId)

    .poll_import_job(terra, namespace, name, jobId)
}

#' @importFrom progress progress_bar
.poll_import_job <- function(
    terra, namespace, name, jobId,
    timeout = getOption("BiocAzul.timeout", 300L)
) {
    .get_status <- function() {
        terra$importJobStatus(
            workspaceNamespace = namespace,
            workspaceName = name,
            jobId = jobId
        ) |>
            httr::content()
    }

    terminal_states <- c("Done", "Error")

    start_time <- proc.time()[["elapsed"]]
    attempt <- 1L

    pb <- progress::progress_bar$new(
        format = "  (:spin) Importing to Terra:dots :elapsed",
        total = NA,
        clear = FALSE
    )

    repeat {
        elapsed <- proc.time()[["elapsed"]] - start_time

        if (elapsed >= timeout)
            stop(
                "Import job timed out after ", timeout, " seconds",
                call. = FALSE
            )

        jobStatus <- tryCatch(
            .get_status(),
            error = function(e) {
                warning("Failed to poll job status: ", conditionMessage(e))
                NULL
            }
        )

        if (!is.null(jobStatus)) {
            status <- jobStatus[["status"]]
            if (status %in% terminal_states) {
                pb$terminate()
                if (identical(status, "Error"))
                    stop(
                        "Import job failed (jobId: ", jobId, "):\n  ",
                        jobStatus[["message"]] %||% "no details provided"
                    )
                message(
                    "Import complete in ", round(elapsed), " seconds"
                )
                return(
                    invisible(
                        list(
                            jobId = jobId,
                            status = status,
                            elapsed = round(elapsed)
                        )
                    )
                )
            }
        }

        steps <- 10L
        for (i in seq_len(steps)) {
            pb$tick(tokens = list(dots = .dotter(i, 10)))
            Sys.sleep(30 / steps)
        }
        attempt <- attempt + 1L

    }
}
