## Unir y limpiar tabla

qc <- bind_rows(
  qc_raw %>% mutate(estado = "Crudo"),
  qc_filt %>% mutate(estado = "Filtrado")
) %>%
  transmute(
    muestra = Sample,
    estado = factor(estado, levels = c("Crudo", "Filtrado")),
    longitud_promedio = `nanostat-Mean_read_length_fastq`,
    read_n50 = `nanostat-Read_length_N50_fastq`,
    calidad_promedio = `nanostat-Mean_read_quality_fastq`,
    numero_reads = `nanostat-Number_of_reads_fastq`,
    bases_totales = `nanostat-Total_bases_fastq`,
    gc_pct = `fastqc-percent_gc`,
    duplicados_pct = `fastqc-percent_duplicates`
  ) %>%
  mutate(muestra = str_remove_all(muestra, "_raw$|_filt$|__SRR.*"))

qc_ancho <- qc %>%
  pivot_wider(
    names_from = estado,
    values_from = c(
      longitud_promedio, read_n50, calidad_promedio,
      numero_reads, bases_totales, gc_pct, duplicados_pct)) %>%
  mutate(
    retencion_reads_pct = numero_reads_Filtrado / numero_reads_Crudo * 100,
    retencion_bases_pct = bases_totales_Filtrado / bases_totales_Crudo * 100,
    cambio_phred = calidad_promedio_Filtrado - calidad_promedio_Crudo,
    cambio_n50 = read_n50_Filtrado - read_n50_Crudo,
    cambio_longitud_promedio = longitud_promedio_Filtrado - longitud_promedio_Crudo,
    cambio_duplicados = duplicados_pct_Filtrado - duplicados_pct_Crudo)

### CONTROL DE CALIDAD DE LECTURAS

qc <- bind_rows(
  qc_raw %>% mutate(estado = "Crudo"),
  qc_filt %>% mutate(estado = "Filtrado")
) %>%
  transmute(
    muestra = Sample,
    estado = factor(estado, levels = c("Crudo", "Filtrado")),
    longitud_promedio = `nanostat-Mean_read_length_fastq`,
    read_n50 = `nanostat-Read_length_N50_fastq`,
    calidad_promedio = `nanostat-Mean_read_quality_fastq`,
    numero_reads = `nanostat-Number_of_reads_fastq`,
    bases_totales = `nanostat-Total_bases_fastq`,
    gc_pct = `fastqc-percent_gc`,
    duplicados_pct = `fastqc-percent_duplicates`
  ) %>%
  mutate(muestra = str_remove_all(muestra, "_raw$|_filt$|__SRR.*"))

qc_ancho <- qc %>%
  pivot_wider(
    names_from = estado,
    values_from = c(
      longitud_promedio, read_n50, calidad_promedio,
      numero_reads, bases_totales, gc_pct, duplicados_pct)) %>%
  mutate(
    retencion_reads_pct = numero_reads_Filtrado / numero_reads_Crudo * 100,
    retencion_bases_pct = bases_totales_Filtrado / bases_totales_Crudo * 100,
    cambio_phred = calidad_promedio_Filtrado - calidad_promedio_Crudo,
    cambio_n50 = read_n50_Filtrado - read_n50_Crudo,
    cambio_longitud_promedio = longitud_promedio_Filtrado - longitud_promedio_Crudo,
    cambio_duplicados = duplicados_pct_Filtrado - duplicados_pct_Crudo)

tabla_qc_anexo <- qc_ancho %>%
  dplyr::rename(
    "Aislamiento" = muestra,
    "Longitud promedio cruda (bp)" = longitud_promedio_Crudo,
    "Longitud promedio filtrada (bp)" = longitud_promedio_Filtrado,
    "Read N50 crudo (bp)" = read_n50_Crudo,
    "Read N50 filtrado (bp)" = read_n50_Filtrado,
    "Calidad promedio cruda" = calidad_promedio_Crudo,
    "Calidad promedio filtrada" = calidad_promedio_Filtrado,
    "Reads crudas" = numero_reads_Crudo,
    "Reads filtradas" = numero_reads_Filtrado,
    "Bases crudas" = bases_totales_Crudo,
    "Bases filtradas" = bases_totales_Filtrado,
    "GC crudo (%)" = gc_pct_Crudo,
    "GC filtrado (%)" = gc_pct_Filtrado,
    "Duplicados crudo (%)" = duplicados_pct_Crudo,
    "Duplicados filtrado (%)" = duplicados_pct_Filtrado,
    "Retención reads (%)" = retencion_reads_pct,
    "Retención bases (%)" = retencion_bases_pct,
    "Cambio Phred" = cambio_phred,
    "Cambio N50 (bp)" = cambio_n50,
    "Cambio longitud promedio (bp)" = cambio_longitud_promedio,
    "Cambio duplicados (%)" = cambio_duplicados
  ) %>%
  mutate(across(where(is.numeric), ~ round(.x, 2)))

tabla_qc_anexo_ft <- flextable(tabla_qc_anexo) %>%
  theme_booktabs() %>%
  autofit() %>%
  fontsize(size = 7, part = "all") %>%
  bold(part = "header") %>%
  align(align = "center", part = "all") %>%
  align(j = "Aislamiento", align = "left", part = "all")

dir.create("res_final", showWarnings = FALSE)

write_csv(
  tabla_qc_anexo,
  "res_final/anexo_01_control_calidad_nanopore_completo.csv")

### GRÁFICO: CAMBIO DE CALIDAD PHRED

datos_phred <- qc_ancho %>%
  transmute(
    muestra,
    Crudo = calidad_promedio_Crudo,
    Filtrado = calidad_promedio_Filtrado,
    cambio = calidad_promedio_Filtrado - calidad_promedio_Crudo) %>%
  mutate(muestra = reorder(muestra, cambio))

grafico_phred <- ggplot(datos_phred) +
  geom_segment(
    aes(x = Crudo, xend = Filtrado, y = muestra, yend = muestra),
    linewidth = 1, color = "gray70") +
  geom_point(aes(x = Crudo, y = muestra), size = 3, color = "gray35") +
  geom_point(aes(x = Filtrado, y = muestra), size = 3, color = "black") +
  geom_text(
    aes(x = pmax(Crudo, Filtrado) + 0.08, y = muestra,
        label = ifelse( round(cambio, 2) == 0, "Δ < 0.1",
                        paste0("Δ = ", round(cambio, 2)))),
    size = 3, hjust = 0) +
  scale_x_continuous(breaks = seq(10, 13, 0.5), limits = c(10, 13.2)) +
  labs(
    x = "Calidad promedio Phred",
    y = "Aislamiento",
    title = "Cambio de calidad promedio Phred tras el filtrado") +
  theme_bw() +
  theme(
    plot.title = element_text(face = "bold"),
    axis.title = element_text(face = "bold"),
    panel.grid.minor = element_blank())


### TABLA RESUMIDA PARA RESULTADOS

tabla_qc_resultados <- qc_ancho %>%
  mutate(
    longitud_promedio_Crudo = longitud_promedio_Crudo / 1000,
    longitud_promedio_Filtrado = longitud_promedio_Filtrado / 1000,
    read_n50_Crudo = read_n50_Crudo / 1000,
    read_n50_Filtrado = read_n50_Filtrado / 1000) %>%
  select(
    muestra,
    retencion_reads_pct,
    retencion_bases_pct,
    gc_pct_Filtrado,
    longitud_promedio_Crudo,
    longitud_promedio_Filtrado,
    read_n50_Crudo,
    read_n50_Filtrado,
    duplicados_pct_Crudo,
    duplicados_pct_Filtrado) %>%
  dplyr::rename(
    "Aislamiento" = muestra,
    "Lecturas retenidas (%)" = retencion_reads_pct,
    "Bases retenidas (%)" = retencion_bases_pct,
    "GC filtrado (%)" = gc_pct_Filtrado,
    "Longitud promedio cruda (kb)" = longitud_promedio_Crudo,
    "Longitud promedio filtrada (kb)" = longitud_promedio_Filtrado,
    "N50 crudo (kb)" = read_n50_Crudo,
    "N50 filtrado (kb)" = read_n50_Filtrado,
    "Duplicados crudo (%)" = duplicados_pct_Crudo,
    "Duplicados filtrado (%)" = duplicados_pct_Filtrado) %>%
  mutate(
    `GC filtrado (%)` = round(`GC filtrado (%)`, 1),
    across(contains("(kb)"), round, 2),
    across(where(is.numeric), round, 2))

tabla_qc_resultados_ft <- flextable(tabla_qc_resultados) %>%
  theme_booktabs() %>%
  fontsize(size = 8, part = "all") %>%
  padding(padding = 2, part = "all") %>%
  line_spacing(space = 0.8, part = "all") %>%
  height(height = 0.22, part = "body") %>%
  bold(part = "header") %>%
  align(align = "center", part = "all") %>%
  align(j = "Aislamiento", align = "left", part = "all") %>%
  bg(i = seq(2, nrow(tabla_metadata), 2), bg = "#F2F2F2", part = "body") %>%
  bg(i = ~ Aislamiento == "Rectal_P11", bg = "#FDEDEC") %>%
  bold(i = ~ Aislamiento == "Rectal_P11",bold = TRUE) %>%
  autofit()

