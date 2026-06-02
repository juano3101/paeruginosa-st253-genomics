### MLST

genes_mlst <- c("acsA", "aroE", "guaA", "mutL", "nuoD", "ppsA", "trpE")

tabla_mlst_anexo <- mlst_raw %>%
  transmute(
    muestra = basename(X1) %>% str_remove("__SRR.*") %>% str_remove("_filt\\.fasta$") %>% str_remove("\\.fasta$"),
    grupo = if_else(str_detect(X1, "controles"), "Control", "Muestra"),
    ensamblaje = case_when(
      str_detect(X1, "flye") ~ "Sin pulido",
      str_detect(X1, "medaka") ~ "Pulido con Medaka",
      TRUE ~ "Control"),
    esquema = X2,
    ST = if_else(X3 == "-", "No determinado", paste0("ST-", X3)),
    acsA = X4, aroE = X5, guaA = X6, mutL = X7, nuoD = X8, ppsA = X9, trpE = X10) %>%
  filter(muestra != "Rectal_P11", muestra != "CN_Escherichia_coli") %>%
  arrange(grupo, muestra, ensamblaje)

tabla_base <- mlst_raw %>%
  transmute(
    muestra = basename(X1) %>% str_remove("__SRR.*") %>% str_remove("_filt\\.fasta$") %>% str_remove("\\.fasta$"),
    pipeline = case_when(
      str_detect(X1, "flye") ~ "Sin pulido",
      str_detect(X1, "medaka") ~ "Pulido con Medaka",
      TRUE ~ "Control"),
    ST = if_else(X3 == "-", "ND", paste0("ST", X3)),
    acsA = X4, aroE = X5, guaA = X6, mutL = X7, nuoD = X8, ppsA = X9, trpE = X10) %>%
  filter(pipeline != "Control", muestra != "Rectal_P11") %>%
  mutate(pipeline = factor(pipeline, levels = c("Sin pulido", "Pulido con Medaka")))

tabla_mlst_estado <- tabla_base %>%
  pivot_longer(all_of(genes_mlst), names_to = "gen", values_to = "alelo") %>%
  mutate(
    alelo_num = str_extract(alelo, "\\d+"),
    estado = factor(
      case_when(
        str_detect(alelo, "\\(-\\)") ~ "No detectado",
        str_detect(alelo, "\\?\\)") ~ "Parcial",
        str_detect(alelo, "\\(~") ~ "Aproximado",
        TRUE ~ "Exacto"),
      levels = c("Exacto", "Aproximado", "Parcial", "No detectado")),
    gen = factor(gen, levels = genes_mlst),
    muestra = factor(muestra, levels = rev(sort(unique(muestra)))))

tabla_st_centro <- tabla_base %>%
  select(muestra, pipeline, ST) %>%
  pivot_wider(names_from = pipeline, values_from = ST) %>%
  mutate(
    ST_label = paste0(`Sin pulido`, " - ", `Pulido con Medaka`),
    muestra = factor(muestra, levels = levels(tabla_mlst_estado$muestra)),
    pipeline = factor("Sin pulido", levels = levels(tabla_base$pipeline)))

dir.create("res_final", showWarnings = FALSE)

write_csv(tabla_mlst_anexo, "res_final/anexo_04_mlst_completo.csv")

## crear gráfico
p_st_final <- ggplot(tabla_mlst_estado, aes(x = gen, y = muestra)) +
  geom_tile(aes(fill = estado), color = "white", linewidth = 0.4,   
            width = 0.9, height = 0.9) +
  geom_text(aes(label = alelo_num), color = "black", size = 4, fontface = "bold") +
  geom_text(
    data = tabla_st_centro, 
    aes(label = ST_label, y = muestra),
    x = 8.26, hjust = 0.5, size = 3, fontface = "bold", inherit.aes = FALSE) +
  facet_wrap(~ pipeline, nrow = 1) +
  scale_fill_manual(values = c(
    "Exacto" = "#DCE6F1", "Aproximado" = "#FDEEAF",
    "Parcial" = "#F8CBAD", "No detectado" = "#2F5597")) +
  coord_cartesian(clip = "off") + 
  labs(x = "Gen MLST", y = "Aislado", fill = "Estado del Alelo") +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1, face = "italic"),
    strip.text = element_text(face = "bold", size = 12),
    legend.position = "bottom",
    panel.spacing = unit(5, "lines"), 
    plot.margin = margin(2, 2, 2, 2)) + 
  theme(
    axis.text.x = element_text(size = 12),
    axis.text.y = element_text(size = 12),
    axis.title.x = element_text(size = 15, face = "bold"),
    axis.title.y = element_text(size = 15, face = "bold"), 
    legend.text = element_text(size = 13),
    legend.title = element_text(size = 12),
    strip.text = element_text(size = 13))