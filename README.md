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

# 02. Filtrado de lecturas

El filtrado de lecturas Nanopore se realizó utilizando `Filtlong`, con el objetivo de eliminar lecturas cortas y de baja calidad antes del ensamblaje genómico. Se aplicaron filtros mínimos de longitud y calidad promedio Phred para mejorar la calidad global de las lecturas utilizadas en los análisis posteriores.

## Instalar Filtlong

El repositorio oficial de `Filtlong` puede consultarse en:

* [Filtlong GitHub Repository](https://github.com/rrwick/filtlong) (v0.3.1)

Instalar la herramienta dentro de un ambiente independiente.

```bash id="5m9t3v"
conda create -n filtlong_env -c bioconda -c conda-forge filtlong -y
conda activate filtlong_env
```
Verificar instalación:

```bash id="8hgc6m"
which filtlong
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

## 02.1. Control de calidad de lecturas filtradas

Después del filtrado, se realizó nuevamente el control de calidad de las lecturas Nanopore para evaluar los cambios en la calidad promedio, longitud de lectura, contenido GC y distribución de las secuencias retenidas.

Este paso utiliza el mismo ambiente Conda creado para el control de calidad de lecturas crudas.

```bash
conda activate qc_env
```

### Ejecutar control de calidad

```bash
bash scripts/01_qc/qc_reads.sh data/filt filt
```

# 03. Ensamblaje con Flye

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

# 04. Pulido con Medaka

Después del ensamblaje inicial, los genomas fueron pulidos utilizando `Medaka` para corregir errores asociados a la secuenciación Nanopore y mejorar la precisión de consenso de los ensamblajes.

## Instalar Medaka

El repositorio oficial puede consultarse en:

* [Medaka GitHub Repository](https://github.com/nanoporetech/medaka) (v2.2.2)

En este proyecto se utilizó `Medaka v2.2.2` instalado mediante `pip` dentro de un ambiente Conda independiente. Esta estrategia permitió evitar problemas de compatibilidad con `Ubuntu 20.04` observados al instalar directamente desde Conda.

```bash
conda create -n medaka_env python=3.11 -y
conda activate medaka_env
conda install -c bioconda minimap2 samtools htslib -y
conda install -c bioconda bcftools -y
pip install --upgrade pip
pip install pyabpoa
pip install medaka
```

Verificar instalación:

```bash
which medaka_consensus
which minimap2
which samtools
which bcftools
which bgzip
which tabix
```

## Ejecutar pulido

### Prueba de funcionamiento

Debido al número de dependencias requeridas por Medaka (`samtools`, `minimap2`, `bcftools`, `bgzip`, `tabix`, `pyabpoa` y bibliotecas de Python), se recomienda ejecutar inicialmente el pulido sobre una única muestra para verificar que la instalación y todas las dependencias funcionan correctamente antes de procesar el conjunto completo de datos.

El siguiente comando permite ejecutar Medaka sobre una muestra individual:

```bash
medaka_consensus \
-i data/seq/Blood_P11__SRR26135180.fastq \
-d results/assembly/flye/raw/Blood_P11__SRR26135180/Blood_P11__SRR26135180_flye_raw.fasta \
-o prueba_medaka \
-t 16 \
-m r1041_e82_400bps_sup_v5.2.0
```

Si la ejecución finaliza correctamente, Medaka generará múltiples archivos dentro del directorio de salida especificado (`prueba_medaka`), incluyendo el ensamblaje pulido final. Una vez validado el funcionamiento de la herramienta, se recomienda ejecutar el script completo para procesar todas las muestras del estudio.

### Ensamblaje y pulido utilizando lecturas crudas

```bash
bash scripts/04_polish/medaka_polishing.sh results/assembly/flye/raw data/seq raw
```

### Ensamblaje y pulido utilizando lecturas filtradas

```bash
bash scripts/04_polish/medaka_polishing.sh results/assembly/flye/filtered data/filt filtered
```
## Parámetros utilizados

El pulido con `Medaka` fue realizado utilizando los siguientes parámetros principales:

```bash
MODEL="r1041_e82_400bps_sup_v5.2.0"
```
`MODEL` corresponde al modelo de consenso utilizado para lecturas Oxford Nanopore R10.4.1 SUP.


# 05. Control de calidad de ensamblajes

La calidad de los ensamblajes fue evaluada utilizando `QUAST` y `BUSCO`. `QUAST` permitió obtener métricas estructurales del ensamblaje, como tamaño total, número de contigs, N50, contenido GC y comparación contra una referencia. `BUSCO` permitió estimar la completitud génica de cada ensamblaje utilizando el linaje `pseudomonas_odb12`.

## Instalar herramientas

Los repositorios oficiales pueden consultarse en:

* [QUAST GitHub Repository](https://github.com/ablab/quast) (v5.3.0)
* [BUSCO GitLab Repository](https://gitlab.com/ezlab/busco) (v6.0.0)

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
bash scripts/05_assembly_qc/assembly_qc.sh <directorio_ensamblajes> <nombre_corrida>
```

El primer argumento corresponde al directorio donde se encuentran los archivos FASTA de los ensamblajes. El segundo argumento define el nombre de la corrida y se utiliza para organizar los resultados.

### Ensamblajes crudos

```bash
chmod +x scripts/06_assembly_qc/assembly_qc.sh
bash scripts/05_assembly_qc/assembly_qc.sh results/assembly/flye/raw raw
```

### Ensamblajes a partir de lecturas filtradas

```bash
bash scripts/05_assembly_qc/assembly_qc.sh results/assembly/flye/filtered filtered
```

### Ensamblajes pulidos con Medaka a partir de lecturas crudas

```bash
bash scripts/05_assembly_qc/assembly_qc.sh results/polishing/medaka/raw medaka_raw
```

### Ensamblajes pulidos con Medaka a partir de lecturas filtradas

```bash
bash scripts/05_assembly_qc/assembly_qc.sh results/polishing/medaka/filtered medaka_filtered
```

## Parámetros principales

En el script se utilizan los siguientes parámetros:

```bash
MODE="genome"
LINEAGE="pseudomonas_odb12"
REFERENCE="data/controles/PA14.fasta"
```

`MODE="genome"` indica que `BUSCO` evaluará ensamblajes genómicos.

`LINEAGE="pseudomonas_odb12"` especifica el conjunto de genes conservados utilizado por `BUSCO`, correspondiente al linaje de *Pseudomonas*.

`REFERENCE="data/controles/PA14.fasta"` indica el genoma de referencia utilizado por `QUAST` para la comparación estructural de los ensamblajes.

# 06. Taxonomía

A partir de aquí se utilizan solo los ensamblados despúes de filtrar y pulir con Medaka

La clasificación taxonómica de ensamblajes y controles se realizó utilizando `Kraken2`, con el objetivo de verificar la identidad taxonómica de los ensamblajes generados y detectar posibles eventos de contaminación o mezclas taxonómicas.

## Instalar Kraken2

El repositorio oficial puede consultarse en:

* [Kraken2 GitHub Repository](https://github.com/DerrickWood/kraken2) (v2.17.1)

Se recomienda instalar `Kraken2` dentro de un ambiente Conda independiente.

```bash id="q7v4ic"
conda create -n kraken2_env -c bioconda -c conda-forge kraken2 -y
conda activate kraken2_env
```

Verificar instalación:

```bash id="4fqzh3"
kraken2 --version
```

## Descargar base de datos Kraken2

En este pipeline se utilizó la base de datos precompilada estándar de 8 GB (`standard_08gb`).

```bash id="11icrc"
mkdir -p databases/kraken2

cd databases/kraken2

wget https://genome-idx.s3.amazonaws.com/kraken/k2_standard_08gb_20240904.tar.gz

mkdir -p standard_08gb

tar -xzvf k2_standard_08gb_20240904.tar.gz -C standard_08gb/

rm k2_standard_08gb_20240904.tar.gz
```

Verificar la base descargada:

```bash id="8c4dsd"
ls databases/kraken2/standard_08gb/
```

## Ejecutar clasificación taxonómica

El script `kraken2_taxonomy.sh` permite clasificar ensamblajes pulidos y controles de referencia.

```bash id="ly3k1y"
chmod +x scripts/06_taxonomy/kraken2_taxonomy.sh
bash scripts/06_taxonomy/kraken2_taxonomy.sh
```

Por defecto, el script utiliza:

```bash id="z3gxdp"
results/polishing/medaka/filtered
```

como directorio de ensamblajes y:

```bash id="f14ol7"
data/controles
```

Durante la clasificación se emplearon además los siguientes parámetros de Kraken2:

```bash id="78a9y5"
--use-names
--report
--output
```

`--use-names` permite mostrar nombres taxonómicos en lugar de únicamente identificadores numéricos.

`--report` genera un resumen tabular de abundancia taxonómica.

`--output` genera el detalle completo de clasificación para cada secuencia analizada.


## 06.1. Preparación del dataset final

Con el objetivo de garantizar que los análisis posteriores se realizaran únicamente sobre ensamblajes de alta calidad, se generó un conjunto final de genomas a partir de los ensamblajes pulidos con Medaka obtenidos desde lecturas filtradas.

Durante esta etapa se recopilaron los ensamblajes finales de todas las muestras y se consolidaron en un único directorio para facilitar los análisis posteriores de tipificación molecular, filogenómica y caracterización del resistoma. Adicionalmente, se excluyó el aislado `Rectal_P11__SRR26135179`, debido a que la clasificación taxonómica mediante Kraken2 evidenció contaminación polimicrobiana, con una proporción importante de secuencias asignadas a otros taxones distintos de *Pseudomonas aeruginosa*.

### Ejecutar preparación del dataset final

```bash
chmod +x scripts/06_taxonomy/final_dataset.sh
bash scripts/06_taxonomy/final_dataset.sh
```

### Criterios de inclusión

Se incluyeron únicamente ensamblajes que cumplieron los siguientes criterios:

* Ensamblajes obtenidos a partir de lecturas filtradas.
* Ensamblajes pulidos mediante Medaka.
* Confirmación taxonómica compatible con *Pseudomonas aeruginosa*.
* Ausencia de evidencia significativa de contaminación taxonómica.

### Criterios de exclusión

Se excluyó el ensamblaje correspondiente a:

```text
Rectal_P11__SRR26135179
```

debido a la detección de contaminación polimicrobiana durante la evaluación taxonómica.

### Resultados

Los ensamblajes finales utilizados en los análisis posteriores se almacenan en:

```bash
data/final_fastas/
```

Para verificar los genomas incluidos en el dataset final:

```bash
ls data/final_fastas/
```

# 07. Tipificación MLST

La tipificación multilocus de secuencias (MLST, Multi-Locus Sequence Typing) se realizó con el objetivo de confirmar el sequence type (ST) de cada aislado y verificar su pertenencia al linaje ST-253 previamente reportado para los genomas analizados.

## Instalar MLST

El repositorio oficial puede consultarse en:

* [MLST GitHub Repository](https://github.com/tseemann/mlst)

Se recomienda instalar la herramienta dentro de un ambiente Conda independiente.

```bash
conda create -n mlst_env -c bioconda -c conda-forge mlst -y
conda activate mlst_env
```

Verificar instalación:

```bash
mlst --version
```

## Ejecutar tipificación MLST

El script `mlst_typing.sh` realiza la identificación automática del sequence type para todos los ensamblajes incluidos en el conjunto final de datos.

```bash
chmod +x scripts/07_mlst/mlst_typing.sh
bash scripts/07_mlst/mlst_typing.sh
```

## Parámetros utilizados

La tipificación se realizó utilizando los esquemas MLST disponibles en PubMLST incluidos en la base de datos de la herramienta.

## Resultados

Los resultados generados se almacenan en:

```bash
results/mlst/
```
# 08. Filogenia


# 09. Anotación genómica

## 09.1. Con Prokka



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

## 09.2. Anotación con Bakta

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