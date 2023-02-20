library(tidyverse)

data <- readxl::read_excel("data/cartera_proyectos 2023-02-02 15_53_15.xlsx", skip = 2)

glimpse(data)

data <- janitor::clean_names(data)

glimpse(data)

data
