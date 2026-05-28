#!/bin/bash
set -euo pipefail

# anotación estructural y funcional con Prokka
INPUT_DIR="${1:-data/final_fastas}"
OUTPUT_DIR="results/annotation/prokka"
LOG_DIR="logs/annotation/prokka"

PARALLEL_JOBS=4
CPUS_PER_JOB=8

# crear directorios de salida y logs si no existen
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

echo "Iniciando anotación con Prokka"
echo "Entrada: $INPUT_DIR"
echo "Salida: $OUTPUT_DIR"
echo "Procesos en paralelo: $PARALLEL_JOBS"
echo "CPUs por proceso: $CPUS_PER_JOB"

# procesar cada archivo FASTA en paralelo
find "$INPUT_DIR" -maxdepth 1 -name "*.fasta" | sort | \
xargs -I {} -P "$PARALLEL_JOBS" bash -c '
  f="$1"
  outdir="$2"
  logdir="$3"
  cpus="$4"
  
  base=$(basename "$f" .fasta) 
  prefix=$(echo "$base" | sed "s/__SRR.*//")

  echo "Procesando: $prefix"

  prokka \
    --outdir "$outdir/$prefix" \
    --prefix "$prefix" \
    --genus Pseudomonas \
    --species aeruginosa \
    --usegenus \
    --rfam \
    --cpus "$cpus" \
    "$f" \
    > "$logdir/${prefix}.log" 2>&1

  echo "Finalizado: $prefix"
' _ {} "$OUTPUT_DIR" "$LOG_DIR" "$CPUS_PER_JOB"

echo "Prokka terminó correctamente"