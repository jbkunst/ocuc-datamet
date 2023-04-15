# setup -------------------------------------------------------------------
library(tidyverse)
library(sf)

# data --------------------------------------------------------------------
data <- readxl::read_excel("data/cartera_proyectos_02_23.xlsx")

glimpse(data)

data <- janitor::clean_names(data)

glimpse(data)

data <- data |>
  select(codigo, ano, provincia, comuna, sector, sub_sector)

tbl_geoserver <- readr::read_csv("data/tbl_geoserver.csv")

data_geo <- tbl_geoserver |>
  filter(resultado == "descargado") |>
  pull(nombre) |>
  str_remove_all("sit\\:") |>
  map(function(file = "idis_ptomigra"){

    cli::cli_progress_step(file)

    l <- sf::st_read(fs::path("data", "geojson", file, ext = "geojson"), quiet = TRUE)

    l <- l |>
      mutate(cod_bip = as.character(cod_bip))

    dout <- inner_join(l, data, by = join_by(cod_bip == codigo)) |>
      mutate(archivo = file, .before = 1) |>
      mutate(id = as.character(id))

    # mapview::mapview(dout)

    dout

  }) |>
  bind_rows()

data_geo |>
  as_tibble() |>
  count(archivo)

mapview::mapview(data_geo)

