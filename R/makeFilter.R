.is_op <- function() {
    function(e1, e2) {
        force(e1)
        force(e2)
        if (is.list(e2))
            e2 <- as.data.frame(e2)
        if (is.null(e2))
            e2 <- NA
        structure(
            list(
                list(is = e2)
            ),
            .Names = e1
        )
    }
}

.combine_op <- function() {
    function(e1, e2) {
        force(e1)
        force(e2)
        c(e1, e2)
    }
}

.op_gen <- function(type = c("within", "contains", "intersect")) {
    function(e1, e2) {
        force(e1)
        force(e2)
        allLen2 <- TRUE
        if (is.list(e2)) {
            allLen2 <- all(
                vapply(
                    e2, function(x) identical(length(x), 2L), logical(1L)
                )
            )
        }
        if ((!is.list(e2) && !is.matrix(e2)) || !allLen2)
            stop(
                "Right-hand side of '%within%' operator must be a list",
                " of length 2 vectors or a matrix",
                call. = FALSE
            )
        if (is.list(e2))
            e2 <- do.call(rbind, e2)
        structure(
            list(
                structure(
                    list(e2),
                    .Names = type
                )
            ),
            .Names = e1
        )
    }
}

.contains_op <- function() {
    function(e1, e2) {
        force(e1)
        force(e2)
        structure(
            list(
                list(contains = e2)
            ),
            .Names = e1
        )
    }
}

.f_env <- new.env(parent = emptyenv())
.f_env$`&` <- .combine_op()
.f_env$`==` <- .is_op()
.f_env$`%within%` <- .op_gen("within")
.f_env$`%contains%` <- .op_gen("contains")
.f_env$`%intersect%` <- .op_gen("intersect")
.f_env$list <- list
.f_env$c <- c
.f_env$matrix <- matrix

.collect_fields <- function(expr) {
    if (is.symbol(expr))
        as.character(expr)
    else if (is.call(expr))
        unlist(lapply(as.list(expr)[-1L], .collect_fields))
    else
        character(0)
}

#' Convert a formula to a filter list
#'
#' @param expr A one-sided formula, e.g. \code{~ projectId == "abc"}
#'
#' @return A named list suitable for JSON serialization
#'
#' @examples
#' makeFilter(~ projectId == "abc" & organism == "Homo sapiens")
#' makeFilter(~ donorCount %within% list(c(1, 5), c(5, 10)))
#'
#' @export
makeFilter <- function(expr) {
    fcomps <- rlang::f_rhs(expr)

    eval_env <- new.env(parent = as.environment(as.list(.f_env)))

    fields <- .collect_fields(fcomps)
    for (field in fields)
        assign(field, field, envir = eval_env)

    eval(fcomps, envir = eval_env)
}
