#' @keywords internal
"_PACKAGE"

# Non-standard-evaluation column names used inside the module's dplyr / tidyr
# pipelines. Declared here so `R CMD check` does not flag them as undefined
# global variables.
utils::globalVariables(c(
  ".id", "age", "sex", "sex_age", "name", "outcome", "label", "y",
  "date_onset", "date_exit", "onset_end", "exit_end", "incub_start",
  "incub_days", "visit", "hf_name", "hf_abbr", "hf_start", "hf_end",
  "hf_end_raw", "is_last_visit"
))

# -----------------------------------------------------------------------------
# Package load hooks
#
# `.onLoad` registers this package's assets under its own shiny resource-path
# prefix (`"epishiny.timeline"`) so its CSS / JS do not collide with
# `epishiny`'s own `"epishiny/"` prefix. The prefix must match the `src=` /
# `href=` paths in `use_epishiny_timeline()` (R/utils.R).
# -----------------------------------------------------------------------------

.onLoad <- function(libname, pkgname) {
  shiny::addResourcePath(
    "epishiny.timeline",
    system.file("assets", package = "epishiny.timeline")
  )
}

.onAttach <- function(libname, pkgname) {
  # Inherit the same defaults as epishiny so user-facing labels stay
  # consistent across modules. epishiny sets these in its own .onAttach;
  # we only set ones the user has not already overridden.
  defaults <- list(
    epishiny.na.label    = "(Missing)",
    epishiny.count.label = "Patients",
    epishiny.week.letter = "W",
    epishiny.week.start  = 1
  )
  for (nm in names(defaults)) {
    if (is.null(getOption(nm))) {
      do.call(options, stats::setNames(list(defaults[[nm]]), nm))
    }
  }
}
