# =============================================================================
# Placeholder module: `mymodule_ui()` / `mymodule_server()`
#
# This file is a complete, runnable skeleton demonstrating how an `epishiny`
# module is structured. Rename `mymodule` to your module's name and replace the
# body of the server with your visualisation logic.
#
# The module follows the same conventions as `epishiny`'s built-in modules
# (`time`, `place`, `person`):
#
#  * UI returns a [bslib::card] (or layout) so it composes inside dashboards.
#  * UI accepts overridable label arguments for i18n.
#  * UI calls [use_epishiny_template()] once to inject this package's assets.
#  * Server takes `df` (data frame *or* reactive returning one) and the
#    cross-module reactive vals `place_filter`, `time_filter`, `filter_info`,
#    `filter_reset` so it slots into [epishiny::epi_dashboard()] cleanly.
#  * Heavy / optional dependencies are checked at call time with
#    [rlang::check_installed()] rather than required in DESCRIPTION's Imports.
# =============================================================================

#' My module
#'
#' One-line description of what this module visualises.
#'
#' @rdname mymodule
#'
#' @param id Module id. Must match between [mymodule_ui()] and
#'   [mymodule_server()].
#' @param group_vars Optional named character vector of categorical variables
#'   for an in-card grouping select. Names are used as labels.
#' @param title Header title for the card.
#' @param icon Icon shown next to the title. Defaults to a [bsicons] glyph.
#' @param tooltip Optional hover-text shown next to the title.
#' @param opts_btn_lab Label for the options popover/sidebar trigger.
#' @param groups_lab Label for the grouping select input.
#' @param no_grouping_lab Label for the "no grouping" choice.
#' @param full_screen Add a full-screen toggle to the card?
#' @param use_sidebar If `TRUE`, render options in a right-hand [bslib::sidebar]
#'   instead of a popover. Default `FALSE`.
#' @param sidebar_title Title for the sidebar. Only used when
#'   `use_sidebar = TRUE`.
#' @param sidebar_width Width of the sidebar in pixels. Default `250`.
#'
#' @return `mymodule_ui()` returns a [bslib::card]. `mymodule_server()` returns
#'   a [shiny::reactive()] of click-event data, suitable for piping back into
#'   sibling modules' `*_filter` arguments.
#'
#' @import shiny
#' @export
#' @example inst/examples/docs/launch-module.R
mymodule_ui <- function(
  id,
  group_vars = NULL,
  title = "My module",
  icon = bsicons::bs_icon("bar-chart-line"),
  tooltip = NULL,
  opts_btn_lab = "Options",
  groups_lab = "Group data by",
  no_grouping_lab = "No grouping",
  full_screen = TRUE,
  use_sidebar = FALSE,
  sidebar_title = NULL,
  sidebar_width = 250
) {
  ns <- NS(id)

  # Optional / heavy dependencies are checked at call time, not in Imports.
  # Add any visualisation-library deps your module needs here.
  pkg_deps <- character()
  if (length(pkg_deps) && !rlang::is_installed(pkg_deps)) {
    rlang::check_installed(pkg_deps, reason = "to use the mymodule module.")
  }

  tt <- if (length(tooltip)) {
    bslib::tooltip(
      bsicons::bs_icon("info-circle", class = "ms-2 text-primary", size = "1.2em"),
      tooltip
    )
  } else {
    NULL
  }

  inputs_ui <- mymodule_options_ui(
    ns = ns,
    group_vars = group_vars,
    groups_lab = groups_lab,
    no_grouping_lab = no_grouping_lab
  )

  bslib::card(
    full_screen = full_screen,
    use_epishiny_template(),
    bslib::card_header(
      class = "d-flex align-items-center",
      tags$span(icon, title, class = "me-auto pe-2"),
      tt,
      if (!use_sidebar) {
        bslib::popover(
          title = opts_btn_lab,
          id = ns("popover"),
          placement = "left",
          trigger = bsicons::bs_icon(
            "gear",
            title = opts_btn_lab,
            class = "ms-2 text-primary",
            size = "1.2em"
          ),
          inputs_ui
        )
      } else {
        actionLink(
          ns("toggle_sidebar"),
          label = NULL,
          icon = bsicons::bs_icon("gear", class = "ms-2 text-primary", size = "1.2em"),
          title = opts_btn_lab
        )
      }
    ),
    if (use_sidebar) {
      bslib::layout_sidebar(
        sidebar = bslib::sidebar(
          id = ns("mymodule_sidebar"),
          title = sidebar_title,
          width = sidebar_width,
          position = "right",
          open = "closed",
          inputs_ui
        ),
        # ---- main output region ------------------------------------------------
        # Replace this with your visualisation output, e.g.
        #   highcharter::highchartOutput(ns("chart"))
        #   leaflet::leafletOutput(ns("map"))
        htmltools::tags$div(id = ns("output"), class = "h-100 w-100")
      )
    } else {
      htmltools::tags$div(id = ns("output"), class = "h-100 w-100")
    }
  )
}

#' @rdname mymodule
#'
#' @param df A data frame (or [shiny::reactive()] returning one) of patient-
#'   level or aggregated data.
#' @param group_pal Categorical colour palette. Defaults to the same `frost`
#'   palette used by `epishiny`.
#' @param na_colour Colour for `NA` group level.
#' @param place_filter A [shiny::reactiveVal()] that, when set, narrows `df`
#'   to a clicked admin region. Receives values produced by
#'   `epishiny::place_server()`.
#' @param time_filter A [shiny::reactiveVal()] that, when set, narrows `df` to
#'   a clicked time period. Receives values produced by
#'   `epishiny::time_server()`.
#' @param filter_info A [shiny::reactiveVal()] holding the current filter-info
#'   HTML string, kept in sync across modules.
#' @param filter_reset A [shiny::reactiveVal()] that, when bumped, signals
#'   modules to clear their internal click filters.
#'
#' @importFrom dplyr .data
#' @export
mymodule_server <- function(
  id,
  df,
  group_vars = NULL,
  group_pal = epi_pals()$frost,
  na_colour = "#666666",
  place_filter = shiny::reactiveVal(),
  time_filter = shiny::reactiveVal(),
  filter_info = shiny::reactiveVal(),
  filter_reset = shiny::reactiveVal()
) {
  shiny::moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns

      observeEvent(input$toggle_sidebar, {
        bslib::sidebar_toggle("mymodule_sidebar")
      })

      if (is.null(group_vars)) {
        shinyjs::hide("group")
      }

      # Apply upstream click-filters from sibling modules.
      df_mod <- reactive({
        df_out <- force_reactive(df)
        pf <- place_filter()
        tf <- time_filter()
        if (length(pf)) {
          df_out <- df_out %>% dplyr::filter(.data[[pf$geo_col]] == pf$region_select)
        }
        if (length(tf) && !is.null(tf$date_col) && !is.null(tf$range)) {
          df_out <- df_out %>%
            dplyr::filter(
              .data[[tf$date_col]] >= tf$range[[1]],
              .data[[tf$date_col]] <= tf$range[[2]]
            )
        }
        df_out
      })

      # Combined filter-info string for chart subtitles / captions.
      filter_info_out <- reactive({
        format_filter_info(filter_info(), tf = time_filter(), pf = place_filter())
      })

      # ---- TODO: render output ----------------------------------------------
      # output$chart <- highcharter::renderHighchart({
      #   df_curve <- df_mod()
      #   ...
      # })

      # Modules typically return click-event data so callers can wire it into
      # the cross-module `*_filter` reactiveVals.
      shiny::reactive({
        NULL
      })
    }
  )
}

# -----------------------------------------------------------------------------
# Internal: options panel shared between popover & sidebar layouts.
# Keep non-exported (no @export) so it stays an implementation detail.
# -----------------------------------------------------------------------------
#' @noRd
mymodule_options_ui <- function(
  ns,
  group_vars = NULL,
  groups_lab = "Group data by",
  no_grouping_lab = "No grouping"
) {
  group_choices <- c(stats::setNames("n", no_grouping_lab), group_vars)
  htmltools::tagList(
    shinyWidgets::virtualSelectInput(
      inputId = ns("group"),
      label = groups_lab,
      choices = group_choices,
      selected = "n",
      width = "100%"
    )
  )
}
