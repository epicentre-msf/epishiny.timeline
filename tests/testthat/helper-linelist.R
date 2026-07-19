# A tiny synthetic linelist with the columns timeline_server() expects by
# default: one row per case, plus repeated health-structure visit fields.
fake_timeline_ll <- function() {
  onset <- as.Date(c("2024-01-03", "2024-01-05", "2024-01-10"))
  data.frame(
    patient_name = c("Ada Lovelace", "Alan Turing", "Grace Hopper"),
    pid = c("P001", "P002", "P003"),
    age = c(34L, 41L, 28L),
    sex = c("Female", "Male", "Female"),
    date_symptom_onset = onset,
    date_exit_eff = onset + c(12, 8, 15),
    type_of_exit = c("Recovered", "Died", "Recovered"),
    HF_name_visited1 = c("City Hospital", "Health Post", "City Hospital"),
    date_start_HF_visited1 = onset + 1,
    date_end_HF_visited1 = onset + c(5, 3, 6),
    HF_name_visited2 = c("General Hospital", NA, "General Hospital"),
    date_start_HF_visited2 = c(onset[1] + 5, NA, onset[3] + 6),
    date_end_HF_visited2 = c(onset[1] + 12, NA, onset[3] + 15),
    stringsAsFactors = FALSE
  )
}
