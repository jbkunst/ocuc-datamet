# setup -------------------------------------------------------------------
# install.packages("webdriver")
library(tidyverse)
library(webdriver)
library(sf)

# webdriver::install_phantomjs()

# start and session -------------------------------------------------------
pjs <- run_phantomjs()
pjs

# session
url_geo_server <- "https://sitmds.ministeriodesarrollosocial.gob.cl/geoserver/web/?wicket:bookmarkablePage=:org.geoserver.web.demo.MapPreviewPage"
url_geo_json_template <- "https://sitmds.ministeriodesarrollosocial.gob.cl/geoserver/sit/ows?service=WFS&version=1.0.0&request=GetFeature&typeName={nombre}&maxFeatures=80000&outputFormat=application%2Fjson"

ses <- Session$new(port = pjs$port)
ses$go(url_geo_server)

# ses$getUrl()
# ses$getTitle()
# ses$takeScreenshot()


# descargar tabla ---------------------------------------------------------
# son 10 páginas
# revisa cada fila por página y guarda geojson si existe  codigo_bip o cod_bip
tbl_geoserver <- map(1:10, function(i = 1){

  cli::cli_progress_step("Página {i}")

  tbl_id <- ses$findElement("table")$getAttribute("id")

  tbl_html <- ses$executeScript(str_glue("return document.getElementById('{ tbl_id }').innerHTML ;"))
  tbl_html <- str_c("<table>", tbl_html, "<table>", collapse = "")

  tbl <- tbl_html |>
    rvest::read_html() |>
    rvest::html_table() |>
    first() |>
    janitor::clean_names() |>
    mutate(pagina = i, .before = 1)

  # glimpse(tbl)

  # avanzar de página
  ses$findElement(".next")$click()
  Sys.sleep(4)

  tbl

})

tbl_geoserver <- list_rbind(tbl_geoserver)

tbl_geoserver

tbl_geoserver |> distinct(pagina, nombre) |> count()
tbl_geoserver |> distinct(nombre)         |> count()


# descarga archivos -------------------------------------------------------
archivos <- tbl_geoserver |>
  pull(nombre)

# revisa que archivos tienen columnas bip y las descarga
resultados <- map(archivos, safely(function(nombre = "sit:violencia_intrafamiliar_698_4326"){

    cli::cli_progress_step(nombre)

    nn <- str_replace_all(nombre, " ", "%20")

    url_geo_json <- str_glue(url_geo_json_template, nombre = nn)

    layer <- st_read(dsn = url_geo_json, quiet = TRUE)

    # si tiene codigo_bip o cod_bip
    if(any(str_detect(names(layer), "codigo_bip|cod_bip"))){

      nn <- str_remove_all(nombre, "^sit|\\:+")

      layer |>
        select(-contains("bbox")) |>
        st_write(
          fs::path("data", "geojson", nn, ext = "geojson"),
          driver = "GeoJSON",
          quiet = TRUE,
          delete_dsn = TRUE
          )

      cli::cli_alert_success("writing geojson {nn}")

      return("descargado")

    } else {

      return("no posee bip")

    }


  }))


tbl_geoserver <- tbl_geoserver |>
  select(pagina, nombre, titulo) |>
  mutate(
    resultado = map_chr(resultados,  \(x) ifelse(is.null(x[["result"]]), NA, x[["result"]])),
    resultado = coalesce(resultado, "error")
  )

readr::write_csv(tbl_geoserver, "data/tbl_geoserver.csv")

tbl_geoserver |>
  filter(resultado == "error")

