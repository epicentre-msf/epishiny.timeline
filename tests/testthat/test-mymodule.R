test_that("mymodule_ui returns shiny tags", {
  ui <- mymodule_ui(id = "test")
  # bslib::card returns a shiny.tag, but the wrapping varies across versions.
  expect_true(inherits(ui, c("shiny.tag", "shiny.tag.list", "bslib_fragment")))
})

test_that("mymodule_server runs and returns a reactive", {
  skip_if_not_installed("epishiny")
  data("df_ll", package = "epishiny")
  shiny::testServer(
    mymodule_server,
    args = list(id = "test", df = df_ll),
    {
      session$flushReact()
      expect_true(shiny::is.reactive(session$returned))
    }
  )
})
