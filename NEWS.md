# epishiny.timeline 0.0.0.9000

* Initial release of the `timeline` module: `timeline_ui()`, `timeline_server()`
  and the `launch_timeline()` standalone launcher.
* Draws one care-pathway timeline per case as a Highcharts `xrange` chart
  (symptom onset to exit, health-structure visits, optional incubation window).
* Consumes the `epishiny` cross-module reactive contract (`place_filter`,
  `time_filter`, `filter_info`, `filter_reset`).
