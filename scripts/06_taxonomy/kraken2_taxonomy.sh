#!/bin/bash
set -euo pipefail



# clasificación taxonómica de controles y ensamblajes con Kraken2

THREADS=8

# rutas configurables
DB_PATH="${KRAKEN2_DB:-databases/kraken2/standard_08gb}"
MUESTRAS_DIR="${1:-results/polishing/medaka/filtered}"
CONTROLES_DIR="${2:-data/controles}"
RUN_NAME="${3:-medaka_filtered}"

# directorios de salida
OUT_DIR="results/taxonomy/kraken2/${RUN_NAME}"
MUESTRAS_OUT="${OUT_DIR}/muestras"
CONTROLES_OUT="${OUT_DIR}/controles"
LOG_DIR="logs/taxonomy/kraken2"

mkdir -p "$MUESTRAS_OUT" "$CONTROLES_OUT" "$LOG_DIR"

exec > >(tee -a "${LOG_DIR}/kraken2_${RUN_NAME}.log") 2>&1

echo "Iniciando análisis con Kraken2"
echo "Base de datos: $DB_PATH"
echo "Muestras: $MUESTRAS_DIR"
echo "Controles: $CONTROLES_DIR"
echo "Salida: $OUT_DIR"

if [[ ! -f "$DB_PATH/hash.k2d" ]]; then
  echo "ERROR: No se encontró la base Kraken2 en: $DB_PATH"
  exit 1
fi

echo "Procesando controles"

for fasta in "$CONTROLES_DIR"/*.fasta; do
  [ -f "$fasta" ] || continue
  muestra=$(basename "$fasta" .fasta)
  echo "Kraken2 control: $muestra"

  kraken2 \
    --db "$DB_PATH" \
    --threads "$THREADS" \
    --use-names \
    --report "${CONTROLES_OUT}/${muestra}_report.txt" \
    --output "${CONTROLES_OUT}/${muestra}_output.txt" \
    "$fasta"
done

echo "Procesando muestras"

for fasta in "$MUESTRAS_DIR"/*/*.fasta; do
  [ -f "$fasta" ] || continue
  muestra=$(basename "$fasta" .fasta)
  echo "Kraken2 muestra: $muestra"

  kraken2 \
    --db "$DB_PATH" \
    --threads "$THREADS" \
    --use-names \
    --report "${MUESTRAS_OUT}/${muestra}_report.txt" \
    --output "${MUESTRAS_OUT}/${muestra}_output.txt" \
    "$fasta"
done

echo "Kraken2 terminado"
echo "Resultados en: $OUT_DIR"