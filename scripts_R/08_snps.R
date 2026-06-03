limpiar_nombres <- function(x) {
  x %>% str_remove("^snippy_") %>% str_remove("__SRR.*") %>% str_remove("_filt$")
}

rownames(distancias) <- limpiar_nombres(rownames(distancias))
colnames(distancias) <- limpiar_nombres(colnames(distancias))

# Ajuste de nombres de referencia
rownames(distancias)[rownames(distancias) == "Reference"] <- "Reference PA14"
colnames(distancias)[colnames(distancias) == "Reference"] <- "Reference PA14"
rownames(distancias)[rownames(distancias) == "PAO1"] <- "Outgroup PAO1"
colnames(distancias)[colnames(distancias) == "PAO1"] <- "Outgroup PAO1"

write_csv(distancias, "res_final/anexo_05_matriz_distancias.csv")

# DEFINICIÓN DE COLORES Y COLORES
# Mapeo exacto de muestras a clados según tu imagen
grupos <- c(
  "Tracheal_discharge_P2" = "Grupo 1", "Rectal_P2"= "Grupo 2",
  "Rectal_P3" = "Grupo 2", "Rectal_1_P12" = "Grupo 3",
  "Urine_2_P12" = "Grupo 3", "Rectal_P9" = "Grupo 4",
  "Wound_2_P12" = "Grupo 4", "Rectal_2_P12" = "Grupo 5",
  "Blood_P11" = "Grupo 5", "Sputum_P3" = "Grupo 5",
  "Tracheal_discharge_P9" = "Grupo 5")

# Colores exactos para los bloques
colores_clados <- c(
  "Grupo 1" = "#E9C46A", "Grupo 2" = "pink", "Grupo 3" = "#F4A261", 
  "Grupo 4" = "#2A9D8F", "Grupo 5" = "#457B9D")

# Filtrar solo cepas clínicas
distancias_clinicas <- as.matrix(distancias)
distancias_clinicas <- distancias_clinicas[
  !rownames(distancias_clinicas) %in% c("Reference PA14", "Outgroup PAO1"),
  !colnames(distancias_clinicas) %in% c("Reference PA14", "Outgroup PAO1")]

# Tamaño del core para porcentajes
distancias_pct <- round((distancias_clinicas / tam_core_full) * 100, 3)

etiquetas_matriz <- matrix(
  paste0(distancias_clinicas, "\n(", sprintf("%.3f", distancias_pct), "%)"),
  nrow = nrow(distancias_clinicas),
  dimnames = dimnames(distancias_clinicas))

diag(etiquetas_matriz) <- ""
diag(distancias_pct) <- NA

anotacion_grupo <- grupos[rownames(distancias_clinicas)]

ha_col <- HeatmapAnnotation(
  Grupo = anotacion_grupo,
  col = list(Grupo = colores_clados),
  annotation_name_gp = gpar(fontsize = 10, fontface = "bold"))

ha_row <- rowAnnotation(
  Grupo = anotacion_grupo,
  col = list(Grupo = colores_clados),
  annotation_name_gp = gpar(fontsize = 10, fontface = "bold"))

p_snp_final <- Heatmap(
  distancias_pct,
  name = "% divergencia",
  col = colorRamp2(c(0, 0.08, 0.15), c("#FFFFFF", "#EECFA1", "#8B795E")),
  cluster_rows = TRUE, cluster_columns = TRUE,
  clustering_method_rows = "complete", clustering_method_columns = "complete",
  top_annotation = ha_col,
  left_annotation = ha_row, row_names_side = "right",
  column_names_rot = 45, na_col = "white", rect_gp = gpar(col = "white", lwd = 1),
  cell_fun = function(j, i, x, y, width, height, fill) {
    if (etiquetas_matriz[i, j] != "") {
      grid.text(etiquetas_matriz[i, j], x, y,
                gp = gpar(fontsize = 7, fontface = "bold"))}},
  column_title = "Matriz de distancia genética: SNPs y porcentaje de divergencia",
  column_title_gp = gpar(fontsize = 12, fontface = "bold"))

# RENDERIZADO FINAL
# Creamos una función o un objeto que contenga ambas instrucciones
p_snp_final_completo <- grid.grabExpr({
  # A. Dibujar el Heatmap principal
  # (Asegúrate de que p_snp_final esté definido antes)
  draw(p_snp_final, merge_legend = TRUE)
  # B. Añadir la nota técnica abajo a la derecha
  grid.text(
    paste0("Core Genome: ", format(tam_core_full, big.mark=","), " bp\n",
           "Nota: Los porcentajes de divergencia se calcularon basándose en la\n",
           "cantidad de SNPs detectados frente al tamaño total del core genome."), 
    x = unit(1, "npc") - unit(8, "mm"), # Pegado al borde derecho
    y = unit(8, "mm"),                  # Pegado al borde inferior
    just = c("right", "bottom"),
    gp = gpar(fontsize = 8, fontface = "italic", lineheight = 1))})
