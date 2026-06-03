library(tidyverse)
library(Biostrings)
library(DECIPHER)
library(flextable)

ruta_bakta <- "work/annotation/bakta"

leer_bakta <- function(muestra){
  file.path(ruta_bakta, muestra, paste0(muestra, ".tsv")) %>%
    read_tsv(skip = 5, col_names = c("seqid","type","start","stop","strand","locus_tag","gene","product","dbxrefs"), show_col_types = FALSE) %>%
    mutate(muestra = muestra, .before = 1)
}

extraer_gen <- function(muestra, seqid, start, stop, strand){
  genoma <- readDNAStringSet(file.path(ruta_bakta, muestra, paste0(muestra, ".fna")))
  names(genoma) <- str_extract(names(genoma), "^[^ ]+")
  sec <- subseq(genoma[[as.character(seqid)]], start = as.integer(start), end = as.integer(stop))
  if(as.character(strand) == "-") sec <- reverseComplement(sec)
  sec
}

coord_trpE <- bind_rows(leer_bakta("Rectal_P9"), leer_bakta("Sputum_P3")) %>%
  filter(gene == "trpE") %>%
  select(muestra, seqid, start, stop, strand, gene, product)

seq_trpE <- coord_trpE %>%
  mutate(secuencia = pmap(list(muestra, seqid, start, stop, strand), extraer_gen))

seqs_trpE <- DNAStringSet(map_chr(seq_trpE$secuencia, as.character))
names(seqs_trpE) <- paste0(seq_trpE$muestra, "_trpE")

aln_trpE <- AlignSeqs(seqs_trpE, verbose = FALSE)

s1 <- strsplit(as.character(aln_trpE[[1]]), "")[[1]]
s2 <- strsplit(as.character(aln_trpE[[2]]), "")[[1]]

diferencias_trpE <- tibble(posicion_nt = seq_along(s1), Rectal_P9 = s1, Sputum_P3 = s2) %>%
  filter(Rectal_P9 != Sputum_P3)

trpE_rectal <- seq_trpE$secuencia[[which(seq_trpE$muestra == "Rectal_P9")]]
trpE_sputum <- seq_trpE$secuencia[[which(seq_trpE$muestra == "Sputum_P3")]]

aa1 <- strsplit(as.character(translate(trpE_rectal)), "")[[1]]
aa2 <- strsplit(as.character(translate(trpE_sputum)), "")[[1]]

diferencias_aa_trpE <- tibble(posicion_aa = seq_along(aa1), Rectal_P9 = aa1, Sputum_P3 = aa2) %>%
  filter(Rectal_P9 != Sputum_P3) %>%
  mutate(cambio_aa = paste0(Rectal_P9, posicion_aa, Sputum_P3))

library(tidyverse)
library(Biostrings)
library(DECIPHER)
library(flextable)

ruta_bakta <- "work/annotation/bakta"

leer_bakta <- function(muestra){
  file.path(ruta_bakta, muestra, paste0(muestra, ".tsv")) %>%
    read_tsv(skip = 5, col_names = c("seqid","type","start","stop","strand","locus_tag","gene","product","dbxrefs"), show_col_types = FALSE) %>%
    mutate(muestra = muestra, .before = 1)
}

extraer_gen <- function(muestra, seqid, start, stop, strand){
  genoma <- readDNAStringSet(file.path(ruta_bakta, muestra, paste0(muestra, ".fna")))
  names(genoma) <- str_extract(names(genoma), "^[^ ]+")
  sec <- subseq(genoma[[as.character(seqid)]], start = as.integer(start), end = as.integer(stop))
  if(as.character(strand) == "-") sec <- reverseComplement(sec)
  sec
}

coord_trpE <- bind_rows(leer_bakta("Rectal_P9"), leer_bakta("Sputum_P3")) %>%
  filter(gene == "trpE") %>%
  select(muestra, seqid, start, stop, strand, gene, product)

seq_trpE <- coord_trpE %>%
  mutate(secuencia = pmap(list(muestra, seqid, start, stop, strand), extraer_gen))

seqs_trpE <- DNAStringSet(map_chr(seq_trpE$secuencia, as.character))
names(seqs_trpE) <- paste0(seq_trpE$muestra, "_trpE")

aln_trpE <- AlignSeqs(seqs_trpE, verbose = FALSE)

s1 <- strsplit(as.character(aln_trpE[[1]]), "")[[1]]
s2 <- strsplit(as.character(aln_trpE[[2]]), "")[[1]]

diferencias_trpE <- tibble(posicion_nt = seq_along(s1), Rectal_P9 = s1, Sputum_P3 = s2) %>%
  filter(Rectal_P9 != Sputum_P3)

trpE_rectal <- seq_trpE$secuencia[[which(seq_trpE$muestra == "Rectal_P9")]]
trpE_sputum <- seq_trpE$secuencia[[which(seq_trpE$muestra == "Sputum_P3")]]

aa1 <- strsplit(as.character(translate(trpE_rectal)), "")[[1]]
aa2 <- strsplit(as.character(translate(trpE_sputum)), "")[[1]]

diferencias_aa_trpE <- tibble(posicion_aa = seq_along(aa1), Rectal_P9 = aa1, Sputum_P3 = aa2) %>%
  filter(Rectal_P9 != Sputum_P3) %>%
  mutate(cambio_aa = paste0(Rectal_P9, posicion_aa, Sputum_P3))

tabla_trpE_final <- diferencias_trpE %>%
  mutate(
    `Cambio nucleotídico` = paste0(Rectal_P9, "→", Sputum_P3),
    `Cambio aminoacídico` = c("Q295R", "Q392R", "Sin cambio")) %>%
  transmute(
    `Posición nucleotídica` = posicion_nt,
    `Alelo 433` = Rectal_P9,
    `Alelo 3` = Sputum_P3,
    `Cambio nucleotídico`,
    `Cambio aminoacídico`)

tabla_trpE_final <- diferencias_trpE %>%
  mutate(
    `Cambio nucleotídico` = paste0(Rectal_P9, "→", Sputum_P3),
    `Cambio aminoacídico` = c("Q295R", "Q392R", "Sin cambio")) %>%
  transmute(
    `Posición nucleotídica` = posicion_nt,
    `Alelo 433` = Rectal_P9,
    `Alelo 3` = Sputum_P3,
    `Cambio nucleotídico`,
    `Cambio aminoacídico`)

ft_trpE <- tabla_trpE_final %>%
  flextable() %>%
  theme_booktabs() %>%
  bold(part = "header") %>%
  align(align = "center", part = "all") %>%
  bg(i = seq(2, nrow(tabla_trpE_final), 2), bg = "#F2F2F2", part = "body") %>%
  autofit()
