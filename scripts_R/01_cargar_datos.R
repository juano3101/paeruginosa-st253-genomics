library(tidyverse)
library(readxl)
library(jsonlite)
library(ape)
library(here)
library(rprojroot)
### IMPROTAR DATOS



metadata <- read_excel("work/metadata/metadata.xlsx")


### CALIDAD READS

ruta_qc_raw  <- "work/qc/raw/multiqc_general_stats.txt"
ruta_qc_filt <- "work/qc/filt/multiqc_general_stats.txt"

qc_raw <- read_tsv(ruta_qc_raw, show_col_types = FALSE)
qc_filt <- read_tsv(ruta_qc_filt, show_col_types = FALSE)


### ASSEMBLY QC

ruta_busco <- "work/qc_assembly/busco"
ruta_quast <- "work/qc_assembly/quast"

busco_raw_archivos <- list.files(file.path(ruta_busco, "raw"), pattern = "\\.json$", recursive = TRUE, full.names = TRUE)
busco_filt_archivos <- list.files(file.path(ruta_busco, "filt"), pattern = "\\.json$", recursive = TRUE, full.names = TRUE)
busco_raw_medaka_archivos <- list.files(file.path(ruta_busco, "raw_medaka"), pattern = "\\.json$", recursive = TRUE, full.names = TRUE)
busco_filt_medaka_archivos <- list.files(file.path(ruta_busco, "filt_medaka"), pattern = "\\.json$", recursive = TRUE, full.names = TRUE)

quast_raw <- read_tsv(
  file.path(ruta_quast, "quast_raw.tsv"),
  show_col_types = FALSE)

quast_filt <- read_tsv(
  file.path(ruta_quast, "quast_filt.tsv"),
  show_col_types = FALSE)

quast_raw_medaka <- read_tsv(
  file.path(ruta_quast, "quast_raw_medaka.tsv"),
  show_col_types = FALSE)

quast_filt_medaka <- read_tsv(
  file.path(ruta_quast, "quast_filt_medaka.tsv"),
  show_col_types = FALSE)

### KRAKEN2

dir_kraken <- "work/kraken"

archivos_kraken <- list.files(
  dir_kraken,
  pattern = "_output\\.txt$",
  recursive = TRUE, full.names = TRUE)


### MLST

mlst_raw <- read_tsv(
  "work/mlst/mlst_results.tsv",
  col_names = FALSE,
  show_col_types = FALSE)


### ARBOL

arbol_raw <- read.tree("work/phylogeny/core.snp.aln.treefile")


### DISTANCIAS SNPs

distancias <- read.delim("work/phylogeny/snippy_distancias.tsv", row.names = 1, check.names = FALSE)
tam_core_full <- Biostrings::width(Biostrings::readDNAStringSet("work/phylogeny/core.full.aln"))[1]

### AMRFINDER

dir_amr <- "work/annotation/amrfinder"

muestras_amr <- basename(
  list.dirs(dir_amr, recursive = FALSE))

