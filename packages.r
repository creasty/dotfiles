options(repos=structure(c(CRAN="http://cran.stat.auckland.ac.nz/")))

cran.packages <- c(
  "e1071",
  "ggplot2",
  "glmnet",
  "Hmisc",
  "igraph",
  "lme4",
  "lubridate",
  "plyr",
  "RCurl",
  "reshape",
  "RJSONIO",
  "scales",
  "tm",
  "XML"
)

for (p in cran.packages) {
  if (!suppressWarnings(require(p, character.only = TRUE, quietly = TRUE))) {
    cat(paste(p, "installing\n"))
    install.packages(p, dependencies = TRUE, type = "source")
  } else {
    cat(paste(p, "installed\n"))
  }
}
