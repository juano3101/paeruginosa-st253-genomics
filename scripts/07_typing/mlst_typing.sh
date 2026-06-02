#!/bin/bash
set -euo pipefail

# tipificación MLST comparando ensamblajes filtrados sin pulido vs filtrados pulidos con Medaka

FLYE_FILTERED_DIR="${1:-results/assembly/flye/filtered}"
MEDAKA_FILTERED_DIR="${2:-results/polishing/medaka/filtered}"
CONTROL_DIR="${3:-data/controles}"

OUT_DIR="results/typing/mlst"
LOG_DIR="logs/typing/mlst"

mkdir -p "$OUT_DIR" "$LOG_DIR"

echo "Buscando ensamblajes Flye filtrados en: $FLYE_FILTERED_DIR"

find "$FLYE_FILTERED_DIR" -type f -name "*_flye_filtered.fasta" | \
  grep -v "Rectal_P11" | sort > "${OUT_DIR}/lista_flye_filtered.txt"

echo "Buscando ensamblajes Medaka filtrados en: $MEDAKA_FILTERED_DIR"

find "$MEDAKA_FILTERED_DIR" -type f -name "*_medaka_filtered.fasta" | \
  grep -v "Rectal_P11" | sort > "${OUT_DIR}/lista_medaka_filtered.txt"

echo "Buscando controles PA14/PAO1 en: $CONTROL_DIR"

find "$CONTROL_DIR" -type f \( \
  -name "PA14.fasta" -o \
  -name "PAO1.fasta" -o \
  -name "PA14.fna" -o \
  -name "PAO1.fna" \
\) | sort > "${OUT_DIR}/lista_controles.txt"

cat \
  "${OUT_DIR}/lista_flye_filtered.txt" \
  "${OUT_DIR}/lista_medaka_filtered.txt" \
  "${OUT_DIR}/lista_controles.txt" \
  > "${OUT_DIR}/lista_fastas.txt"

if [[ ! -s "${OUT_DIR}/lista_fastas.txt" ]]; then
  echo "No se encontraron archivos FASTA/FNA"
  exit 1
fi

echo "Ejecutando MLST"

xargs mlst < "${OUT_DIR}/lista_fastas.txt" \
  > "${OUT_DIR}/mlst_results.tsv" \
  2> "${LOG_DIR}/mlst.log"

echo "MLST terminado"
echo "Resultados: ${OUT_DIR}/mlst_results.tsv"
echo "Flye filtrado: ${OUT_DIR}/lista_flye_filtered.txt"
echo "Medaka filtrado: ${OUT_DIR}/lista_medaka_filtered.txt"
echo "Controles: ${OUT_DIR}/lista_controles.txt"
echo "Lista completa: ${OUT_DIR}/lista_fastas.txt"