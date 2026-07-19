test_that("timeline_ui returns shiny tags", {
  skip_if_not_installed("highcharter")
  ui <- timeline_ui(id = "test")
  expect_true(
    inherits(ui, c("shiny.tag", "shiny.tag.list", "bslib_fragment"))
  )
})

test_that("timeline_server runs and returns a reactive of shown ids", {
  skip_if_not_installed("highcharter")
  ll <- fake_timeline_ll()
  shiny::testServer(
    timeline_server,
    args = list(id = "test", df = ll),
    {
      session$setInputs(
        facility = "",
        cases = c("Ada Lovelace", "Alan Turing", "Grace Hopper"),
        show_agesex = TRUE,
        incubation = 8
      )
      session$flushReact()

      # returns a reactive
      expect_true(shiny::is.reactive(session$returned))

      # only cases with a kept outcome and both dates are modelled
      expect_setequal(cases_dat()$.id, ll$patient_name)

      # long-format visits: 3 first visits + 2 second visits = 5 rows
      expect_equal(nrow(visits_dat()), 5L)
      expect_true(all(visits_dat()$hf_end >= visits_dat()$hf_start))

      # the returned reactive is the plotted-id selection
      expect_setequal(session$returned(), ll$patient_name)
    }
  )
})

test_that("facility filter narrows the plotted cases", {
  skip_if_not_installed("highcharter")
  ll <- fake_timeline_ll()
  shiny::testServer(
    timeline_server,
    args = list(id = "test", df = ll),
    {
      session$setInputs(
        facility = "General Hospital",
        cases = ll$patient_name,
        show_agesex = TRUE,
        incubation = 8
      )
      session$flushReact()
      # only Ada and Grace passed through General Hospital
      expect_setequal(facility_ids(), c("Ada Lovelace", "Grace Hopper"))
    }
  )
})

test_that("time_filter narrows the underlying data", {
  skip_if_not_installed("highcharter")
  ll <- fake_timeline_ll()
  tf <- shiny::reactiveVal(list(
    date_col = "date_symptom_onset",
    range = as.Date(c("2024-01-01", "2024-01-06"))
  ))
  shiny::testServer(
    timeline_server,
    args = list(id = "test", df = ll, time_filter = tf),
    {
      session$setInputs(show_agesex = TRUE, incubation = 8, facility = "")
      session$flushReact()
      # Grace Hopper (onset 2024-01-10) is filtered out
      expect_setequal(cases_dat()$.id, c("Ada Lovelace", "Alan Turing"))
    }
  )
})
