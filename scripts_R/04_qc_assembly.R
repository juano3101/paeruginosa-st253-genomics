### CALIDAD DE ENSAMBLAJE

estrategias <- c("raw", "filt", "raw_medaka", "filt_medaka")

limpiar_muestra <- function(x) {
  x %>% basename() %>%
    str_remove("^short_summary\\.specific\\.pseudomonas_odb12\\.") %>%
    str_remove("\\.json$") %>%
    str_remove("_flye_raw$|_flye_filtered$|_medaka_raw$|_medaka_filtered$") %>%
    str_remove("_*SRR.*")
}

archivos_busco <- list(
  raw = busco_raw_archivos,
  filt = busco_filt_archivos,
  raw_medaka = busco_raw_medaka_archivos,
  filt_medaka = busco_filt_medaka_archivos)

cargar_busco <- function(archivos, estrategia) {
  map_dfr(archivos, \(x) {
    j <- fromJSON(x)
    tibble(
      muestra = limpiar_muestra(x),
      estrategia = estrategia,
      busco_completos_pct = j$results$`Complete percentage`,
      busco_single_pct = j$results$`Single copy percentage`,
      busco_duplicados_pct = j$results$`Multi copy percentage`,
      busco_fragmentados_pct = j$results$`Fragmented percentage`,
      busco_faltantes_pct = j$results$`Missing percentage`,
      busco_completos_n = j$results$`Complete BUSCOs`,
      busco_single_n = j$results$`Single copy BUSCOs`,
      busco_duplicados_n = j$results$`Multi copy BUSCOs`,
      busco_fragmentados_n = j$results$`Fragmented BUSCOs`,
      busco_faltantes_n = j$results$`Missing BUSCOs`,
      busco_total = j$results$n_markers,
      busco_scaffolds = as.numeric(j$results$`Number of scaffolds`),
      busco_contigs = as.numeric(j$results$`Number of contigs`),
      busco_longitud_total = as.numeric(j$results$`Total length`),
      busco_gaps_pct = as.numeric(str_remove(j$results$`Percent gaps`, "%")),
      busco_scaffold_n50 = as.numeric(j$results$`Scaffold N50`),
      busco_contig_n50 = as.numeric(j$results$`Contigs N50`))
  })
}

cargar_quast <- function(tabla, estrategia_nombre) {
  tabla %>%
    dplyr::rename(metrica = Assembly) %>%
    pivot_longer(-metrica, names_to = "ensamblaje", values_to = "valor") %>%
    mutate(
      muestra = limpiar_muestra(ensamblaje),
      estrategia = estrategia_nombre,
      valor = readr::parse_number(as.character(valor))) %>%
    filter(!is.na(valor)) %>%
    select(muestra, estrategia, metrica, valor)
}

tabla_busco <- imap_dfr(archivos_busco, cargar_busco) %>%
  filter(muestra != "short_summary")

tabla_quast <- bind_rows(
  cargar_quast(quast_raw, "raw"),
  cargar_quast(quast_filt, "filt"),
  cargar_quast(quast_raw_medaka, "raw_medaka"),
  cargar_quast(quast_filt_medaka, "filt_medaka")) %>%
  distinct(muestra, estrategia, metrica, .keep_all = TRUE) %>%
  pivot_wider(names_from = metrica, values_from = valor) %>%
  dplyr::rename(
    quast_contigs_0bp = `# contigs (>= 0 bp)`,
    quast_contigs_1000bp = `# contigs (>= 1000 bp)`,
    quast_contigs_5000bp = `# contigs (>= 5000 bp)`,
    quast_contigs_10000bp = `# contigs (>= 10000 bp)`,
    quast_contigs_25000bp = `# contigs (>= 25000 bp)`,
    quast_contigs_50000bp = `# contigs (>= 50000 bp)`,
    quast_total_0bp = `Total length (>= 0 bp)`,
    quast_total_1000bp = `Total length (>= 1000 bp)`,
    quast_total_5000bp = `Total length (>= 5000 bp)`,
    quast_total_10000bp = `Total length (>= 10000 bp)`,
    quast_total_25000bp = `Total length (>= 25000 bp)`,
    quast_total_50000bp = `Total length (>= 50000 bp)`,
    quast_contigs = `# contigs`,
    quast_contig_mayor = `Largest contig`,
    quast_longitud_total = `Total length`,
    quast_gc_pct = `GC (%)`,
    quast_genome_fraction_pct = `Genome fraction (%)`,
    quast_n50 = N50,
    quast_n90 = N90,
    quast_aun = auN,
    quast_l50 = L50,
    quast_l90 = L90,
    quast_n_por_100kbp = `# N's per 100 kbp`)

tabla_calidad_ensamblaje <- full_join(
  tabla_quast,
  tabla_busco,
  by = c("muestra", "estrategia")) %>%
  mutate(
    estrategia = factor(estrategia, levels = estrategias),
    across(where(is.numeric), ~ round(.x, 2))) %>%
  arrange(muestra, estrategia)

dir.create("res_final", showWarnings = FALSE)

write_csv(
  tabla_calidad_ensamblaje,
  "res_final/anexo_02_control_calidad_ensamblaje.csv")

### RESUMEN POR ESTRATEGIA

res_media <- function(x, div = 1, dec = 2) {
  round(mean(x / div, na.rm = TRUE), dec)
}

res_rango <- function(x, div = 1, dec = 2) {
  x <- x / div
  paste0(
    round(mean(x, na.rm = TRUE), dec), "\n[",
    round(min(x, na.rm = TRUE), dec), "-",
    round(max(x, na.rm = TRUE), dec), "]")
}

tabla_resumen_estrategia <- tabla_calidad_ensamblaje %>%
  mutate(
    estrategia = recode(
      estrategia,
      raw = "Crudo",
      raw_medaka = "Crudo + Medaka",
      filt = "Filtrado",
      filt_medaka = "Filtrado + Medaka")) %>%
  group_by(estrategia) %>%
  summarise(
    Contigs = res_rango(quast_contigs, dec = 0),
    `Longitud total\n(Mb)` = res_rango(quast_longitud_total, 1e6),
    `Contig mayor\n(Mb)` = res_rango(quast_contig_mayor, 1e6),
    `N50\n(Mb)` = res_rango(quast_n50, 1e6),
    `GC\n(%)` = res_rango(quast_gc_pct),
    `Genoma de referencia\ncubierto (%)` = res_rango(quast_genome_fraction_pct),
    `Genes completos\n(%)` = res_rango(busco_completos_pct),
    `Genes fragmentados\n(%)` = res_rango(busco_fragmentados_pct),
    `Genes faltantes\n(%)` = res_rango(busco_faltantes_pct),
    `Genes single-copy\n(%)` = res_rango(busco_single_pct),
    `Genes duplicados\n(%)` = res_rango(busco_duplicados_pct),
    .groups = "drop") %>%
  dplyr::rename(Estrategia = estrategia)

tabla_resumen_estrategia_ft <- flextable(tabla_resumen_estrategia) %>%
  theme_booktabs() %>%
  fontsize(size = 6.2, part = "all") %>%
  padding(padding = 1, part = "all") %>%
  line_spacing(space = 0.85, part = "all") %>%
  height(height = 0.32, part = "body") %>%
  height(height = 0.38, part = "header") %>%
  width(width = 0.58) %>%
  bold(part = "header") %>%
  align(align = "center", part = "all") %>%
  align(j = "Estrategia", align = "left", part = "all") %>%
  bg(i = seq(2, nrow(tabla_resumen_estrategia), 2), bg = "#F2F2F2")

### RESUMEN POR MUESTRA FINAL

tabla_ensamblaje_final <- tabla_calidad_ensamblaje %>%
  filter(estrategia == "filt_medaka") %>%
  select(
    muestra,
    quast_contigs,
    quast_longitud_total,
    quast_contig_mayor,
    quast_n50,
    quast_gc_pct,
    quast_genome_fraction_pct,
    busco_completos_pct,
    busco_fragmentados_pct,
    busco_faltantes_pct,
    busco_single_pct,
    busco_duplicados_pct) %>%
  mutate(
    across(c(quast_longitud_total, quast_contig_mayor, quast_n50), ~ round(.x / 1e6, 2)),
    quast_contigs = as.integer(quast_contigs),
    across(where(is.numeric), ~ round(.x, 2))) %>%
  arrange(quast_contigs) %>%
  dplyr::rename(
    Aislamiento = muestra,
    Contigs = quast_contigs,
    `Longitud total\n(Mb)` = quast_longitud_total,
    `Contig mayor\n(Mb)` = quast_contig_mayor,
    `N50\n(Mb)` = quast_n50,
    `GC\n(%)` = quast_gc_pct,
    `Genoma de referencia\ncubierto (%)` = quast_genome_fraction_pct,
    `Genes completos\n(%)` = busco_completos_pct,
    `Genes fragmentados\n(%)` = busco_fragmentados_pct,
    `Genes faltantes\n(%)` = busco_faltantes_pct,
    `Genes single-copy\n(%)` = busco_single_pct,
    `Genes duplicados\n(%)` = busco_duplicados_pct)

tabla_ensamblaje_final_ft <- flextable(tabla_ensamblaje_final) %>%
  theme_booktabs() %>%
  fontsize(size = 6.6, part = "all") %>%
  padding(padding = 1, part = "all") %>%
  line_spacing(space = 0.85, part = "all") %>%
  height(height = 0.28, part = "body") %>%
  height(height = 0.36, part = "header") %>%
  bold(part = "header") %>%
  align(align = "center", part = "all") %>%
  align(j = "Aislamiento", align = "left", part = "all") %>%
  bg(i = seq(2, nrow(tabla_ensamblaje_final), 2), bg = "#F2F2F2") %>%
  bg(i = ~ Aislamiento == "Rectal_P11", bg = "#FDEDEC") %>%
  bold(i = ~ Aislamiento == "Rectal_P11", bold = TRUE) %>%
  width(width = 0.58) %>%
  autofit()

