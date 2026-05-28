# *Pseudomonas aeruginosa* ST-253 Genomics Pipeline

Pipeline bioinformático reproducible para el análisis genómico de aislados clínicos de *Pseudomonas aeruginosa* ST-253 utilizando secuenciación Nanopore.

## Clonar repositorio

```bash
git clone https://github.com/juano3101/paeruginosa-st253-genomics.git
cd paeruginosa-st253-genomics
```

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

* [FastQC GitHub Repository](https://github.com/s-andrews/fastqc)
* [NanoPlot GitHub Repository](https://github.com/wdecoster/nanoplot)
* [MultiQC GitHub Repository](https://github.com/multiqc/multiqc)

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

* [Filtlong GitHub Repository](https://github.com/rrwick/Filtlong?utm_source=chatgpt.com)

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

````markdown id="6qbz2r"
## Resultados

Revisar las lecturas filtradas generadas en:

```bash
ls results/filtered/
````


# 03. Control de calidad de lecturas filtradas
# 04. Ensamblaje
# 05. Pulido
# 06. Control de calidad de ensamblajes