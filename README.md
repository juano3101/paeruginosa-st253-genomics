# *Pseudomonas aeruginosa* ST-253 Genomics Pipeline

Pipeline bioinformático reproducible para el análisis genómico de aislados clínicos de *Pseudomonas aeruginosa* ST-253 utilizando secuenciación Nanopore.

## Clonar repositorio

```bash
git clone https://github.com/juano3101/paeruginosa-st253-genomics.git
cd paeruginosa-st253-genomics
```

# Índice

- [00. Descargar secuencias](#00-descargar-secuencias)
- [01. Control de calidad de lecturas crudas](#01-control-de-calidad-de-lecturas-crudas)
- [02. Filtrado de lecturas](#02-filtrado-de-lecturas)
- [03. Control de calidad de lecturas filtradas](#03-control-de-calidad-de-lecturas-filtradas)
- [04. Ensamblaje con Flye](#04-ensamblaje-con-flye)
- [05. Anotación genómica](#05-anotación-genómica)
  - [05.1 Anotación con Prokka](#051-anotación-con-prokka)

# 00. Descargar secuencias

Los datos brutos de secuenciación correspondientes a lecturas Nanopore fueron recuperados desde el repositorio público del NCBI bajo el BioProject `PRJNA946810`, el cual investigó el origen endógeno de infecciones por *Pseudomonas aeruginosa* en pacientes hospitalizados en Ecuador. Del total de aislados disponibles en dicho proyecto, se seleccionaron exclusivamente aquellos pertenecientes al sequence type ST-253, incluyendo aislados clínicos obtenidos de diferentes tipos de muestra y correspondientes a cinco pacientes hospitalizados.

## Instalar SRA Toolkit

Para descargar las lecturas desde NCBI/SRA se requiere `sra-tools`.

* [SRA Toolkit GitHub Repository](https://github.com/ncbi/sra-tools?utm_source=chatgpt.com) (v3.4.1)

Se recomienda instalarlo dentro de un ambiente Conda para mantener la reproducibilidad del pipeline.

```bash
conda create -n sra_tools -c bioconda -c conda-forge sra-tools -y
conda activate sra_tools
```

Verificar instalación:

```bash
which fasterq-dump
which prefetch
vdb-config --version
```

## Ejecutar descarga

Con el ambiente `sra_tools` activado, ejecutar:

```bash
chmod +x scripts/00_download/download_data.sh
bash scripts/00_download/download_data.sh
```

Verificar los archivos FASTQ descargados:

```bash
ls data/raw_fastq/
ls data/controles/
```
# 01. Control de calidad de lecturas crudas

El control de calidad inicial de las lecturas Nanopore se realizó utilizando `FastQC`, `NanoPlot` y `MultiQC`, con el objetivo de evaluar métricas como distribución de longitudes, calidad Phred, contenido GC y resumen global de calidad antes del filtrado de lecturas.

## Instalar herramientas de control de calidad

Las herramientas utilizadas pueden consultarse en sus repositorios oficiales:

* [FastQC GitHub Repository](https://github.com/s-andrews/fastqc) (v0.12.1)
* [NanoPlot GitHub Repository](https://github.com/wdecoster/nanoplot) (v1.46.2)
* [MultiQC GitHub Repository](https://github.com/multiqc/multiqc) (v1.35)

Se recomienda instalar todas las herramientas dentro de un mismo ambiente Conda.

```bash
conda create -n qc_env -c bioconda -c conda-forge fastqc nanoplot multiqc -y
conda activate qc_env
```

Verificar instalación:

```bash
which fastqc
which NanoPlot
which multiqc
```

## Ejecutar control de calidad

El script `qc_reads.sh` permite ejecutar el análisis de calidad tanto para lecturas crudas como filtradas.

### Lecturas crudas

```bash
chmod +x scripts/01_qc/qc_reads.sh
bash scripts/01_qc/qc_reads.sh data/seq raw
```

### Lecturas filtradas

```bash
bash scripts/01_qc/qc_reads.sh results/filtered filtered
```

## Resultados
Revisar Los resultados en:

```bash
ls results/qc/raw/
ls results/qc/filtered/
```

# 02. Filtrado de lecturas

El filtrado de lecturas Nanopore se realizó utilizando `Filtlong`, con el objetivo de eliminar lecturas cortas y de baja calidad antes del ensamblaje genómico. Se aplicaron filtros mínimos de longitud y calidad promedio Phred para mejorar la calidad global de las lecturas utilizadas en los análisis posteriores.

## Instalar Filtlong

El repositorio oficial de `Filtlong` puede consultarse en:

* [Filtlong GitHub Repository](https://github.com/rrwick/filtlong) (v0.3.1)

Se recomienda instalar la herramienta dentro de un ambiente Conda independiente.

```bash id="5m9t3v"
conda create -n filtlong_env -c bioconda -c conda-forge filtlong -y
conda activate filtlong_env
```
Verificar instalación:

```bash id="8hgc6m"
which filtlong
filtlong --help | head
```

## Ejecutar filtrado

El script `filter_reads.sh` realiza el filtrado automático de lecturas para todas las muestras utilizando los parámetros definidos en el pipeline.

```bash id="7o4r1z"
chmod +x scripts/02_filt/filter_reads.sh
bash scripts/02_filt/filter_reads.sh
```

## Parámetros utilizados

```bash id="pqxq4n"
--min_length 1000
--min_mean_q 10
```

## Resultados
Revisar las lecturas filtradas generadas en:

```bash
ls results/filtered/
```

# 03.Control de calidad de lecturas filtradas

Después del filtrado, se realizó nuevamente el control de calidad de las lecturas Nanopore para evaluar los cambios en la calidad promedio, longitud de lectura, contenido GC y distribución de las secuencias retenidas.

Este paso utiliza el mismo ambiente Conda creado para el control de calidad de lecturas crudas.

```bash
conda activate qc_env
```

## Ejecutar control de calidad

```bash
bash scripts/01_qc/qc_reads.sh results/filtered filtered
```

## Resultados

Revisar los resultados generados en:

```bash
ls results/qc/filtered/
```

# 04. Ensamblaje con Flye

El ensamblaje de novo de los genomas se realizó utilizando `Flye`, un ensamblador optimizado para lecturas largas Nanopore.

## Instalar Flye

El repositorio oficial puede consultarse en:

* [Flye GitHub Repository](https://github.com/mikolmogorov/Flye)

Se recomienda instalar `Flye` dentro de un ambiente Conda independiente.

```bash
conda create -n flye_env -c bioconda -c conda-forge flye -y
conda activate flye_env
```

Verificar instalación:

```bash
which flye
flye --version
```

## Ejecutar ensamblaje

El script `flye_assembly.sh` permite ensamblar tanto lecturas crudas como lecturas filtradas.

### Ensamblaje de lecturas crudas

```bash
chmod +x scripts/03_assembly/flye_assembly.sh
bash scripts/03_assembly/flye_assembly.sh data/seq raw
```

### Ensamblaje de lecturas filtradas

```bash
bash scripts/03_assembly/flye_assembly.sh data/filt filtered
```

## Resultados

Revisar los ensamblajes generados en:

```bash
ls results/assembly/
```


# 05. Anotación genómica

La anotación funcional de los ensamblajes bacterianos se realizó utilizando herramientas especializadas para identificación de genes codificantes, ARN ribosomal y otras características genómicas.

## 05.1 Anotación con Prokka

La anotación genómica inicial fue realizada utilizando `Prokka`.

### Instalar Prokka

El repositorio oficial puede consultarse en:

* [Prokka GitHub Repository](https://github.com/tseemann/prokka?utm_source=chatgpt.com)

Se recomienda instalar `Prokka` dentro de un ambiente Conda independiente.

```bash id="r1r4dx"
conda create -n prokka_env -c bioconda -c conda-forge prokka -y
conda activate prokka_env
```

Verificar instalación:

```bash id="7vk0ov"
which prokka
prokka --version
```

### Ejecutar anotación

```bash id="wkpv6g"
chmod +x scripts/03_assembly/prokka_annotation.sh
bash scripts/03_assembly/prokka_annotation.sh
```

### Resultados

Revisar las anotaciones generadas en:

```bash id="k8rdsh"
ls results/prokka/
```

# 05. Pulido
# 06. Control de calidad de ensamblajes