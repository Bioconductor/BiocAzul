#' @name Azul-utils
#'
#' @title Obtain a list of projects and their IDs from the specified catalog
#'
#' @description This function queries the specified catalog for projects and
#'   returns a tibble with project names and their corresponding IDs. The
#'   `catalog` parameter allows you to specify which catalog to query, with
#'   options including "dcp58", "dcp59", and "lm10" (e.g., when using the Human
#'   Cell Atlas API).
#'
#' @param api `Azul` object representing the connection to the API.
#'
#' @param catalog `character(1)` specifying the catalog to query. Options are
#'   given by `listCatalogs(api)`.
#'
#' @importFrom httr content
#'
#' @returns * `projectTable`: A tibble with three columns: `term`, `count`, and
#'   `projectId`. The `term` column contains the project names, the `count`
#'   column contains the number of occurrences of each project in the specified
#'   catalog, and the `projectId` column contains the unique identifiers for
#'   each project.
#'
#' @examples
#' hca <- Azul(provider = "hca")
#'
#' catalogs <- listCatalogs(hca)
#' latest <- head(catalogs, n = 1)
#' projectTable(hca, catalog = latest)
#'
#' anvil <- Azul(provider = "anvil")
#'
#' catalogs <- listCatalogs(anvil)
#' latest <- head(catalogs, n = 1)
#' projectTable(anvil, catalog = latest)
#' @export
projectTable <- function(
    api,
    catalog
) {
    stopifnot(
        "Invalid catalog specified. Use 'listCatalogs()' for all catalogs." =
            catalog %in% listCatalogs(api)
    )
    service <- .service(api)
    enttype <- switch(service, hca = "projects", anvil = "datasets")
    projs <- api$`Search_an_index_for_entities_of_interest\n.`(
        catalog = catalog, entity_type = enttype
    ) |>
        content()
    entity <- switch(
        service,
        hca = gsub("s", "", enttype),
        anvil = paste0(enttype, ".title")
    )
    splitter <- c("termFacets", entity, "terms")

    projtab <- projs[[splitter]] |>
        dplyr::bind_rows()

    if (identical(service, "hca") && is.list(projtab[["projectId"]]))
        tidyr::unnest(projtab, cols = "projectId")
    else
        projtab
}

#' @rdname Azul-utils
#'
#' @returns * `listCatalogs`: A character vector of catalog names that are
#'   available in the API.
#'
#' @export
listCatalogs <- function(api) {
    api$List_all_available_catalogs.() |>
        content() |>
        `[[`(_, "catalogs") |>
        names()
}

#' @rdname Azul-utils
#'
#' @returns * `availableFacets`: A character vector of facet names that are
#'   available for querying in the specified catalog.
#'
#' @examples
#' catalogs <- listCatalogs(hca)
#' latest <- head(catalogs, n = 1)
#' availableFacets(hca, catalog = latest)
#'
#' catalogs <- listCatalogs(anvil)
#' latest <- head(catalogs, n = 1)
#' availableFacets(anvil, catalog = latest)
#' @export
availableFacets <- function(api, catalog) {
    stopifnot(
        "Invalid catalog specified. Use 'listCatalogs()' for all catalogs." =
            catalog %in% listCatalogs(api)
    )
    service <- .service(api)
    enttype <- switch(service, hca = "projects", anvil = "datasets")
    projects <- api$`Search_an_index_for_entities_of_interest\n.`(
        catalog = catalog, entity_type = enttype
    ) |>
        content()
    names(projects[["termFacets"]])
}

#' @rdname Azul-utils
#'
#' @param facet `character(1)` a facet term for which to produce a table of
#'   tallies. The available facets can be obtained with `availableFacets()`.
#'
#' @returns * `facetTable`: A tibble with two columns: `term` and `count`. The
#'   `term` column contains the unique values of the specified facet, and the
#'   `count` column contains the number of occurrences of each term in the
#'   projects of the specified catalog.
#'
#' @examples
#' catalogs <- listCatalogs(hca)
#' latest <- head(catalogs, n = 1)
#' facetTable(hca, "genusSpecies", latest)
#'
#' facetTable(anvil, "donors.organism_type", latest)
#' @export
facetTable <-
    function(api, facet, catalog)
{
    stopifnot(
        "Invalid catalog specified. Use 'listCatalogs()' for all catalogs." =
            catalog %in% listCatalogs(api)
    )
    service <- .service(api)
    enttype <- switch(service, hca = "projects", anvil = "datasets")

    projects <- api$`Search_an_index_for_entities_of_interest\n.`(
        catalog = catalog, entity_type = enttype
    ) |>
        httr::content()
    allFacets <- names(projects[["termFacets"]])
    stopifnot("'facet' not found in termFacets" = facet %in% allFacets)

    splitter <- c("termFacets", facet, "terms")
    projects[[splitter]] |>
        dplyr::bind_rows()
}
