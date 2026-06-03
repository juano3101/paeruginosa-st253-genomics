# DISTANCIAS FILOGENÉTICAS RESPECTO A PA14

dist_pa14 <- as.data.frame(distancias) %>%
  rownames_to_column("muestra") %>%
  select(muestra, distancia_pa14 = `Reference PA14`)


# MÉTRICAS DE CALIDAD DE ENSAMBLAJE
# (SOLO ENSAMBLAJES FILTRADOS Y PULIDOS CON MEDAKA)


datos_divergencia <- tabla_calidad_ensamblaje %>%
  filter(estrategia == "filt_medaka") %>%
  select(
    muestra,
    quast_contigs,
    quast_n50,
    busco_gaps_pct,
    busco_completos_pct) %>%
  left_join(dist_pa14, by = "muestra") %>%
  filter(!str_detect(muestra, "Reference|Outgroup|PAO1|PA14"))


# ============================================================
# CUANTIFICACIÓN DE POSICIONES AMBIGUAS (N)
# Y GAPS EN EL ALINEAMIENTO DEL CORE GENOME
# ============================================================

aln <- readDNAStringSet("work/phylogeny/core.full.aln")

resumen_aln <- tibble(
  muestra = names(aln),
  longitud = Biostrings::width(aln),
  n_N = str_count(as.character(aln), "N"),
  n_gaps = str_count(as.character(aln), "-")) %>%
  mutate(
    pct_N = round(100 * n_N / longitud, 4),
    pct_gaps = round(100 * n_gaps / longitud, 4),
    muestra = str_remove(muestra, "^snippy_"),
    muestra = str_remove(muestra, "__.*"),
    muestra = recode(
      muestra,
      "Reference" = "Reference PA14",
      "PAO1" = "Outgroup PAO1"))


# ============================================================
# INTEGRACIÓN DE MÉTRICAS DE CALIDAD,
# DISTANCIAS FILOGENÉTICAS Y ALINEAMIENTO
# ============================================================

datos_divergencia2 <- datos_divergencia %>%
  left_join(
    resumen_aln %>%
      select(muestra, n_N, pct_N, n_gaps, pct_gaps),
    by = "muestra") %>%
  arrange(desc(distancia_pa14))


# ============================================================
# CORRELACIONES ENTRE DIVERGENCIA FILOGENÉTICA
# Y CALIDAD DE ENSAMBLAJE
# ============================================================

cor_contigs <- cor.test(
  datos_divergencia2$distancia_pa14,
  datos_divergencia2$quast_contigs,
  method = "spearman")

cor_n50 <- cor.test(
  datos_divergencia2$distancia_pa14,
  datos_divergencia2$quast_n50,
  method = "spearman")

cor_N <- cor.test(
  datos_divergencia2$distancia_pa14,
  datos_divergencia2$n_N,
  method = "spearman")


# ============================================================
# TABLA RESUMEN DE CORRELACIONES
# ============================================================

tabla_correlaciones <- tibble(
  Comparación = c(
    "Distancia a PA14 vs número de contigs",
    "Distancia a PA14 vs N50",
    "Distancia a PA14 vs posiciones ambiguas (N)"),
  Rho_Spearman = c(
    unname(cor_contigs$estimate),
    unname(cor_n50$estimate),
    unname(cor_N$estimate)),
  p_valor = c(
    cor_contigs$p.value,
    cor_n50$p.value,
    cor_N$p.value)) %>%
  mutate(
    Rho_Spearman = round(Rho_Spearman, 3),
    p_valor = round(p_valor, 3))


# TABLA DETALLADA POR AISLADO
tabla_divergencia <- datos_divergencia2 %>%
  transmute(
    Aislado = muestra,
    `Distancia a PA14 (SNPs)` = distancia_pa14,
    Contigs = quast_contigs,
    N50 = quast_n50,
    `BUSCO completos (%)` = busco_completos_pct,
    `Posiciones ambiguas (N)` = n_N,
    `% posiciones ambiguas` = pct_N,
    Gaps = n_gaps,
    `% gaps` = pct_gaps)

write_csv(
  tabla_divergencia,
  "res_final/anexo_07_calidad_ensamblaje_divergencia_filogenetica.csv")

# FORMATO FLEXTABLE:
# TABLA DE CORRELACIONES

ft_correlaciones <- tabla_correlaciones %>%
  flextable() %>%
  theme_booktabs() %>%
  bold(part = "header") %>%
  align(align = "center", part = "all") %>%
  bg(i = seq(2, nrow(tabla_correlaciones), 2), bg = "#F2F2F2", part = "body") %>%
  autofit()



# DISTANCIA FILOGENÉTICA VS NÚMERO DE CONTIGS

fig_contigs <- ggplot(
  datos_divergencia2,
  aes(quast_contigs, distancia_pa14, label = muestra)
) +
  geom_point(size = 3) +
  geom_text(nudge_y = 150, size = 3) +
  labs(
    x = "Número de contigs",
    y = "Distancia a PA14 (SNPs)"
  ) +
  theme_bw()


# DISTANCIA FILOGENÉTICA VS N50

fig_n50 <- ggplot(
  datos_divergencia2,
  aes(quast_n50, distancia_pa14, label = muestra)
) +
  geom_point(size = 3) +
  geom_text(nudge_y = 150, size = 3) +
  labs(
    x = "N50 del ensamblaje",
    y = "Distancia a PA14 (SNPs)"
  ) +
  theme_bw()

# DISTANCIA FILOGENÉTICA VS POSICIONES AMBIGUAS (N)

fig_N <- ggplot(
  datos_divergencia2,
  aes(n_N, distancia_pa14, label = muestra)
) +
  geom_point(size = 3) +
  geom_text(nudge_y = 150, size = 3) +
  labs(
    x = "Posiciones ambiguas (N) en el alineamiento",
    y = "Distancia a PA14 (SNPs)"
  ) 
  
  
library(ggrepel)
library(patchwork)

tema_div <- theme_bw() +
  theme(
    axis.title = element_text(size = 11),
    axis.text = element_text(size = 9),
    plot.title = element_text(size = 12, face = "bold"),
    panel.grid.minor = element_blank()
  )

fig_N <- ggplot(datos_divergencia2, aes(n_N, distancia_pa14, label = muestra)) +
  geom_point(size = 2.8) +
  geom_text_repel(size = 3, max.overlaps = Inf) +
  labs(x = "Posiciones ambiguas (N) en el alineamiento", y = "Distancia a PA14 (SNPs)") +
  tema_div

fig_n50 <- ggplot(datos_divergencia2, aes(quast_n50, distancia_pa14, label = muestra)) +
  geom_point(size = 2.8) +
  geom_text_repel(size = 3, max.overlaps = Inf) +
  labs(x = "N50 del ensamblaje", y = "Distancia a PA14 (SNPs)") +
  tema_div

fig_contigs <- ggplot(datos_divergencia2, aes(quast_contigs, distancia_pa14, label = muestra)) +
  geom_point(size = 2.8) +
  geom_text_repel(size = 3, max.overlaps = Inf) +
  labs(x = "Número de contigs", y = "Distancia a PA14 (SNPs)") +
  tema_div

fig_divergencia_calidad <- fig_N + fig_n50 + fig_contigs +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(size = 14, face = "bold"))

