# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this package is

`epishiny.template` is a **starter package**. It is not meant to be installed
as-is in production. Forks of this package become standalone module packages
that depend on the core [`epishiny`](https://github.com/epicentre-msf/epishiny)
package.

When the user asks you to "create a new epishiny module package", the workflow
is:

1. Copy this directory under a new name (`epishiny.<topic>`).
2. Rename the package, the placeholder module, and the asset prefix
   (see `README.md` §1–§3 for exact strings to replace).
3. Implement the visualisation in `R/module.R`.
4. Document and check (`devtools::document()`, `devtools::check()`).

Keep the existing scaffolding — the resource-path registration, the options
fallback, the cross-module reactive contract, the local mirrors of epishiny
utilities — unless the user explicitly asks to change it.

## Dependency model — important

`epishiny` is in **`Suggests`**, not `Imports`, on purpose. The template
must remain installable and functional without `epishiny`, so that child
modules don't transitively pull in the full set of core-epishiny viz
dependencies (leaflet, sf, highcharter, gt, gtsummary, chromote,
webshot2, classInt, …). Concretely:

- Don't add `epishiny::` calls to `R/*.R`. If you need a helper, mirror
  it in `R/utils.R` instead.
- Tests and examples that touch `epishiny` (e.g. `df_ll`) must guard with
  `skip_if_not_installed("epishiny")` or
  `requireNamespace("epishiny", quietly = TRUE)`.
- A child module that genuinely calls `epishiny::geo_layer()` etc. at
  runtime *can* promote `epishiny` to `Imports` for that specific
  package — but the template stays Suggests.

## Repo layout

- `R/zzz.R` — `.onLoad` registers `inst/assets/` under a unique Shiny
  resource-path prefix; `.onAttach` sets the four `epishiny.*` options if
  not already set by epishiny itself
- `R/utils.R` — local mirrors of epishiny's small internal helpers
  (`use_epishiny_template()`, `force_reactive()`, `epi_pals()`, `get_label()`,
  `format_filter_info()`, `time_stamp()`, pipe re-exports)
- `R/module.R` — placeholder `mymodule_ui()` / `mymodule_server()` showing
  the canonical UI/server pattern, options popover/sidebar, and cross-module
  reactive plumbing
- `inst/assets/{css,js}/` — module-specific CSS/JS, loaded via
  `use_epishiny_template()`
- `inst/examples/docs/launch-module.R` — minimal standalone launcher used
  in roxygen `@example`
- `tests/testthat/` — testthat 3 tests; mirror epishiny's testing style

## Conventions to preserve when extending

- Module UI returns a `bslib::card` (or layout) and calls
  `use_epishiny_template()` once.
- UI accepts overridable label arguments (i18n).
- Server takes `df` as data frame *or* reactive; wrap with `force_reactive()`.
- Server accepts `place_filter`, `time_filter`, `filter_info`, `filter_reset`
  defaulted to `shiny::reactiveVal()` — even if the module doesn't use them
  yet — so it composes inside `epishiny::epi_dashboard()`.
- Heavy / optional deps are checked at call time with
  `rlang::check_installed()`, not declared in `Imports:`.
- Errors use `cli::cli_abort()`, not `stop()`.
- Internal helpers stay `@noRd`; only the module's `*_ui()` / `*_server()`
  pair is `@export`ed.

## When mirroring helpers from epishiny

`R/utils.R` is a deliberate mirror of `~/epicentre/epishiny/R/utils.R`. If
the upstream definitions change, update this file to match. Prefer
upstreaming a new helper to `epishiny` and calling `epishiny::helper()`
over either adding a new local mirror or using `epishiny:::helper()`.

## Development commands

Standard R-package workflow:

```r
devtools::load_all()
devtools::document()
devtools::test()
devtools::check()
```

## Reference

The parent package and its conventions live at
`~/epicentre/epishiny` and https://epicentre-msf.github.io/epishiny/.
