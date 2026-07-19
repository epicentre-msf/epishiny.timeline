# epishiny.timeline

A standalone [`epishiny`](https://github.com/epicentre-msf/epishiny) module that
draws **patient care-pathway timelines**.

Each case is one row of a Highcharts `xrange` chart, from symptom onset to exit
(recovery or death), with the health structures visited drawn as labelled
rectangles over the disease phase and an optional assumed-incubation window
before onset.

## Installation

```r
# install.packages("remotes")
remotes::install_github("epicentre-msf/epishiny.timeline")
install.packages("highcharter")  # renderer, kept in Suggests
```

## Quick start

```r
library(epishiny.timeline)
launch_timeline(my_linelist)
```

## Expected data

A patient-level linelist: one row per case, plus repeated health-structure
visit columns (`HF_name_visited1`, `HF_name_visited2`, …). Every column name is
an argument of `timeline_server()`, so you map your own data rather than
renaming it — see `?timeline_server` for the full list. Only cases whose
outcome is in `outcome_levels` (default `c("Recovered", "Died")`) with both an
onset and exit date are drawn.

## Use inside a dashboard

The module consumes `epishiny`'s cross-module reactive contract, so it composes
with the built-in modules:

```r
library(shiny)
library(bslib)
library(epishiny)
library(epishiny.timeline)

ui <- bslib::page_sidebar(
  sidebar = epishiny::filter_ui("filter", date_vars = "date_symptom_onset"),
  bslib::layout_columns(
    epishiny::time_ui("time", date_vars = "date_symptom_onset"),
    epishiny.timeline::timeline_ui("timeline")
  )
)

server <- function(input, output, session) {
  app <- epishiny::filter_server("filter", df = my_linelist,
                                 date_vars = "date_symptom_onset")
  epishiny::time_server("time", df = app$df, date_vars = "date_symptom_onset",
                        filter_info = app$filter_info)
  epishiny.timeline::timeline_server(
    "timeline", df = app$df,
    filter_info = app$filter_info,
    time_filter = app$time_filter,
    place_filter = app$place_filter,
    filter_reset = app$filter_reset
  )
}

shinyApp(ui, server)
```

`timeline_server()` *consumes* the four reactiveVals `epishiny` modules pass
around, and returns a `reactive()` of the case ids currently shown:

| reactiveVal    | Effect on the timeline                                   |
| -------------- | -------------------------------------------------------- |
| `place_filter` | narrows the data to a clicked admin region               |
| `time_filter`  | narrows the data to a clicked time period                |
| `filter_info`  | current filter-info string, kept in sync across modules  |
| `filter_reset` | clears the module's own facility / cases selection       |

## Dependency model

Following the `epishiny` module-package model, this package does **not** depend
on `epishiny` in `Imports`: small helpers are mirrored in `R/utils.R` so it
installs without pulling in `epishiny`'s full set of visualisation
dependencies. `epishiny` and `highcharter` are in `Suggests` only.
