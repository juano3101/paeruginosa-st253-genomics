#!/bin/bash
set -euo pipefail

# curación exploratoria del ensamblaje Rectal_P11 con purge_haplotigs

MUESTRA="Rectal_P11__SRR26135179_filt"
THREADS=16

# rutas de entrada y salida
ASSEMBLY="results/polishing/medaka/filtered/${MUESTRA}/${MUESTRA}_medaka_filtered.fasta"
READS="data/filt/${MUESTRA}.fastq"
OUTDIR="results/purge_haplotigs/${MUESTRA}"
LOG_DIR="logs/assembly_qc/purge_haplotigs"

mkdir -p "$OUTDIR" "$LOG_DIR"

if [[ ! -f "$ASSEMBLY" ]]; then
  echo "No se encontró el ensamblaje: $ASSEMBLY"
  exit 1
fi

if [[ ! -f "$READS" ]]; then
  echo "No se encontraron las lecturas: $READS"
  exit 1
fi

exec > >(tee -a "${LOG_DIR}/${MUESTRA}.log") 2>&1

cd "$OUTDIR"

echo "Procesando: $MUESTRA"

# Alineamiento de lecturas al ensamblaje
minimap2 -t "$THREADS" -ax map-ont "$OLDPWD/$ASSEMBLY" "$OLDPWD/$READS" | \
# Convertir a BAM, ordenar e indexar
samtools sort -@ "$THREADS" -o aln.bam

samtools index aln.bam

#  Ejecutar purge_haplotigs
purge_haplotigs hist -b aln.bam -g "$OLDPWD/$ASSEMBLY" # Generar histograma de cobertura
purge_haplotigs cov -i aln.bam.200.gencov -l 5 -m 20 -h 80 # Ajustar los umbrales según el histograma
purge_haplotigs purge -g "$OLDPWD/$ASSEMBLY" -c coverage_stats.csv # Purge haplotigs

cp curated.fasta "${MUESTRA}_purged.fasta"

echo "Purge terminado para $MUESTRA"
echo "Resultado final: $OUTDIR/${MUESTRA}_purged.fasta"