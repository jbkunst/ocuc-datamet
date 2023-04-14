# install.packages("webdriver")
library(webdriver)

# webdriver::install_phantomjs()

# start -------------------------------------------------------------------
pjs <- run_phantomjs()

pjs


# session -----------------------------------------------------------------
ses <- Session$new(port = pjs$port)

ses$go("https://r-pkg.org/pkg/callr")

ses$getUrl()

ses$getTitle()

ses$takeScreenshot()

# ses$executeScript("document.getElementById('cran-input').value='highcharter'")

search <- ses$findElement("#cran-input")

search$sendKeys("html", key$enter)

ses$getUrl()

ses$takeScreenshot()
