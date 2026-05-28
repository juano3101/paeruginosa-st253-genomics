# *Pseudomonas aeruginosa* ST-253 Genomics Pipeline

Pipeline bioinformático reproducible para el análisis genómico de aislados clínicos de *Pseudomonas aeruginosa* ST-253 utilizando secuenciación Nanopore.

## Clonar repositorio

```bash
git clone https://github.com/juano3101/paeruginosa-st253-genomics.git
cd paeruginosa-st253-genomics
```

## Descargar secuencias

Los datos brutos de secuenciación correspondientes a lecturas Nanopore fueron recuperados desde el repositorio público del NCBI bajo el BioProject `PRJNA946810`, el cual investigó el origen endógeno de infecciones por *Pseudomonas aeruginosa* en pacientes hospitalizados en Ecuador. Del total de aislados disponibles en dicho proyecto, se seleccionaron exclusivamente aquellos pertenecientes al sequence type ST-253, incluyendo aislados clínicos obtenidos de diferentes tipos de muestra y correspondientes a cinco pacientes hospitalizados.

### Instalar SRA Toolkit

Para descargar las lecturas desde NCBI/SRA se requiere `sra-tools`. El repositorio oficial puede consultarse en:

* [SRA Toolkit GitHub Repository](https://github.com/ncbi/sra-tools)

Se recomienda instalarlo dentro de un ambiente Conda para mantener la reproducibilidad del pipeline.

```bash
conda create -n sra_tools -c bioconda -c conda-forge sra-tools -y
conda activate sra_tools
```

Verificar la instalación:

```bash
fasterq-dump --version
prefetch --version
```

### Ejecutar descarga

Con el ambiente `sra_tools` activado, ejecutar:

```bash
bash scripts/00_download/download_data.sh
```

Los archivos FASTQ descargados serán almacenados en:

```bash
data/raw_fastq/
```
algo anda mal