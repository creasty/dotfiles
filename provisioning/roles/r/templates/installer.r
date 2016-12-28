options(repos=structure(c(CRAN="http://cran.stat.auckland.ac.nz/")))

cran.packages <- c(
{% for package in packages %}
  "{{ package }}",
{% endfor %}
)

for (p in cran.packages) {
  if (!suppressWarnings(require(p, character.only = TRUE, quietly = TRUE))) {
    cat(paste(p, "installing\n"))
    install.packages(p, dependencies = TRUE, type = "source")
  } else {
    cat(paste(p, "installed\n"))
  }
}
