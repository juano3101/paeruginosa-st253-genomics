#!/bin/bash
set -euo pipefail

# detección de genes y mutaciones AMR usando AMRFinderPlus a partir de anotaciones Bakta

INPUT_DIR="${1:-results/annotation/bakta}"
OUTPUT_DIR="results/annotation/amrfinder"
LOG_DIR="logs/annotation/amrfinder"

PARALLEL_JOBS=4 # número de procesos paralelos (ajustar según recursos disponibles)
THREADS=8 # número de threads por proceso (ajustar según recursos disponibles)
ORGANISM="Pseudomonas_aeruginosa" # organismo específico para AMRFinderPlus (ajustar según especie)
ANNOTATION_FORMAT="bakta" # formato de anotación de entrada (ajustar si se usa otro formato)

mkdir -p "$OUTPUT_DIR" "$LOG_DIR" 

echo "Iniciando AMRFinderPlus"
echo "Entrada Bakta: $INPUT_DIR"
echo "Salida: $OUTPUT_DIR"
echo "Procesos paralelos: $PARALLEL_JOBS"
echo "Threads por proceso: $THREADS"
echo "Organismo: $ORGANISM"

# buscar archivos .faa y procesar con AMRFinderPlus en paralelo
find "$INPUT_DIR" -name "*.faa" | sort | \
xargs -I {} -P "$PARALLEL_JOBS" bash -c '
  faa="$1"
  outdir="$2"
  logdir="$3"
  threads="$4"
  organism="$5"
  annotation_format="$6"

  sample=$(basename "$faa" .faa)
  folder=$(dirname "$faa")

  fna="$folder/${sample}.fna"
  gff="$folder/${sample}.gff3"

  if [[ ! -f "$fna" || ! -f "$gff" ]]; then
    echo "ERROR: faltan archivos .fna o .gff3 para $sample"
    exit 1
  fi

  mkdir -p "$outdir/$sample"

  echo "Procesando: $sample"

  amrfinder \
    --threads "$threads" \
    -O "$organism" \
    --plus \
    -p "$faa" \
    -n "$fna" \
    -g "$gff" \
    --annotation_format "$annotation_format" \
    -o "$outdir/$sample/${sample}.tsv" \
    > "$logdir/${sample}.log" 2>&1

  echo "Finalizado: $sample"
' _ {} "$OUTPUT_DIR" "$LOG_DIR" "$THREADS" "$ORGANISM" "$ANNOTATION_FORMAT"

echo "Todos los análisis de AMRFinderPlus terminaron"