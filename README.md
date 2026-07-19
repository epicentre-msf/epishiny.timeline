# epishiny.timeline

A standalone [`epishiny`](https://github.com/epicentre-msf/epishiny) module that
draws **patient care-pathway timelines**.

Each case is one row of a [Highcharts](https://www.highcharts.com/) `xrange`
chart, running from symptom onset to exit (recovery or death). The health
structures a patient passed through are drawn as labelled rectangles over the
disease phase, with an optional *assumed-incubation* window before onset. It
follows the `epishiny` module conventions (a `bslib` card with a gear-toggled
options panel and the cross-module reactive contract) so it slots into a
dashboard alongside the core `epishiny` time, place and person modules.

## What the chart shows

For every selected case, on a shared day-by-day date axis:

| Series               | Drawn as                                   |
| -------------------- | ------------------------------------------ |
| **Disease**          | a bar from symptom onset to exit           |
| **Assumed incubation** | a shaded window *before* onset (slider-controlled, in days) |
| **Facilities**       | outlined rectangles over the days spent in each health structure, labelled with its initials |
| **Symptom onset**    | a marker at the start of the disease bar   |
| **Exit**             | a marker at the end, coloured by outcome (recovered vs died) |

The date axis has two tiers: bare day numbers near the plot and a month band
above them. Hovering any element shows its dates.

## Options panel

Rendered in a right-hand sidebar (or a popover if `use_sidebar = FALSE`):

- **Health facility** — keep only cases that passed through a chosen structure
  (default: all structures).
- **Cases to display** — pick which patients to show.
- **Identifier** — switch the y-axis label between patient name and patient id.
- **Show age / sex** — append `(sex-age)` to each y-axis label.
- **Assumed incubation (days)** — length of the incubation window before onset
  (set to 0 to hide it).

## Installation

```r
# install.packages("remotes")
remotes::install_github("epicentre-msf/epishiny.timeline")
```

The chart itself is rendered with [`highcharter`](https://jkunst.com/highcharter/),
which is kept in `Suggests` and checked for at call time — install it too if it
isn't already:

```r
install.packages("highcharter")
```

## Quick start

`launch_timeline()` opens a standalone single-module app — handy for previewing
against your own linelist:

```r
library(epishiny.timeline)

launch_timeline(my_linelist)
```

## Expected data

The module works on a **patient-level linelist**: one row per case, with a set
of repeated *health-structure visit* columns (`..._visited1`, `..._visited2`,
…). Every column name is an argument of `timeline_server()`, so you map your
own data rather than renaming it. The defaults are:

| Argument           | Default column        | Meaning                                  |
| ------------------ | --------------------- | ---------------------------------------- |
| `id_var`           | `patient_name`        | case id / join key to the visit columns  |
| `name_var`         | `patient_name`        | name shown on the y-axis                 |
| `pid_var`          | `pid`                 | patient id (alternative y-axis label)    |
| `age_var`          | `age`                 | age for the `(sex-age)` label            |
| `sex_var`          | `sex`                 | sex for the `(sex-age)` label            |
| `date_onset`       | `date_symptom_onset`  | symptom-onset date                       |
| `date_exit`        | `date_exit_eff`       | exit date                                |
| `outcome_var`      | `type_of_exit`        | outcome (only `outcome_levels` are kept) |
| `hf_name_pattern`  | `HF_name_visited`     | stem of the structure-name columns       |
| `hf_start_pattern` | `date_start_HF_visited` | stem of the visit-start columns        |
| `hf_end_pattern`   | `date_end_HF_visited` | stem of the visit-end columns            |

The `hf_*_pattern` stems are matched with [`dplyr::contains()`], so
`HF_name_visited1`, `HF_name_visited2`, … are gathered automatically and
reshaped to one row per visit. A visit's end date falls back to the recorded
end, then the case exit (for the last structure), then a single day.

Only cases whose `outcome_var` is in `outcome_levels`
(default `c("Recovered", "Died")`) and that have both an onset and an exit date
are drawn. Map the arguments to your own values, e.g.:

```r
timeline_server(
  "timeline", df = my_linelist,
  id_var = "case_id", name_var = "full_name",
  outcome_var = "outcome", outcome_levels = c("Guéri", "Décédé"),
  recovered_value = "Guéri"
)
```

## Use inside a dashboard

The module consumes `epishiny`'s cross-module reactive contract, so it composes
with the built-in modules. Pass `filter_info` for synced subtitles, and
`place_filter` / `time_filter` to react to clicks in sibling map / epicurve
modules:

```r
library(shiny)
library(bslib)
library(epishiny)
library(epishiny.timeline)

ui <- bslib::page_sidebar(
  title = "Outbreak dashboard",
  sidebar = epishiny::filter_ui("filter", date_vars = "date_symptom_onset"),
  bslib::layout_columns(
    col_widths = c(6, 6),
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

### Cross-module reactive contract

`timeline_server()` accepts the four reactiveVals `epishiny` modules pass around
and *consumes* them:

| reactiveVal    | Effect on the timeline                                    |
| -------------- | --------------------------------------------------------- |
| `place_filter` | narrows the data to a clicked admin region                |
| `time_filter`  | narrows the data to a clicked time period                 |
| `filter_info`  | current filter-info string (kept in sync across modules)  |
| `filter_reset` | clears the module's own facility / cases selection        |

`timeline_server()` returns a [`shiny::reactive()`] of the case ids currently
shown, so callers can wire the selection into sibling modules.

## Dependency model

Following the `epishiny` module-package model, this package **does not depend on
`epishiny`** in `Imports`: a few small helpers are mirrored in `R/utils.R` so it
installs without pulling in `epishiny`'s full set of visualisation dependencies.
`epishiny` is in `Suggests` only, for the dashboard example above. The
`highcharter` renderer is likewise in `Suggests` and checked at call time.
