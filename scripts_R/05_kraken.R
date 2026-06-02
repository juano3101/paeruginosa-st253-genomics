### KRAKEN2

leer_output <- function(archivo, grupo) {
  read_tsv(
    archivo,
    col_names = c("estado", "contig", "taxid", "longitud", "lca"),
    col_types = cols(.default = "c"),
    trim_ws = TRUE) %>%
    mutate(
      grupo = grupo,
      muestra = basename(archivo) %>%
        str_remove("_output\\.txt$") %>%
        str_remove("__SRR.*") %>%
        str_remove("_filt") %>%
        str_remove("_$"),
      longitud = as.numeric(longitud))
}

tabla_contigs <- tibble(
  archivo = archivos_kraken,
  grupo = if_else(str_detect(archivo, "muestras"), "muestra", "control")) %>%
  mutate(datos = map2(archivo, grupo, leer_output)) %>%
  select(datos) %>%
  unnest(datos) %>%
  group_by(grupo, muestra) %>%
  mutate(
    total_contigs = n(),
    longitud_total_muestra = sum(longitud, na.rm = TRUE),
    porcentaje_longitud = round(100 * longitud / longitud_total_muestra, 2),
    porcentaje_contig = round(100 / total_contigs, 2),
    asignacion = if_else(estado == "U" | taxid == "0", "No clasificado", taxid)) %>%
  ungroup() %>%
  select(
    grupo, muestra, contig, longitud, porcentaje_longitud,
    porcentaje_contig, estado, asignacion)

dir.create("res_final", showWarnings = FALSE)

write_csv(
  tabla_contigs,
  "res_final/anexo_03_identificación_contigs_kraken.csv")




tabla_resumen_especies <- tabla_contigs %>%
  filter(estado == "C") %>%
  mutate(especie = case_when(
    str_detect(asignacion, regex("Pseudomonas aeruginosa", TRUE)) ~ "Pseudomonas aeruginosa",
    str_detect(asignacion, regex("Bacillus pacificus", TRUE)) ~ "Bacillus pacificus",
    str_detect(asignacion, regex("Bacillus cereus", TRUE)) ~ "Bacillus cereus",
    str_detect(asignacion, regex("Escherichia coli", TRUE)) ~ "Escherichia coli",
    TRUE ~ "Otras especies")) %>%
  group_by(grupo, muestra, especie) %>%
  summarise(porcentaje_longitud = round(sum(porcentaje_longitud), 2),
            porcentaje_contig = round(sum(porcentaje_contig), 2),
            .groups = "drop") %>%
  filter(porcentaje_longitud >= 1) %>%
  arrange(grupo, muestra, desc(porcentaje_longitud))

filas_sombra <- tabla_resumen_especies %>%
  distinct(grupo, muestra) %>%
  mutate(sombra = row_number() %% 2 == 0) %>%
  right_join(tabla_resumen_especies, by = c("grupo", "muestra")) %>%
  pull(sombra)

tabla_resumen_especies_ft <- tabla_resumen_especies %>%
  mutate(grupo = recode(grupo, control = "Controles", muestra = "Muestras"),
         across(c(porcentaje_longitud, porcentaje_contig), ~ round(.x, 2))) %>%
  flextable() %>%
  merge_v(j = c("grupo", "muestra")) %>%
  set_header_labels(grupo = "Grupo", muestra = "Aislado", especie = "Especie",
                    porcentaje_longitud = "% longitud", porcentaje_contig = "% contigs") %>%
  theme_booktabs() %>% bold(part = "header") %>%
  fontsize(size = 8, part = "all") %>% padding(padding = 1, part = "all") %>%
  bg(i = which(filas_sombra), bg = "#F2F2F2", part = "body") %>%
  bg(i = ~ muestra == "Rectal_P11", bg = "#FDEDEC", part = "body") %>%
  align(align = "center", part = "all") %>%
  align(j = c("grupo", "muestra", "especie"), align = "left", part = "all") %>%
  autofit()