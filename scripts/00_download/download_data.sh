#!/bin/bash
set -euo pipefail

# ==========================================
# Descarga de lecturas Nanopore y genomas
# de referencia/control para el análisis
# de Pseudomonas aeruginosa ST-253
# ==========================================

# Número de hilos para fasterq-dump
THREADS=8

# Directorios de salida
SEQ_DIR="data/seq"
CONTROL_DIR="data/controles"

# Crear directorios si no existen
mkdir -p "$SEQ_DIR" "$CONTROL_DIR"

# ==========================================
# Descarga de lecturas desde NCBI SRA
# ==========================================

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

for item in "${MUESTRAS[@]}"; do

  # Separar ID SRA y nombre de muestra
  IFS='|' read -r SRR MUESTRA <<< "$item"

  echo "==> Descargando $SRR ($MUESTRA)"

  # Descarga de lecturas Nanopore
  fasterq-dump "$SRR" -e "$THREADS"

  # Renombrar archivos FASTQ
  if [[ -f "${SRR}.fastq" ]]; then

    mv "${SRR}.fastq" \
       "${SEQ_DIR}/${MUESTRA}__${SRR}.fastq"

  elif [[ -f "${SRR}_1.fastq" && -f "${SRR}_2.fastq" ]]; then

    mv "${SRR}_1.fastq" \
       "${SEQ_DIR}/${MUESTRA}__${SRR}_1.fastq"

    mv "${SRR}_2.fastq" \
       "${SEQ_DIR}/${MUESTRA}__${SRR}_2.fastq"

  else
    echo "No encontré archivos FASTQ esperados para $SRR"
    exit 1
  fi

done

# ==========================================
# Descarga de genomas de referencia/control
# ==========================================

cd "$CONTROL_DIR"

# Pseudomonas aeruginosa PA14
wget -O PA14.fasta.gz \
https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/014/625/GCF_000014625.1_ASM1462v1/GCF_000014625.1_ASM1462v1_genomic.fna.gz

# Pseudomonas aeruginosa PAO1
wget -O PAO1.fasta.gz \
https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/765/GCF_000006765.1_ASM676v1/GCF_000006765.1_ASM676v1_genomic.fna.gz

# Escherichia coli K-12
wget -O Ecoli_K12.fasta.gz \
https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz

# Descomprimir genomas
gunzip -f *.gz

cd -

# ==========================================
# Resumen final
# ==========================================

echo "Archivos FASTQ listos en $SEQ_DIR:"
ls -lh "$SEQ_DIR"

echo "Genomas de control listos en $CONTROL_DIR:"
ls -lh "$CONTROL_DIR"