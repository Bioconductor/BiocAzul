#' @name Azul-utils
#'
#' @title Obtain a list of projects and their IDs from the specified catalog
#'
#' @description This function queries the specified catalog for projects and
#'   returns a tibble with project names and their corresponding IDs. The
#'   `catalog` parameter allows you to specify which catalog to query, with
#'   options including "dcp56", "dcp57", and "lm10".
#'
#' @param api `Azul` object representing the connection to the API.
#'
#' @param catalog `character(1)` specifying the catalog to query. Options
#'   include "dcp56", "dcp57", and "lm10" as given by `listCatalogs(api)`.
#'
#' @importFrom httr content
#'
#' @examples
#' azul <- Azul()
#' listCatalogs(azul)
#' projectTable(azul, catalog = "dcp56")
#' @export
projectTable <- function(
    api,
    catalog = c("dcp56", "dcp57", "lm10")
) {
    catalog <- match.arg(catalog)
    projs <- api$`Search_an_index_for_entities_of_interest\n.`(
        catalog = catalog, entity_type = "projects"
    ) |>
        content()

    projs$termFacets$project$terms |>
        dplyr::bind_rows() |>
        tidyr::unnest(cols = "projectId")
}

#' @rdname Azul-utils
#'
#' @export
listCatalogs <- function(api) {
    res <- api$List_all_available_catalogs.() |>
        content()
    res[["catalogs"]] |>
        names()
}
