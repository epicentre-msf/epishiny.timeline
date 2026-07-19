# epishiny.template

> [!TIP]
> This is a **GitHub template repository**. To start a new module package,
> click **"Use this template" → "Create a new repository"** at the top of
> the GitHub page. That gives you a fresh repo (no fork relationship, clean
> history) named whatever you choose. Then follow the steps below.

A starter R package for authoring **standalone `epishiny` module packages**.

The core [`epishiny`](https://github.com/epicentre-msf/epishiny) package
provides interactive Shiny modules for time, place, and person analysis of
linelist data. To keep its dependency surface manageable, additional modules
(e.g. lab data, severity, mortality, …) are intended to live in their own
packages that depend on `epishiny`. This template gives you a working skeleton
for those packages: the conventions, asset plumbing, options handling, and
cross-module reactive contract are already wired up — you just rename and fill
in the visualisation.

## What you get

- A working placeholder module: `mymodule_ui()` / `mymodule_server()`
- A `.onLoad` hook registering an isolated Shiny resource path for your assets
- A `.onAttach` hook that sets the same default options `epishiny` does, so
  labels are consistent whether or not `epishiny` is loaded
- Mirrored copies of `epishiny`'s small internal helpers (`epi_pals()`,
  `force_reactive()`, `format_filter_info()`, `get_label()`, `time_stamp()`,
  pipe re-exports) so the package is self-contained and passes
  `R CMD check` cleanly without `epishiny:::`
- A `use_epishiny_template()` head-tag injector for your CSS/JS
- Stubs for `inst/assets/{css,js}/`, `inst/examples/docs/`, and `tests/testthat/`

## Dependency model

This template **deliberately does not depend on `epishiny`** in `Imports`.
That is the whole point of splitting modules out: a child module package
should only pull in what *it* needs, not the union of every visualisation
dependency in core epishiny (leaflet, sf, highcharter, gt, gtsummary,
chromote, webshot2, classInt, …).

To make that work without `epishiny` at runtime, the template:

- mirrors a handful of small helpers in `R/utils.R`
- redefines the same default `epishiny.*` options in `.onAttach`
- relies on `epishiny` only at the *interface* level — the reactive-value
  shapes (`place_filter`, `time_filter`, `filter_info`, `filter_reset`)
  produced by epishiny modules. Your module consumes those shapes; it
  doesn't import their definitions.

`epishiny` is in `Suggests:` so the example launcher and the integration test
can use its bundled `df_ll` data when available, but the package installs
and runs without it.

If your specific module *does* call into `epishiny` at runtime — e.g. wraps
`epishiny::geo_layer()` or reads bundled `sf_*` objects — promote it from
`Suggests` back to `Imports` for that package only.

## How to use

### 1. Create your repo from this template

1. On the [template repo's GitHub page](https://github.com/epicentre-msf/epishiny.template),
   click **"Use this template"** → **"Create a new repository"**.
2. Name the new repo following the convention `epishiny.<topic>`
   (e.g. `epishiny.lab`, `epishiny.severity`). Lowercase, dot-separated.
3. Clone it locally and `cd` into it.

> If you don't see the **"Use this template"** button, the template flag
> hasn't been set on the repo yet. The maintainer enables it under
> *Settings → General → ✅ Template repository*.

### 2. Rename the package

The new repo still contains the placeholder name `epishiny.template`
everywhere. Replace it in one pass:

```bash
NEW=epishiny.lab            # the name you picked above

# rename the .Rproj file
mv epishiny.template.Rproj "$NEW.Rproj"

# replace the package name everywhere (macOS sed shown; -i '' is intentional;
# on Linux drop the empty string after -i)
grep -rl 'epishiny\.template' . | xargs sed -i '' "s/epishiny\\.template/$NEW/g"
```

Then update `DESCRIPTION` by hand: `Title`, `Description`, `Authors@R`,
`URL`, `BugReports`. Commit the rename as your first commit on `main`.

### 3. Rename the placeholder module

Decide on a name — convention is a single short noun matching the topic
(e.g. `lab`, `severity`, `mortality`). Rename in `R/module.R`:

- `mymodule_ui` → `<name>_ui`
- `mymodule_server` → `<name>_server`
- `mymodule_options_ui` → `<name>_options_ui`
- `@rdname mymodule` → `@rdname <name>`

…and in `tests/testthat/test-mymodule.R` and
`inst/examples/docs/launch-module.R`.

### 4. Update the asset prefix

In `R/zzz.R` and `R/utils.R` (`use_epishiny_template()`), change
`"epishiny.template"` to your new package name so the resource path is
unique across modules. The `src=` / `href=` paths must match the prefix
registered in `addResourcePath()`.

(If you used the `sed` snippet in step 2, this is already done — but
double-check both files.)

### 5. Add your module

Replace the placeholder body of `<name>_server()` in `R/module.R`. The
existing scaffolding already:

- accepts `df` as a data frame *or* reactive returning one (via
  `force_reactive()`)
- applies upstream click-filters from sibling modules via `place_filter`
  and `time_filter`
- composes `filter_info` with `format_filter_info()` for chart subtitles
- returns a reactive of click-event data so callers can wire it back into
  the cross-module reactiveVals (mirrors what `time_server()` and
  `place_server()` do in `epishiny`)

Add any new heavy / optional dependencies to the `pkg_deps` vector in
`<name>_ui()` and check them with `rlang::check_installed()` rather than
adding them to `Imports:` — that keeps installation lean for users who
don't need every module.

### 6. Document and check

```r
devtools::document()
devtools::check()
```

The first run of `document()` will regenerate `NAMESPACE` from the roxygen
tags in `R/module.R` and `R/utils.R`.

### 7. Use it from a dashboard

Once installed, your module composes alongside epishiny's built-ins.
Users who want the combined dashboard install both packages:

```r
install.packages("remotes")
remotes::install_github("epicentre-msf/epishiny")
remotes::install_github("epicentre-msf/epishiny.lab")
```

```r
library(shiny)
library(bslib)
library(epishiny)
library(epishiny.lab)        # your new module package

data("df_ll")

ui <- bslib::page_sidebar(
  title = "Outbreak dashboard",
  sidebar = epishiny::filter_ui("filter", date_vars = "date_notification"),
  bslib::layout_columns(
    col_widths = c(8, 4),
    epishiny::time_ui("time", date_vars = "date_notification"),
    epishiny.lab::lab_ui("lab")          # <- your module
  )
)

server <- function(input, output, session) {
  app <- epishiny::filter_server("filter", df = df_ll,
                                 date_vars = "date_notification")
  epishiny::time_server("time", df = app$df, date_vars = "date_notification",
                        filter_info = app$filter_info)
  epishiny.lab::lab_server("lab", df = app$df,
                           filter_info = app$filter_info)
}

shinyApp(ui, server)
```

## Cross-module reactive contract

`epishiny` modules talk to each other through three `reactiveVal`s passed
into their server functions:

| reactiveVal    | Producer                         | Consumer                       |
| -------------- | -------------------------------- | ------------------------------ |
| `place_filter` | `place_server()` (map click)     | `time_server()`, `person_server()`, **your module** |
| `time_filter`  | `time_server()` (chart click)    | `place_server()`, `person_server()`, **your module** |
| `filter_info`  | `filter_server()` (sidebar)      | every module (for subtitles)   |
| `filter_reset` | `filter_server()` (reset button) | every module (clear local state) |

Your module should:

- accept all four as `shiny::reactiveVal()`-defaulted arguments
- *consume* them when filtering its own data
- *produce* the appropriate one (e.g. a clickable chart updates
  `time_filter`) by returning a reactive from its server, which the caller
  pipes back into the corresponding `reactiveVal()`

The placeholder module shows both halves of that contract.

## Shared options

`epishiny` sets four options in its `.onAttach`:

- `epishiny.na.label` — label for missing values, default `"(Missing)"`
- `epishiny.count.label` — generic count label, default `"Patients"`
- `epishiny.week.letter` — week label prefix, default `"W"`
- `epishiny.week.start` — week start day, default `1` (Monday)

Read them with `getOption("epishiny.na.label", "(Missing)")` from anywhere
in your module. They are inherited automatically; this template's
`.onAttach` only sets them if `epishiny` itself was not attached first.

## Mirrored utilities — keep in sync

`R/utils.R` mirrors a handful of small, stable helpers from
`epishiny/R/utils.R`. They are duplicated rather than reached for via
`epishiny:::` so this package passes `R CMD check` cleanly. If the upstream
versions change in `epishiny`, mirror the change here too. If you need a
helper that isn't mirrored, prefer to **export it from `epishiny` first**,
then call it via `epishiny::...` rather than copying or `:::`.
