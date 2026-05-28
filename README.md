# *Pseudomonas aeruginosa* ST-253 Genomics Pipeline

Pipeline bioinformático reproducible para el análisis genómico de aislados clínicos de *Pseudomonas aeruginosa* ST-253 utilizando secuenciación Nanopore.

## Clonar repositorio

```bash
git clone https://github.com/juano3101/paeruginosa-st253-genomics.git
cd paeruginosa-st253-genomics
```

## Estructura del proyecto

```bash
scripts/
├── 00_download
├── 01_qc
├── 02_filt
├── 03_assembly
├── 04_polish
├── 05_assembly_qc
```

## Requerimientos

* Linux Ubuntu 20.04+
* Conda 25.11.1
* R
* Python 3
* Snippy
* Flye
* Medaka
* Kraken2
* QUAST
* BUSCO
* IQ-TREE

## Crear ambientes Conda

```bash
conda env create -f environment/snippy_clean.yml
conda activate snippy_clean
```

## Flujo general del pipeline

1. Descarga de datos
2. Control de calidad
3. Filtrado de lecturas
4. Ensamblaje genómico
5. Pulido de ensamblajes
6. Evaluación de calidad
7. Filogenómica
8. Resistoma

```
```
