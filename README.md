# *Pseudomonas aeruginosa* ST-253 Genomics Pipeline

Pipeline bioinformático reproducible para el análisis genómico de aislados clínicos de *Pseudomonas aeruginosa* ST-253 utilizando secuenciación Nanopore.

## Clonar repositorio

```bash
git clone https://github.com/juano3101/paeruginosa-st253-genomics.git
cd paeruginosa-st253-genomics
```
# Flujo general del pipeline

![Pipeline bioinformático](figures/pipeline.svg)

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
conda create -n qc_env python=3.11 -y
conda activate qc_env

pip install NanoPlot
conda install -c bioconda -c conda-forge fastqc -y
conda install -c bioconda -c conda-forge multiqc -y
````

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

## Resultados
Revisar Los resultados en:

```bash
ls results/qc/raw/
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

Se eligió que se retengan únicamente lecturas con una longitud mínima de 1000 pb y se eliminen lecturas con calidad promedio Phred menor a 10.

```bash id="pqxq4n"
--min_length 1000
--min_mean_q 10
```

## Resultados
Revisar las lecturas filtradas generadas en:

```bash
ls data/filt/
```

# 03.Control de calidad de lecturas filtradas

Después del filtrado, se realizó nuevamente el control de calidad de las lecturas Nanopore para evaluar los cambios en la calidad promedio, longitud de lectura, contenido GC y distribución de las secuencias retenidas.

Este paso utiliza el mismo ambiente Conda creado para el control de calidad de lecturas crudas.

```bash
conda activate qc_env
```

## Ejecutar control de calidad

```bash
bash scripts/01_qc/qc_reads.sh data/filt filt
```

## Resultados

Revisar los resultados generados en:

```bash
ls results/qc/filt/
```

# 04. Ensamblaje con Flye

El ensamblaje de novo de los genomas se realizó utilizando `Flye`, un ensamblador optimizado para lecturas largas Nanopore.

## Instalar Flye

El repositorio oficial puede consultarse en:

* [Flye GitHub Repository](https://github.com/mikolmogorov/Flye) (2.9.6)

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

# 05 Pulido con Medaka

Después del ensamblaje inicial, los genomas fueron pulidos utilizando `Medaka` para corregir errores asociados a secuenciación Nanopore y mejorar la precisión de consenso de los ensamblajes.

## Instalar Medaka

El repositorio oficial puede consultarse en:

* [Medaka GitHub Repository](https://github.com/nanoporetech/medaka) (v2.2.2)

Se recomienda instalar `Medaka` dentro de un ambiente Conda independiente. La instalación mediante Conda incluye automáticamente dependencias necesarias como `samtools`, `minimap2`, `tabix` y `bgzip`.

```bash
conda create -n medaka_env -c conda-forge -c nanoporetech -c bioconda medaka -y
conda activate medaka_env
```

Verificar instalación:

```bash
which medaka_consensus
medaka_consensus --version
which minimap2
which samtools
```

### Ejecutar pulido

El script `medaka_polishing.sh` permite realizar el pulido de ensamblajes generados a partir de lecturas crudas o filtradas. Ambos enfoques fueron evaluados para comparar el efecto del filtrado sobre la calidad final de los ensamblajes, aunque se recomienda utilizar lecturas filtradas para obtener ensamblajes más consistentes y con menor ruido asociado a lecturas de baja calidad.

### Ensamblaje y pulido utilizando lecturas crudas

```bash
bash scripts/03_assembly/flye_assembly.sh data/seq raw
bash scripts/04_polish/medaka_polishing.sh results/assembly/flye/raw data/seq raw
```

### Ensamblaje y pulido utilizando lecturas filtradas

```bash
bash scripts/03_assembly/flye_assembly.sh data/filt filtered
bash scripts/04_polish/medaka_polishing.sh results/assembly/flye/filt data/filt filtered
```

### Parámetros utilizados

El pulido con `Medaka` fue realizado utilizando los siguientes parámetros principales:

```bash
THREADS_PER_JOB=16
MAX_JOBS=4
MODEL="r1041_e82_400bps_sup_v5.2.0"
```

`THREADS_PER_JOB` define el número de hilos utilizados por cada proceso de Medaka.

`MAX_JOBS` define el número máximo de muestras procesadas en paralelo.

`MODEL` corresponde al modelo de consenso utilizado para lecturas Oxford Nanopore R10.4.1 SUP.

### Resultados

Revisar los ensamblajes pulidos generados en:

```bash
ls results/polishing/medaka/
```


# 06. Control de calidad de ensamblajes

La calidad de los ensamblajes fue evaluada utilizando `QUAST` y `BUSCO`. `QUAST` permitió obtener métricas estructurales del ensamblaje, como tamaño total, número de contigs, N50, contenido GC y comparación contra una referencia. `BUSCO` permitió estimar la completitud génica de cada ensamblaje utilizando el linaje `pseudomonas_odb12`.

## Instalar herramientas

Los repositorios oficiales pueden consultarse en:

* [QUAST GitHub Repository](https://github.com/ablab/quast)
* [BUSCO GitLab Repository](https://gitlab.com/ezlab/busco)

Se recomienda instalar ambas herramientas dentro de un mismo ambiente Conda.

```bash
conda create -n assembly_qc_env -c bioconda -c conda-forge quast busco -y
conda activate assembly_qc_env
```

Verificar instalación:

```bash
quast --version
busco --version
```

## Ejecutar control de calidad de ensamblajes

El script `assembly_qc.sh` recibe dos argumentos:

```bash
bash scripts/06_assembly_qc/assembly_qc.sh <directorio_ensamblajes> <nombre_corrida>
```

El primer argumento corresponde al directorio donde se encuentran los archivos FASTA de los ensamblajes. El segundo argumento define el nombre de la corrida y se utiliza para organizar los resultados.

### Ensamblajes crudos

```bash
chmod +x scripts/06_assembly_qc/assembly_qc.sh
bash scripts/06_assembly_qc/assembly_qc.sh results/assembly/flye/raw raw
```

### Ensamblajes a partir de lecturas filtradas

```bash
bash scripts/06_assembly_qc/assembly_qc.sh results/assembly/flye/filtered filtered
```

### Ensamblajes pulidos con Medaka a partir de lecturas crudas

```bash
bash scripts/06_assembly_qc/assembly_qc.sh results/polishing/medaka/raw medaka_raw
```

### Ensamblajes pulidos con Medaka a partir de lecturas filtradas

```bash
bash scripts/06_assembly_qc/assembly_qc.sh results/polishing/medaka/filtered medaka_filtered
```

## Parámetros principales

En el script se utilizan los siguientes parámetros:

```bash
THREADS=32
MODE="genome"
LINEAGE="pseudomonas_odb12"
REFERENCE="data/controles/PA14.fasta"
```

`THREADS=32` define el número de hilos utilizados por `QUAST` y `BUSCO`. Puede ajustarse según los recursos disponibles del servidor.

`MODE="genome"` indica que `BUSCO` evaluará ensamblajes genómicos.

`LINEAGE="pseudomonas_odb12"` especifica el conjunto de genes conservados utilizado por `BUSCO`, correspondiente al linaje de *Pseudomonas*.

`REFERENCE="data/controles/PA14.fasta"` indica el genoma de referencia utilizado por `QUAST` para la comparación estructural de los ensamblajes.

## Resultados

Revisar los resultados generados en:

```bash
ls results/assembly_qc/quast/
ls results/assembly_qc/busco/
ls logs/assembly_qc/
```



# 07. Anotación genómica

A partir de aquí se utilizan solo los ensamblados despúes de filtrar y pulir con Medaka

## 07.1 Anotación con Prokka

La anotación genómica inicial fue realizada utilizando `Prokka`.

### Instalar Prokka

El repositorio oficial puede consultarse en:

* [Prokka GitHub Repository](https://github.com/tseemann/prokka) (v1.15.6)

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

## 07.2 Anotación con Bakta

La anotación genómica complementaria fue realizada utilizando `Bakta`, una herramienta para la anotación rápida y estandarizada de genomas bacterianos.

### Instalar Bakta

El repositorio oficial puede consultarse en:

* [Bakta GitHub Repository](https://github.com/oschwengers/bakta)

Se recomienda instalar `Bakta` dentro de un ambiente Conda independiente.

```bash
conda create -n bakta_env -c bioconda -c conda-forge bakta -y
conda activate bakta_env
```

Verificar instalación:

```bash
which bakta
bakta --version
```

### Descargar base de datos de Bakta

Antes de ejecutar la anotación, se debe descargar y configurar la base de datos de Bakta.

```bash
mkdir -p databases/bakta
bakta_db download --output databases/bakta
```

Verificar la base de datos:

```bash
ls databases/bakta/
```

### Ejecutar anotación

```bash
chmod +x scripts/03_assembly/bakta_annotation.sh
bash scripts/03_assembly/bakta_annotation.sh
```

### Resultados

Revisar las anotaciones generadas en:

```bash
ls results/bakta/
```
