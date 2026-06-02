library(tidyverse)
library(flextable)

### TABLA DE METADATOS

tabla_metadata <- metadata %>%
  arrange(paciente, id) %>%
  transmute(
    Paciente = paciente,
    Hospital = hospital,
    Edad = age,
    Sexo = recode(sex, female = "Femenino", male = "Masculino"),
    Aislado = id,
    `Tipo de muestra` = tipo_muestra,
    Origen = origen,
    BioSample = bio_sample,
    SRR = SRR)

filas_bloque <- tabla_metadata %>%
  mutate(fila = row_number()) %>%
  group_by(Paciente) %>%
  mutate(grupo = cur_group_id()) %>%
  ungroup()

filas_paciente_sombra <- filas_bloque %>%
  filter(grupo %% 2 == 0) %>%
  pull(fila)

filas_aislado_sombra <- seq(2, nrow(tabla_metadata), 2)

tabla_metadata_ft <- flextable(tabla_metadata) %>%
  theme_booktabs() %>%
  merge_v(j = c("Paciente", "Hospital", "Edad", "Sexo"), combine = TRUE) %>%
  valign(j = c("Paciente", "Hospital", "Edad", "Sexo"), valign = "center", part = "body") %>%
  fontsize(size = 8, part = "all") %>%
  padding(padding = 2, part = "all") %>%
  line_spacing(space = 0.8, part = "all") %>%
  height(height = 0.22, part = "body") %>%
  bold(part = "header") %>%
  align(align = "center", part = "all") %>%
  align(j = "Aislado", align = "left", part = "all") %>%
  bg(i = filas_aislado_sombra, j = c("Aislado", "Tipo de muestra", "Origen", "BioSample", "SRR"), bg = "#F2F2F2", part = "body") %>%
  bg(i = filas_paciente_sombra, j = c("Paciente", "Hospital", "Edad", "Sexo"), bg = "#EDEDED", part = "body") %>%
  autofit()
