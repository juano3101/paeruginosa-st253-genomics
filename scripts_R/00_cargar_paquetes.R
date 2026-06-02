# =========================================================
# PAQUETES INICIALES DEL REPORTE
# =========================================================
paquetes <- c(
  # Manipulación
  "tidyverse",
  "scales",
  "jsonlite",
  "Biostrings",
  "readxl",
  "here",
  
  # Visualización
  "ggplot2",
  "patchwork",
  "ggtree",
  "ape",
  "phangorn",
  "ComplexHeatmap",
  "circlize",
  "grid",
  "ggtreeExtra",
  "ggnewscale",
  "cowplot",
  
  # Reportes
  "knitr",
  "kableExtra",
  "DT",
  "flextable",
  "officer"
)

# =========================================================
# INSTALAR FALTANTES
# =========================================================

faltantes <- paquetes[
  !paquetes %in% rownames(installed.packages())
]

if(length(faltantes) > 0){
  
  if(!requireNamespace("BiocManager", quietly = TRUE)){
    install.packages("BiocManager")
  }
  
  BiocManager::install(
    faltantes,
    ask = FALSE,
    update = FALSE
  )
}

# =========================================================
# CARGAR PAQUETES
# =========================================================

suppressMessages({
  lapply(paquetes, library, character.only = TRUE)
})
