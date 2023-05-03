page_navbar(
  theme = apptheme,
  sidebar = sidebar("Sidebar"),
  fillable = TRUE,
  title  = tags$span("Title"),
  header = tags$h2("Header"),
  footer = tags$footer("Footer"),
  nav("Page 1", "Page 1 content"),
  nav("Page 2", "Page 2 content")
)
