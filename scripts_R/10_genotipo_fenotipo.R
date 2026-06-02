### ÁRBOL FILOGENÉTICO

arbol <- arbol_raw

arbol$tip.label <- arbol$tip.label %>%
  str_remove("^snippy_") %>%
  str_remove("__SRR.*") %>%
  str_remove("_filt$")

arbol$tip.label[arbol$tip.label == "Reference"] <- "Reference PA14 (ST-253)"
arbol$tip.label[arbol$tip.label == "PAO1"] <- "Outgroup PAO1 (ST-549)"

arbol_root <- midpoint(arbol, node.labels = "support") %>%
  ladderize(right = TRUE)

arbol_clean <- arbol_root %>%
  drop.tip("Outgroup PAO1 (ST-549)") %>%
  drop.tip("Reference PA14 (ST-253)")

metadata_tree <- metadata %>%
  dplyr::rename(label = id)

arbol_base <- ggtree(arbol_clean, size = 0.8) +
  geom_tiplab(
    size = 3,
    fontface = "bold",
    align = TRUE,
    linetype = 3,
    color = "black",
    offset = 0.0006
  ) +
  geom_hilight(node = 21, fill = "pink", alpha = 0.35) +
  geom_hilight(node = 16, fill = "#F4A261", alpha = 0.35) +
  geom_hilight(node = 17, fill = "#2A9D8F", alpha = 0.35) +
  geom_hilight(node = 18, fill = "#457B9D", alpha = 0.35) +
  geom_hilight(node = 5, fill = "#E9C46A", alpha = 0.35) +
  scale_y_reverse() +
  xlim(0, 0.04)


###########################
####CAPA SEXO#############
##########################

arbol_sexo <- arbol_base +
  geom_fruit(
    data = metadata,
    geom = geom_tile,
    mapping = aes(y = id, fill = sex),
    color = "black",
    width = 0.001,
    offset = 0.7,
    pwidth = 0.05,
    axis.params = list(
      axis = "x", text = "Sexo", text.angle = 90,
      text.size = 3, vjust = 0.3, hjust = 0.5)) +
  scale_fill_manual(
    values = c(female = "#F4A6C1", male = "#8EC5F4"),
    labels = c(female = "Femenino", male = "Masculino"),
    name = "Sexo")  +
  theme(legend.position = "right")


###########################
####CAPA MUESTRAS#############
##########################
arbol_C2 <- arbol_sexo +
  new_scale_fill()

# Partimos de arbol_sexo para seguir sumando capas
arbol_muestras <- arbol_C2 +
  geom_fruit(
    data = metadata,
    geom = geom_tile,
    mapping = aes(y = id, fill = tipo_muestra),
    color = "black", size = 0.2,
    width = 0.001, offset = 0.155, pwidth = 0.02,
    axis.params = list(
      axis = "x", text = "Muestra", text.angle = 90, 
      text.size = 3, vjust = 0.3, hjust = 0.5)) +
  scale_fill_manual(
    values = c(
      "Blood" = "#E76F51", 
      "Rectal" = "#264653", 
      "Sputum" = "#E9C46A", 
      "Tracheal discharge" = "#F4A261",
      "Urinary" = "#7B68EE",
      "Wound" = "#2A9D8F"),
    name = "Muestra") +
  theme(legend.position = "right")


###########################
####CAPA PACIENTE#############
##########################
arbol_C3 <- arbol_muestras + new_scale_fill()

arbol_paciente <- arbol_C3 +
  geom_fruit(data = metadata, geom = geom_tile, 
             mapping = aes(y = id, fill = paciente), 
             color = "black", size = 0.2, width = 0.001, 
             offset = 0.14, pwidth = 0.02, 
             axis.params = list(axis = "x", text = "Paciente", text.angle = 90, 
                                text.size = 3, vjust = 0.3, hjust = 0.5)) +
  scale_fill_manual(values = c(P11 = "#D870AD", P12 = "#A6D854", P2 = "#66C2A5", P3 = "#FC8D62", P9 = "#8DA0CB"), name = "Paciente")  +
  theme(legend.position = "right")



###########################
#### CAPA GENES ###########
###########################
tabla_genes_larga <- matriz_genes_detalle %>%
  as.data.frame() %>%
  rownames_to_column("id") %>%
  pivot_longer(-id, names_to = "gen", values_to = "evento") %>%
  mutate(gen = case_when(gen %in% c("blaOXA", "blaOXA-488") ~ "blaOXA", gen %in% c("blaPDC", "blaPDC-34") ~ "blaPDC", str_detect(gen, "^nalC") ~ gen, TRUE ~ str_remove(gen, "_.*$"))) %>%
  group_by(id, gen) %>%
  summarise(evento = max(evento, na.rm = TRUE), .groups = "drop") %>%
  left_join(mecanismos_genes %>% mutate(gen_plot = case_when(str_detect(gen_plot, "^nalC") ~ gen_plot, TRUE ~ str_remove(gen_plot, "_.*$"))) %>% distinct(gen_plot, mecanismo), by = c("gen" = "gen_plot")) %>%
  mutate(evento = factor(evento, levels = c(0, 1, 2, 3), labels = c("Ausente", "Gen AMR", "Mutación puntual", "Mutación disruptiva")))

arbol_C5 <- arbol_paciente + new_scale_fill()

orden_genes <- c("aph(3')-IIb", "aadA6", "aac(6')-29", 
                 "blaOXA", "blaPDC", "blaVIM-2", "gyrA", 
                 "ftsI", "nalC_G71E", "nalC_S209R", "nalD", 
                 "mexR", "mexZ", "ampD", "oprD")

tabla_genes_larga <- tabla_genes_larga %>%
  filter(gen %in% orden_genes) %>%
  mutate(gen = factor(gen, levels = orden_genes))

arbol_genes <- arbol_C5 +
  geom_fruit(data = tabla_genes_larga, geom = geom_tile, mapping = aes(y = id, x = gen, fill = evento), color = "black", 
             size = 0.15, offset = 0.065, pwidth = 0.8, 
             axis.params = list(axis = "x", text.angle = 90, 
                                text.size = 3, vjust = 0.5, 
                                hjust = 0.22, line.color = "white")) +
  scale_fill_manual(values = c("Ausente" = "#CDC9C9", "Gen AMR" = "#2171B5", "Mutación puntual" = "#F4A261",
                               "Mutación disruptiva" = "#D73027"), name = "Tipo de evento")

capas_genes <- ggplot_build(arbol_genes)$data
capa_genes_data <- capas_genes[[tail(which(sapply(capas_genes, function(x) all(c("xmin", "xmax", "ymin", "ymax", "x") %in% names(x)) && is.numeric(x$x) && length(unique(round(x$x, 6))) == length(orden_genes))), 1)]]

coords_genes <- capa_genes_data %>%
  arrange(xmin) %>%
  distinct(xmin, xmax) %>%
  mutate(gen = orden_genes)

coords_mecanismos <- coords_genes %>%
  left_join(tabla_genes_larga %>% distinct(gen, mecanismo) %>% mutate(gen = as.character(gen)), by = "gen") %>%
  group_by(mecanismo) %>%
  summarise(xmin = min(xmin), xmax = max(xmax), .groups = "drop") %>%
  mutate(mecanismo = factor(mecanismo, levels = orden_mecanismo), ymin = 0.38, ymax = 0.28)

arbol_genes_f <- arbol_genes +
  new_scale_fill() +
  geom_rect(data = coords_mecanismos, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = mecanismo), inherit.aes = FALSE, color = "black", size = 0.1) +
  scale_fill_manual(values = colores_mecanismos, name = "Mecanismo de resistencia") +
  coord_cartesian(clip = "off") 


###########################
#### CAPA ANTIBIÓTICO #####
###########################
# 1. Tu diccionario y preparación de datos (esto está perfecto)
dicc_ab <- tibble(
  antibiotico = c("amikacin", "gentamicin", "ceftazidime", "cefepime", "imipenem", "meropenem", "piperacillin_tazobactam", "ciprofloxacin", "levofloxacin"),
  ab = c("AMK", "GEN", "CAZ", "FEP", "IPM", "MEM", "TZP", "CIP", "LVX"),
  familia = c("Aminoglucósidos", "Aminoglucósidos", "Cefalosporinas", "Cefalosporinas", "Carbapenémicos", "Carbapenémicos", "Penicilinas + inhibidor", "Fluoroquinolonas", "Fluoroquinolonas"),
  color = c("#00CED1", "#00CED1", "#388E3C", "#388E3C", "#F57C00", "#F57C00", "#7B1FA2", "#90EE90", "#90EE90"))

metadata_ab <- metadata %>%
  select(id, all_of(dicc_ab$antibiotico)) %>%
  pivot_longer(-id, names_to = "antibiotico", values_to = "fenotipo") %>%
  left_join(dicc_ab, by = "antibiotico") %>%
  mutate(ab = factor(ab, levels = dicc_ab$ab))

# 2. Generar el árbol con el antibiograma
arbol_ab <- arbol_genes_f + new_scale_fill() +
  geom_fruit(data = metadata_ab, geom = geom_tile, 
             mapping = aes(y = id, x = ab, fill = fenotipo), 
             color = "black", size = 0.2, offset = 0.055, pwidth = 0.4, 
             axis.params = list(axis = "x", text.angle = 90, 
                                text.size = 3, vjust = 0.3, hjust = 0.5, line.color = "white")) +
  scale_fill_manual(values = c(R = "#CD5555", S = "#A2CD5A"), name = "Antibiograma")

# 3. EXTRAER DATOS SIN ERRORES (Búsqueda por número de filas)
todas_las_capas <- ggplot_build(arbol_ab)$data
n_esperado <- nrow(metadata_ab) # El número exacto de celdas dibujadas

# Buscamos qué capa tiene ese número de filas
idx_capa <- which(sapply(todas_las_capas, nrow) == n_esperado)
capa_ab_data <- todas_las_capas[[max(idx_capa)]] # Tomamos la última que coincida

# 4. Crear coordenadas y df_familias
coords_ab <- capa_ab_data %>%
  arrange(xmin) %>%
  distinct(xmin, xmax) %>%
  mutate(ab = levels(metadata_ab$ab)) %>%
  left_join(dicc_ab %>% select(ab, familia, color), by = "ab")

df_familias <- coords_ab %>%
  group_by(familia, color) %>%
  summarise(xmin = min(xmin), xmax = max(xmax), .groups = "drop") %>%
  mutate(familia = factor(familia, levels = unique(dicc_ab$familia)), 
         ymin = 0.38,  # Ajustado para que sea fino y pegado
         ymax = 0.28)

# 5. Gráfico final con rectángulos unidos al heatmap
arbol_ab_f <- arbol_ab + new_scale_fill() +
  geom_rect(data = df_familias, 
            aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = familia), 
            inherit.aes = FALSE, color = "black", size = 0.1) +
  scale_fill_manual(values = setNames(unique(dicc_ab$color), unique(dicc_ab$familia)), 
                    name = "Familia de antibióticos") +
  coord_cartesian(clip = "off") +
  theme(legend.position = "right")

extraer_leyenda <- function(p, i = 1, ncol = 2) {
  get_legend(p + theme(legend.position = "right") + guides(fill = guide_legend(ncol = ncol)))$grobs[[i]]
}

leyenda_sexo <- extraer_leyenda(arbol_sexo, 1, 2)
leyenda_muestra <- extraer_leyenda(arbol_muestras, 1, 2)
leyenda_paciente <- extraer_leyenda(arbol_paciente, 3, 2)
leyenda_evento <- extraer_leyenda(arbol_genes, 1, 2)
leyenda_mecanismo <- extraer_leyenda(arbol_genes_f, 2, 2)
leyenda_ab <- extraer_leyenda(arbol_ab, 5, 2)
leyenda_familia <- extraer_leyenda(arbol_ab_f, 6, 2)

leyendas_final <- plot_grid(
  leyenda_sexo,
  leyenda_muestra,
  leyenda_paciente,
  leyenda_mecanismo,
  leyenda_evento,
  leyenda_ab,
  leyenda_familia,
  ncol = 1,
  align = "v",
  rel_heights = c(1, 0.7, 1.1, 1, 0.8, 0.5, 1))

arbol_sin_leyenda <- arbol_ab_f +
  theme(
    legend.position = "none",
    plot.margin = margin(25))

# Usamos ggdraw para tener control total del posicionamiento
figura_final <- ggdraw() +
  # Dibujamos el árbol (ocupa todo el ancho pero el xlim lo controla)
  draw_plot(arbol_sin_leyenda, x = 0, y = 0, width = 0.8) + 
  # Dibujamos la leyenda pegadita (ajusta 'x' para acercar o alejar)
  draw_plot(leyendas_final, x = 0.77 , y = 0.05, width = 0.075, height = 0.9)

