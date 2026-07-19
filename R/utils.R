# =============================================================================
# Internal helpers, mirrored from `epishiny` so this package is self-contained
# and passes R CMD check without using `epishiny:::` (which would NOTE).
#
# Keep these in sync with `R/utils.R` in the parent `epishiny` package. If you
# change semantics here, prefer to upstream the change to `epishiny` first and
# then mirror it back, so all module packages stay consistent.
# =============================================================================

#' Add module-package shared assets to the page
#'
#' Mirrors `epishiny:::use_epishiny()` but points at this package's own
#' `inst/assets/` tree (registered in [.onLoad]). Call once per UI from your
#' module's `*_ui()` function. Wrap in [shiny::singleton()] so it is only
#' inserted into the DOM once.
#'
#' Rename this function (e.g. `use_epishiny_lab`) and update the `src=`/
#' `href=` prefixes when you fork this template.
#'
#' @return A `<head>` tag list wrapped in [shiny::singleton()].
#' @noRd
use_epishiny_template <- function() {
  header <- shiny::tags$head(
    shiny::tags$script(src = "epishiny.template/js/main.js"),
    shiny::tags$link(
      rel = "stylesheet",
      type = "text/css",
      href = "epishiny.template/css/styles.css"
    ),
    shinyjs::useShinyjs()
  )
  shiny::singleton(header)
}

#' Pipe operator re-export
#' @importFrom magrittr %>%
#' @noRd
magrittr::`%>%`

#' Definition operator re-export
#' @importFrom rlang :=
#' @noRd
rlang::`:=`

#' Force evaluation of reactive expressions
#'
#' Returns `x()` if `x` is reactive, otherwise `x` unchanged. Module servers
#' use this so they can be called with either a static data frame or a
#' [shiny::reactive()] returning one.
#'
#' @param x A reactive expression or regular value.
#' @return The evaluated reactive expression or the original value.
#' @noRd
force_reactive <- function(x) {
  if (shiny::is.reactive(x)) x() else x
}

#' Generate a `YYYY-MM-DD_HHMMSS` timestamp
#' @noRd
time_stamp <- function() {
  format(Sys.time(), "%Y-%m-%d_%H%M%S")
}

#' Look up a label for a selected choice
#'
#' For a named character vector of choices, return the name corresponding to
#' the selected value, falling back to a default label.
#'
#' @param selected The selected choice.
#' @param choices A named character vector of choices.
#' @param .default Default label. Defaults to `getOption("epishiny.count.label", "N")`.
#' @noRd
get_label <- function(selected,
                      choices,
                      .default = getOption("epishiny.count.label", "N")) {
  if (length(choices)) {
    lab <- choices[choices == selected]
    ifelse(rlang::is_named(lab), names(lab), lab)
  } else {
    .default
  }
}

#' Format cross-module filter info text
#'
#' Combines the running filter-info HTML string with time- and place-filter
#' updates triggered by chart / map clicks in sibling modules. Returns an
#' HTML-formatted string suitable for display in a chart subtitle / caption.
#'
#' @param fi Existing filter info text.
#' @param tf Time filter info (list with `$lab`).
#' @param pf Place filter info (list with `$level_name`, `$region_name`).
#' @noRd
format_filter_info <- function(fi = NULL, tf = NULL, pf = NULL) {
  if (length(tf)) {
    if (length(fi)) {
      fi <- sub(
        "\\d{2}/[A-Za-z]{3}/\\d{2} - \\d{2}/[A-Za-z]{3}/\\d{2}",
        tf$lab,
        fi
      )
    } else {
      fi <- paste("<b>Filters applied</b></br>Period:", tf$lab)
    }
  }
  if (length(pf)) {
    pf_lab <- paste0(pf$level_name, ": ", pf$region_name)
    if (length(fi)) {
      fi <- paste0(fi, "</br>", pf_lab)
    } else {
      fi <- paste0("<b>Filters applied</b></br>", pf_lab)
    }
  }
  fi
}

#' Default categorical color palettes
#'
#' Mirrors `epishiny:::epi_pals()`. Use `epi_pals()$frost` etc. as the default
#' for module palette arguments so colours match the parent package.
#' @noRd
epi_pals <- function() {
  list(
    frost   = c("#5E81AC", "#81A1C1", "#88C0D0", "#8FBCBB"),
    aurora  = c("#BF616A", "#D08770", "#EBCB8B", "#A3BE8C", "#B48EAD"),
    vibrant = c("#0077BB", "#33BBEE", "#009988", "#EE7733", "#CC3311", "#EE3377"),
    muted   = c("#332288", "#88CCEE", "#44AA99", "#117733", "#999933",
                "#DDCC77", "#CC6677", "#882255", "#AA4499")
  )
}
