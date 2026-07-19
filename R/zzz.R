#' @keywords internal
"_PACKAGE"

# -----------------------------------------------------------------------------
# Package load hooks
#
# Each module package needs a *unique* shiny resource path prefix so its
# CSS / JS assets do not collide with `epishiny`'s own `"epishiny/"` prefix
# (set in epishiny's own `.onLoad`). When you fork this template:
#
#   1. Rename the package in DESCRIPTION (e.g. `epishiny.lab`).
#   2. Replace `"epishiny.template"` below with that same name.
#   3. Update the `src=`/`href=` paths in `use_epishiny_template()`
#      (R/utils.R) to match.
# -----------------------------------------------------------------------------

.onLoad <- function(libname, pkgname) {
  shiny::addResourcePath(
    "epishiny.template",
    system.file("assets", package = "epishiny.template")
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
