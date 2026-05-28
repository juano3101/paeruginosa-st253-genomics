#!/bin/bash
set -euo pipefail

# descarga de lecturas Nanopore y genomas de referencia/control

# número de hilos para fasterq-dump
THREADS=8

# directorios de salida
SEQ_DIR="data/seq"
CONTROL_DIR="data/controles"

# directorio y archivo de log
LOG_DIR="logs/download"
LOG_FILE="${LOG_DIR}/download_data.log"

# crear directorios si no existen
mkdir -p "$SEQ_DIR" "$CONTROL_DIR" "$LOG_DIR"

# guardar salida  y errores en log
exec > >(tee -a "$LOG_FILE") 2>&1

# lista de muestras con formato "ID_SRA|Nombre_Muestra"
MUESTRAS=(
  "SRR26135158|Rectal_P2"
  "SRR26135157|Tracheal_discharge_P2"
  "SRR26135209|Sputum_P3"
  "SRR26135156|Rectal_P3"
  "SRR26135187|Tracheal_discharge_P9"
  "SRR26135189|Rectal_P9"
  "SRR26135179|Rectal_P11"
  "SRR26135180|Blood_P11"
  "SRR26135174|Urine_2_P12"
  "SRR26135176|Rectal_1_P12"
  "SRR26135175|Rectal_2_P12"
  "SRR26135178|Wound_2_P12"
)

# para cada muestra, descargar las lecturas y renombrar los archivos FASTQ
for item in "${MUESTRAS[@]}"; do
  IFS='|' read -r SRR MUESTRA <<< "$item" # separar el ID SRA y el nombre de la muestra
  echo "==> Descargando $SRR ($MUESTRA)" # indicar qué muestra se está descargando
  fasterq-dump "$SRR" -e "$THREADS" # descargar lecturas desde SRA con los hilos especificados
  if [[ -f "${SRR}.fastq" ]]; then # renombrar y mover archivo FASTQ
    mv "${SRR}.fastq" \
       "${SEQ_DIR}/${MUESTRA}__${SRR}.fastq" # renombrar el archivo con el formato "Nombre_Muestra_SRA.fastq"
  else
    echo "No encontré archivos FASTQ esperados para $SRR" # mensaje de error si no se encuentran los archivos FASTQ
    exit 1
  fi
done


# descarga de genomas de referencia/control

cd "$CONTROL_DIR" # cambiar al directorio de controles

# pseudomonas aeruginosa PA14, referencia interna ST-253
wget -O PA14.fasta.gz \
https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/014/625/GCF_000014625.1_ASM1462v1/GCF_000014625.1_ASM1462v1_genomic.fna.gz

# pseudomonas aeruginosa PAO1 outgroup
wget -O PAO1.fasta.gz \
https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/765/GCF_000006765.1_ASM676v1/GCF_000006765.1_ASM676v1_genomic.fna.gz

# escherichia coli K-12 control para kraken2
wget -O Ecoli_K12.fasta.gz \
https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz

# Descomprimir genomas
gunzip -f *.gz

cd -

# resumen final
echo "Archivos FASTQ listos en $SEQ_DIR:"
ls -lh "$SEQ_DIR"

echo "Genomas de control listos en $CONTROL_DIR:"
ls -lh "$CONTROL_DIR"