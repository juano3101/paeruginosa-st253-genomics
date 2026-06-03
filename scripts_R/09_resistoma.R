### CREAR TABLA DE GENES DE RESISTNECIAS

### AMRFINDER

tabla_amrfinder_completa <- map_dfr(
  muestras_amr,
  function(muestra) {
    
    archivo <- file.path(
      dir_amr,
      muestra,
      paste0(muestra, ".tsv"))
    
    read_tsv(
      archivo,
      show_col_types = FALSE) %>%
      mutate(
        muestra = muestra,
        .before = 1)
  }
)

write_csv(tabla_amrfinder_completa, "res_final/anexo_06_arm_finder_muestra.csv")

### TABLA RESUMEN
tabla_amr <- tabla_amrfinder_completa %>%
  filter(Subtype %in% c("AMR", "POINT", "POINT_DISRUPT")) %>%
  distinct(muestra, `Element symbol`, `Contig id`, Start, Strand, .keep_all = TRUE)


### GRAFICO SUBTYPE
tabla_subtype <- tabla_amr %>% count(muestra, Subtype)

p_Subtype <- ggplot(tabla_subtype,
                    aes(x = muestra, y = n, fill = Subtype)) +
  geom_col() + coord_flip() + scale_fill_brewer(palette = "Paired") + labs(fill = "Subtype") + theme_minimal()


### GRAFICO CLASS

tabla_class <- tabla_amr %>% count(muestra, Class)

p_Class <- ggplot(tabla_class,
                  aes(x = muestra, y = n, fill = Class)) +
  geom_col() + coord_flip() + scale_fill_brewer(palette = "Paired") +
  labs(fill = "Clase") + theme_minimal() + 
  theme(axis.text.y = element_blank())

### UNIR GRÁFICOS
p_final_resist <- (p_Subtype | p_Class) +
  plot_layout(guides = "collect", widths = c(1, 1.2)) &
  theme(legend.position = "right",
        legend.title = element_text(face = "bold", size = 11),
        legend.text = element_text(size = 10),
        plot.title = element_text(face = "bold", hjust = 0.5),
        axis.title.y = element_blank())


### FILTRAR TABLA
terminos_busqueda <- c("ciprofloxacin", "levofloxacin", "imipenem", "meropenem", "ceftazidime", "cefepime", "piperacillin", "tazobactam", "gentamicin", "amikacin", "QUINOLONE", "FLUOROQUINOLONE", "CARBAPENEM", "CEPHALOSPORIN", "BETA-LACTAM", "AMINOGLYCOSIDE", "MULTIDRUG", "EFFLUX")
patron_regex <- paste(terminos_busqueda, collapse = "|")

tabla_amr_filtrada <- tabla_amr %>%
  filter(if_any(c(Class, Subclass, `HMM description`, `Closest reference name`, `Element name`), ~ str_detect(., regex(patron_regex, ignore_case = TRUE)))) %>%
  mutate(Gene_Standard = str_replace(`Element symbol`, "[_\\-].*$", ""))

tabla_bombas_efflux <- tabla_amr_filtrada %>%
  filter(str_detect(Class, "EFFLUX"))

tabla_amr_no_efflux <- tabla_amr_filtrada %>%
  filter(!str_detect(Class, "EFFLUX"))
tabla_amr_no_efflux <- tabla_amr_no_efflux %>%
  filter(!`Element symbol` %in% c(
    "fptA_G319AfsTer32",
    "fptA_K75SfsTer42",
    "fptA_S460AfsTer23"
  ))

tabla_AMR_adquiridos <- tabla_amr_no_efflux %>% filter(Subtype == "AMR")
tabla_POINT_mutaciones <- tabla_amr_no_efflux %>% filter(Subtype == "POINT")
tabla_POINT_disrupt <- tabla_amr_no_efflux %>% filter(Subtype == "POINT_DISRUPT")



### RESISTOMA

colores_pacientes <- c(P11 = "#D870AD", P12 = "#A6D854", P2 = "#66C2A5", P3 = "#FC8D62", P9 = "#8DA0CB")

colores_mecanismos <- c(
  "Enz. Aminogl." = "#E6AB02", "β-lactamasa" = "#7570B3",
  "Diana Quinol." = "#E7298A", "PBP/Pared Cel." = "#7AC5CD",
  "Reg. Eflujo" = "#1B9E77", "Reg. AmpC" = "#A6761D",
  "Porina" = "#666666", "Otro" = "grey80")

orden_mecanismo <- c("Enz. Aminogl.", "β-lactamasa", "Diana Quinol.", "PBP/Pared Cel.", "Reg. Eflujo", "Reg. AmpC", "Porina")

pacientes <- c(
  Blood_P11 = "P11",
  Rectal_1_P12 = "P12",
  Rectal_2_P12 = "P12",
  Urine_2_P12 = "P12",
  Wound_2_P12 = "P12",
  Rectal_P2 = "P2",
  Tracheal_discharge_P2 = "P2",
  Rectal_P3 = "P3",
  Sputum_P3 = "P3",
  Rectal_P9 = "P9",
  Tracheal_discharge_P9 = "P9")

tabla_gen_muestra_detalle <- tabla_amr_no_efflux %>%
  mutate(
    gen_plot = case_when(
      `Element symbol` %in% c("blaOXA", "blaOXA-488") ~ "blaOXA",
      `Element symbol` %in% c("blaPDC", "blaPDC-34") ~ "blaPDC",
      TRUE ~ `Element symbol`),
    valor = case_when(
      Subtype == "AMR" ~ 1,
      Subtype == "POINT" ~ 2,
      Subtype == "POINT_DISRUPT" ~ 3,
      TRUE ~ 0)) %>%
  distinct(muestra, gen_plot, Subtype, valor)

matriz_genes_detalle <- tabla_gen_muestra_detalle %>%
  select(muestra, gen_plot, valor) %>%
  pivot_wider(names_from = gen_plot, values_from = valor, values_fill = 0) %>%
  column_to_rownames("muestra") %>%
  as.matrix()

orden_muestras <- names(pacientes)
matriz_genes_detalle <- matriz_genes_detalle[orden_muestras, , drop = FALSE]

mecanismos_genes <- tibble(
  gen_plot = colnames(matriz_genes_detalle),
  frecuencia = colSums(matriz_genes_detalle > 0)) %>%
  mutate(
    mecanismo = case_when(
      str_detect(gen_plot, "aac|aadA|aph") ~ "Enz. Aminogl.",
      str_detect(gen_plot, "blaPDC|blaOXA|blaVIM") ~ "β-lactamasa",
      str_detect(gen_plot, "gyrA") ~ "Diana Quinol.",
      str_detect(gen_plot, "ftsI") ~ "PBP/Pared Cel.",
      str_detect(gen_plot, "nalC|nalD|mexR|mexZ") ~ "Reg. Eflujo",
      str_detect(gen_plot, "ampD") ~ "Reg. AmpC",
      str_detect(gen_plot, "oprD") ~ "Porina",
      TRUE ~ "Otro"),
    mecanismo = factor(mecanismo, levels = orden_mecanismo),
    gen_base = str_remove(gen_plot, "_.*$")) %>%
  group_by(mecanismo, gen_base) %>%
  mutate(frecuencia_grupo = max(frecuencia)) %>%
  ungroup() %>%
  arrange(mecanismo, desc(frecuencia_grupo), gen_base, desc(frecuencia), gen_plot)

matriz_genes_detalle <- matriz_genes_detalle[, mecanismos_genes$gen_plot, drop = FALSE]

ha_row_detalle <- rowAnnotation(
  Paciente = pacientes[rownames(matriz_genes_detalle)],
  col = list(Paciente = colores_pacientes),
  show_annotation_name = FALSE)

ha_col_detalle <- HeatmapAnnotation(
  Mecanismo = mecanismos_genes$mecanismo,
  col = list(Mecanismo = colores_mecanismos),
  show_annotation_name = FALSE)

p_heatmap_genes_detalle <- Heatmap(
  matriz_genes_detalle,
  name = "Tipo de evento",
  col = c("0" = "#CDC9C9", "1" = "#2171B5", "2" = "#F4A261", "3" = "#D73027"),
  cluster_rows = FALSE,
  cluster_columns = FALSE,
  row_split = factor(pacientes[rownames(matriz_genes_detalle)], levels = c("P11", "P12", "P2", "P3", "P9")),
  column_split = mecanismos_genes$mecanismo,
  column_gap = unit(3, "mm"),
  bottom_annotation = ha_col_detalle,
  left_annotation = ha_row_detalle,
  row_names_side = "left",
  column_names_rot = 45,
  rect_gp = gpar(col = "black", lwd = 1),
  heatmap_legend_param = list(
    at = c(0, 1, 2, 3),
    labels = c("Ausente", "Gen AMR", "Mutación puntual", "Mutación disruptiva")),
  column_title = NULL,
  row_title = NULL,
  column_title_gp = gpar(fontsize = 10, fontface = "bold"))
