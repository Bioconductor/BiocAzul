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
#' @param filters `list` A list of filters to apply when preparing the manifest.
#'   The filters should be structured according to the requirements of the Human
#'   Cell Atlas API, and will be converted to JSON format before being sent in
#'   the request to the API. See the details section for more information on the
#'   expected structure of the filters.
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
#'   `list(donorCount = list(within = list(c(1, 5), c(5, 10))))` selects
#'   entities whose donor organism count falls within both ranges, i.e., is
#'   exactly 5. The accessions field supports filtering for a specific accession
#'   and/or namespace within a project. For
#'   example,
#'   ```r
#'   list(
#'       accessions = list(
#'           is = list(list(namespace = "array_express"))
#'       )
#'   )
#'   ```
#'   will filter for projects that have an `array_express`
#'   accession. Similarly,
#'   ```r
#'   list(
#'       accessions = list(
#'           is = list(
#'               list(accession ="ERP112843")
#'           )
#'       )
#'   )
#'   ```
#'   will filter for projects that have the accession `ERP112843` while
#'
#'   ```r
#'   list(
#'       accessions = list(
#'           is = list(
#'               list(namespace = "array_express", accession = "E-AAAA-00")
#'           )
#'       )
#'   )
#'   ```
#'   will filter for projects that match both values. The organismAge field is
#'   special in that it contains two property keys: value and unit. For example,
#'
#'   ```r
#'   list(
#'      organismAge = list(
#'          is = list(
#'              list(value = "20", unit = "year")
#'          )
#'      )
#'   )
#'   ```
#'   Both keys are required. `list(organismAge = list(is = list(NULL)))` selects
#'   entities that have no organism age.
#'
#' @importFrom AnVIL Terra
#'
#' @seealso [makeFilter()]
#'
#' @examplesIf interactive()
#' importToTerra(
#'     azul,
#'     catalog = "dcp56",
#'     filters = list(
#'         projectId = list(is = "74b6d569-3b11-42ef-b6b1-a0454522b4a0")
#'     )
#' )
#'
#' @export
importToTerra <- function(
    api, namespace, name, filters,
    catalog = c("dcp56", "dcp57", "lm10"), format = "terra.pfb"
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

    service_url <- httr::content(prep_manif)$Location

    terra <- Terra()
    AnVILPublish:::.create_workspace(
        namespace = namespace,
        name = name
    )
    job_result <- terra$createImportJob(
        workspaceNamespace = namespace,
        workspaceName = workspace,
        filetype = "pfb",
        url = service_url
    )
    jobId <- httr::content(job_result)$jobId
    terra$importJobStatus(
        workspaceNamespace = namespace,
        workspaceName = workspace,
        jobId = jobId
    ) |>
        httr::content()
}
