library(tidyverse)
library(ComplexHeatmap)
library(circlize)
library(grid)


# 1. PROCESAMIENTO DE DATOS
tabla_amr_no_efflux <- tabla_amr_filtrada %>%
  filter(!str_detect(Class, "EFFLUX")) %>%
  filter(!`Element symbol` %in% c("fptA_G319AfsTer32","fptA_K75SfsTer42","fptA_S460AfsTer23"))

pacientes <- c(Blood_P11="P11", Rectal_1_P12="P12", Rectal_2_P12="P12", Urine_2_P12="P12", Wound_2_P12="P12", Tracheal_discharge_P2="P2", Rectal_P2="P2", Sputum_P3="P3", Rectal_P3="P3", Tracheal_discharge_P9="P9", Rectal_P9="P9")
orden_muestras <- names(pacientes)

colores_pacientes <- c(P11="#D870AD", P12="#A6D854", P2="#66C2A5", P3="#FC8D62", P9="#8DA0CB")

colores_sexo <- c(Femenino="#F4A6C1", Masculino="#8EC5F4")

colores_muestras <- c(Sangre="#E76F51", Rectal="#264653", Esputo="#E9C46A", `Secreción traqueal`="#F4A261", Urinaria="#7B68EE", Herida="#2A9D8F")

colores_evento <- c("0"="#CDC9C9","1"="#2171B5","2"="#F4A261","3"="#D73027")
colores_mecanismos <- c("Enz. Aminogl."="#E6AB02","β-lactamasa"="#7570B3","Diana Quinol."="#E7298A","PBP/Pared Cel."="#7AC5CD","Reg. Eflujo"="#1B9E77","Reg. AmpC"="#A6761D","Porina"="#666666")
orden_mecanismo <- names(colores_mecanismos)

tabla_gen_muestra_detalle <- tabla_amr_no_efflux %>%
  mutate(gen_plot=case_when(
    `Element symbol` %in% c("blaOXA","blaOXA-488")~"blaOXA",
    `Element symbol` %in% c("blaPDC","blaPDC-34")~"blaPDC",
    str_detect(`Element symbol`,"^nalC_G71E")~"nalC_G71E",
    str_detect(`Element symbol`,"^nalC_S209R")~"nalC_S209R",
    str_detect(`Element symbol`,"^nalD")~"nalD",
    str_detect(`Element symbol`,"^mexR")~"mexR",
    str_detect(`Element symbol`,"^mexZ")~"mexZ",
    str_detect(`Element symbol`,"^ampD")~"ampD",
    str_detect(`Element symbol`,"^oprD")~"oprD",
    TRUE~`Element symbol`),
    valor=case_when(Subtype=="AMR"~1, Subtype=="POINT"~2, Subtype=="POINT_DISRUPT"~3, TRUE~0)) %>%
  group_by(muestra, gen_plot) %>%
  summarise(valor=max(valor, na.rm=TRUE), .groups="drop")

matriz_genes_detalle <- tabla_gen_muestra_detalle %>%
  dplyr::select(muestra, gen_plot, valor) %>%
  pivot_wider(names_from=gen_plot, values_from=valor, values_fill=0) %>%
  column_to_rownames("muestra") %>%
  as.matrix()

orden_genes <- c("aph(3')-IIb","aadA6","aac(6')-29","blaOXA","blaPDC","blaVIM-2","gyrA_T83I","ftsI_R504C","nalC_G71E","nalC_S209R","nalD","mexR","mexZ","ampD","oprD")
orden_genes <- intersect(orden_genes, colnames(matriz_genes_detalle))
matriz_genes_detalle <- matriz_genes_detalle[orden_muestras, orden_genes, drop=FALSE]

mecanismos_genes <- tibble(gen_plot=colnames(matriz_genes_detalle)) %>%
  mutate(mecanismo=case_when(str_detect(gen_plot,"aac|aadA|aph")~"Enz. Aminogl.", str_detect(gen_plot,"blaPDC|blaOXA|blaVIM")~"β-lactamasa", str_detect(gen_plot,"gyrA")~"Diana Quinol.", str_detect(gen_plot,"ftsI")~"PBP/Pared Cel.", str_detect(gen_plot,"nalC|nalD|mexR|mexZ")~"Reg. Eflujo", str_detect(gen_plot,"ampD")~"Reg. AmpC", str_detect(gen_plot,"oprD")~"Porina", TRUE~"Otro"),
         mecanismo=factor(mecanismo, levels=orden_mecanismo))

split_filas_comun <- factor(pacientes[orden_muestras], levels=c("P11","P12","P2","P3","P9"))


# 2. HEATMAP DE METADATA (Con traducciones)
matriz_metadata_final <- metadata %>%
  filter(id %in% orden_muestras) %>%
  mutate(id = factor(id, levels = orden_muestras)) %>%
  arrange(id) %>%
  mutate(
    sex = case_when(sex == "female" ~ "Femenino", sex == "male" ~ "Masculino", TRUE ~ sex),
    tipo_muestra = case_when(
      tipo_muestra == "Blood" ~ "Sangre",
      tipo_muestra == "Rectal" ~ "Rectal",
      tipo_muestra == "Sputum" ~ "Esputo",
      tipo_muestra == "Tracheal discharge" ~ "Secreción traqueal",
      tipo_muestra == "Urinary" ~ "Urinaria",
      tipo_muestra == "Wound" ~ "Herida",
      TRUE ~ tipo_muestra)) %>%
  dplyr::select(id, paciente, sex, tipo_muestra) %>%
  dplyr::rename(Paciente = paciente, Sexo = sex, Muestra = tipo_muestra) %>% 
  column_to_rownames("id") %>%
  as.matrix() 

colores_metadata_lista <- c(colores_pacientes, colores_sexo, colores_muestras)

p_metadata <- Heatmap(
  matriz_metadata_final, 
  name = "Metadata",
  col = colores_metadata_lista,
  cluster_rows = FALSE, 
  cluster_columns = FALSE,
  row_split = split_filas_comun,       
  row_title_gp = gpar(fontsize = 0),   
  row_names_side = "left",
  row_names_gp = gpar(fontsize=8, fontface="bold"),
  column_names_rot = 45,
  column_names_gp = gpar(fontsize=8, fontface="bold"),
  rect_gp = gpar(col="black", lwd=0.7), 
  border = TRUE,
  show_heatmap_legend = FALSE,
  column_title = " ", 
  column_title_side = "top")


# 3. HEATMAP DE GENES
ha_genes <- HeatmapAnnotation(
  Mecanismo = mecanismos_genes$mecanismo, 
  col = list(Mecanismo = colores_mecanismos), 
  show_annotation_name = FALSE,
  show_legend = FALSE )

p_genes <- Heatmap(
  matriz_genes_detalle, name="Tipo de evento", col=colores_evento,
  cluster_rows=FALSE, cluster_columns=FALSE,
  row_split = split_filas_comun,       
  row_title_gp = gpar(fontsize = 0),   
  column_split=mecanismos_genes$mecanismo,
  column_gap=unit(1.2,"mm"), 
  top_annotation=ha_genes, 
  show_row_names=FALSE,                
  column_names_rot=45,
  column_names_gp=gpar(fontsize=7), 
  rect_gp=gpar(col="black", lwd=0.7), border=TRUE,
  show_heatmap_legend = FALSE,
  column_title = "Mecanismos de Resistencia",
  column_title_side = "top",
  column_title_gp = gpar(fontsize = 11, fontface = "bold"))


# 4. HEATMAP DE ANTIBIOGRAMA 
dicc_ab <- tibble(
  antibiotico=c("amikacin","gentamicin","ceftazidime","cefepime","imipenem","meropenem","piperacillin_tazobactam","ciprofloxacin","levofloxacin"),
  ab=c("AMK","GEN","CAZ","FEP","IPM","MEM","TZP","CIP","LVX"),
  familia=c("Aminoglucósidos","Aminoglucósidos","Cefalosporinas","Cefalosporinas","Carbapenémicos","Carbapenémicos","Penicilinas + inhibidor","Fluoroquinolonas","Fluoroquinolonas"))

metadata_ab <- metadata %>%
  filter(id %in% orden_muestras) %>%
  dplyr::select(id, all_of(dicc_ab$antibiotico)) %>%
  mutate(id=factor(id, levels=orden_muestras)) %>%
  arrange(id) %>%
  pivot_longer(-id, names_to="antibiotico", values_to="fenotipo") %>%
  left_join(dicc_ab, by="antibiotico") %>%
  # Traducimos R y S en el flujo de datos
  mutate(fenotipo = case_when(fenotipo == "R" ~ "Resistente", fenotipo == "S" ~ "Sensible", TRUE ~ fenotipo)) %>%
  mutate(ab=factor(ab, levels=dicc_ab$ab))

matriz_ab <- metadata_ab %>%
  dplyr::select(id, ab, fenotipo) %>%
  pivot_wider(names_from=ab, values_from=fenotipo) %>%
  column_to_rownames("id") %>%
  as.matrix()

colores_ab <- c(Resistente="#CD5555", Sensible="#A2CD5A")
colores_familia <- c("Aminoglucósidos"="#00CED1","Cefalosporinas"="#388E3C","Carbapenémicos"="#F57C00","Penicilinas + inhibidor"="#7B1FA2","Fluoroquinolonas"="#90EE90")

ha_ab <- HeatmapAnnotation(
  Familia = dicc_ab$familia, 
  col = list(Familia = colores_familia), 
  show_annotation_name = FALSE,
  show_legend = FALSE )

p_ab <- Heatmap(
  matriz_ab, name="Antibiograma", col=colores_ab,
  cluster_rows=FALSE, cluster_columns=FALSE,
  row_split = split_filas_comun,       
  row_title_gp = gpar(fontsize = 0),   
  column_split=factor(dicc_ab$familia, levels=unique(dicc_ab$familia)),
  column_gap=unit(1.2,"mm"), top_annotation=ha_ab,
  show_row_names=FALSE, column_names_rot=45, column_names_gp=gpar(fontsize=7),
  rect_gp=gpar(col="black", lwd=0.7), border=TRUE, 
  show_heatmap_legend = FALSE,
  column_title = "Perfil de Susceptibilidad (Familias)",
  column_title_side = "top",
  column_title_gp = gpar(fontsize = 11, fontface = "bold"))

# 5. CREACIÓN MANUAL DE LEYENDAS ÚNICAS

leg_paciente <- Legend(title = "Paciente", labels = names(colores_pacientes), legend_gp = gpar(fill = colores_pacientes))
leg_sexo     <- Legend(title = "Sexo",     labels = names(colores_sexo),      legend_gp = gpar(fill = colores_sexo))
leg_muestra  <- Legend(title = "Muestra",  labels = names(colores_muestras),  legend_gp = gpar(fill = colores_muestras))

leg_evento   <- Legend(title = "Tipo de evento", at = c(0, 1, 2, 3), labels = c("Ausente", "Gen AMR", "Mutación puntual", "Mutación disruptiva"), legend_gp = gpar(fill = colores_evento))
leg_antibio  <- Legend(title = "Antibiograma", labels = names(colores_ab), legend_gp = gpar(fill = colores_ab))

leg_mecanism <- Legend(title = "Mecanismo", labels = names(colores_mecanismos), legend_gp = gpar(fill = colores_mecanismos))
leg_familia  <- Legend(title = "Familia", labels = names(colores_familia), legend_gp = gpar(fill = colores_familia))

grupo_leyendas <- packLegend(
  leg_paciente, leg_sexo, 
  leg_muestra, leg_evento, 
  leg_antibio, leg_mecanism, 
  leg_familia, direction = "vertical")


# 6. UNIÓN Y DIBUJO DE LA FIGURA FINAL

figura_final <- p_metadata + p_genes + p_ab


