#!/bin/bash
set -euo pipefail

# anotación estructural y funcional con Bakta

INPUT_DIR="${1:-data/final_fastas}"
DB="${2:-databases/bakta/db}"

OUTPUT_DIR="results/annotation/bakta"
LOG_DIR="logs/annotation/bakta"

PARALLEL_JOBS=4 # número de procesos paralelos
THREADS=8 # número de threads por proceso (ajustar según la capacidad de tu máquina)

mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

echo "Iniciando Bakta"
echo "Entrada: $INPUT_DIR"
echo "Base de datos: $DB"
echo "Salida: $OUTPUT_DIR"
echo "Procesos paralelos: $PARALLEL_JOBS"
echo "Threads por proceso: $THREADS"

# verificar base de datos
if [[ ! -d "$DB" ]]; then
  echo "ERROR: no existe la base de datos Bakta en: $DB"
  echo "Descárgala con:"
  echo "bakta_db download --output databases/bakta --type full"
  exit 1
fi

# verificar entrada
if [[ ! -d "$INPUT_DIR" ]]; then
  echo "ERROR: no existe la carpeta de entrada: $INPUT_DIR"
  exit 1
fi

# procesar cada archivo fasta en paralelo con xargs
find "$INPUT_DIR" -maxdepth 1 -name "*.fasta" | sort | \
xargs -I {} -P "$PARALLEL_JOBS" bash -c '
  f="$1"
  outdir="$2"
  logdir="$3"
  threads="$4"
  db="$5"

  base=$(basename "$f" .fasta)
  prefix=$(echo "$base" | sed "s/__SRR.*//")

  echo "Procesando: $prefix"

  bakta \
    --db "$db" \
    --threads "$threads" \
    --skip-sorf \
    --output "$outdir/$prefix" \
    --prefix "$prefix" \
    "$f" \
    > "$logdir/${prefix}.log" 2>&1

  echo "Finalizado: $prefix"
' _ {} "$OUTPUT_DIR" "$LOG_DIR" "$THREADS" "$DB"

echo "Bakta terminó correctamente"