### FILOGENIA

tabla_st_arbol <- tabla_st_centro %>%
  transmute(
    muestra = as.character(muestra),
    ST_simple = case_when(
      `Sin pulido` == `Pulido con Medaka` ~ `Pulido con Medaka`,
      `Sin pulido` == "ND" ~ `Pulido con Medaka`,
      `Pulido con Medaka` == "ND" ~ `Sin pulido`,
      TRUE ~ paste0(`Sin pulido`, " - ", `Pulido con Medaka`)),
    ST_label = paste0(" (", ST_simple, ")"))

arbol <- arbol_raw

arbol$tip.label <- arbol$tip.label %>%
  str_remove("^snippy_") %>%
  str_remove("__SRR.*") %>%
  str_remove("_filt$")

arbol$tip.label[arbol$tip.label == "Reference"] <- "Reference PA14 (ST-253)"
arbol$tip.label[arbol$tip.label == "PAO1"] <- "Outgroup PAO1 (ST-549)"

idx <- match(arbol$tip.label, tabla_st_arbol$muestra)

arbol$tip.label <- if_else(
  !is.na(idx),
  paste0(arbol$tip.label, tabla_st_arbol$ST_label[idx]),
  arbol$tip.label)

arbol_root <- midpoint(arbol, node.labels = "support") %>%
  ladderize(right = TRUE)

# Función base para graficar
plot_arbol <- function(arbol_obj, xlim_val, offset_val, titulo, subtitulo) {
  ggtree(arbol_obj, size = 0.8) +
    geom_tiplab(size = 4, fontface = "bold", align = FALSE, 
                linetype = 3, color = "black")+
    theme_tree2() + scale_y_reverse() + xlim(0, xlim_val) +
    labs(title = titulo, subtitle = subtitulo)
}

p_tree_completo <- plot_arbol(
  arbol_root,
  xlim_val = 0,
  offset_val = 0,
  titulo = "Relación filogenómica global",
  subtitulo = "Linaje ST-253 con PA14 como referencia y PAO1 como outgroup") +
  geom_hilight(node = 21, fill = "pink", alpha = 0.35) +
  geom_hilight(node = 23, fill = "#F4A261", alpha = 0.35) +
  geom_hilight(node = 24, fill = "#2A9D8F", alpha = 0.35) +
  geom_hilight(node = 17, fill = "#457B9D", alpha = 0.35) +
  geom_hilight(node = 7, fill = "#E9C46A", alpha = 0.35) +
  scale_x_continuous(breaks = seq(0, 0.0675, by = 0.0075),
                     limits = c(0, 0.0675)) + 
  geom_cladelab(node=21, label="Grupo 2", align=TRUE, fill="pink",  
                alpha = 0.35, geom='label', offset = 0.008) +
  geom_cladelab(node=23, label="Grupo 3", align=TRUE, fill="#F4A261",  
                alpha = 0.35, geom='label', offset = 0.008) +
  geom_cladelab(node=24, label="Grupo 4", align=TRUE, fill="#2A9D8F",  
                alpha = 0.35, geom='label', offset = 0.008) +
  geom_cladelab(node=17, label="Grupo 5", align=TRUE, fill="#457B9D",  
                alpha = 0.35, geom='label', offset = 0.008) +
  geom_cladelab(node=7, label="Grupo 1", align=TRUE, fill="#E9C46A",  
                alpha = 0.35, geom='label', offset = 0.008)

arbol_clean <- drop.tip(arbol_root, "Outgroup PAO1 (ST-549)")
arbol_clean <- drop.tip(arbol_clean, "Reference PA14 (ST-253)")

p_final <- plot_arbol(
  arbol_clean, xlim_val = 0.013, offset_val = 0.0002,
  titulo = "Microevolución de aislados", subtitulo = "Linaje ST-253") +
  geom_hilight(node = 21, fill = "pink", alpha = 0.35) +
  geom_hilight(node = 16, fill = "#F4A261", alpha = 0.35) +
  geom_hilight(node = 17, fill = "#2A9D8F", alpha = 0.35) +
  geom_hilight(node = 18, fill = "#457B9D", alpha = 0.35) +
  geom_hilight(node = 5, fill = "#E9C46A", alpha = 0.35) +
  geom_text2(aes(subset = !isTip & !is.na(label) & label != "" & node != 13,
                 label = label),
             size = 3, vjust = 0.3, hjust = -0.1, color = "black") +
  geom_text2(aes(subset = node == 13, label = label),
             size = 3, vjust = -1, hjust = 8, color = "black") +
  scale_x_continuous(breaks = seq(0, 0.013, by = 0.001),
                     limits = c(0, 0.013)) + 
  geom_cladelab(node=21, label="Grupo 2", align=TRUE, fill="pink",  
                alpha = 0.35, geom='label', offset = 0.00009) +
  geom_cladelab(node=16, label="Grupo 3", align=TRUE, fill="#F4A261",  
                alpha = 0.35, geom='label', offset = 0.00009) +
  geom_cladelab(node=17, label="Grupo 4", align=TRUE, fill="#2A9D8F",  
                alpha = 0.35, geom='label', offset = 0.00009) +
  geom_cladelab(node=18, label="Grupo 5", align=TRUE, fill="#457B9D",  
                alpha = 0.35, geom='label', offset = 0.0012) +
  geom_cladelab(node=5, label="Grupo 1", align=TRUE, fill="#E9C46A",  
                alpha = 0.35, geom='label', offset = 0.00009)

figura_phyl_1 <- (p_tree_completo / p_final) +
  plot_annotation(tag_levels = "A",
                  theme = theme(
                    plot.title = element_text(size = 16, face = "bold"),
                    plot.tag = element_text(size = 14, face = "bold")))
