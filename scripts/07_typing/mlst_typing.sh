#!/bin/bash
set -euo pipefail

# tipificación MLST del dataset final curado
INPUT_DIR="${1:-data/final_fastas}"
OUT_DIR="results/typing/mlst"
LOG_DIR="logs/typing/mlst"

mkdir -p "$OUT_DIR" "$LOG_DIR"

echo "Buscando archivos FASTA en: $INPUT_DIR"

# Listar archivos FASTA/FNA y guardarlos en un archivo
find "$INPUT_DIR" -type f \( -name "*.fasta" -o -name "*.fna" \) | sort > "${OUT_DIR}/lista_fastas.txt"

# Verificar que se encontraron archivos FASTA/FNA
if [[ ! -s "${OUT_DIR}/lista_fastas.txt" ]]; then
  echo "No se encontraron archivos FASTA/FNA en $INPUT_DIR"
  exit 1
fi

echo "Ejecutando MLST"

# Ejecutar mlst en paralelo usando xargs
# xargs -P 4 para usar 4 núcleos, ajusta según tu sistema
xargs mlst < "${OUT_DIR}/lista_fastas.txt" > "${OUT_DIR}/mlst_results.tsv" 2> "${LOG_DIR}/mlst.log"

echo "MLST terminado"
echo "Resultados: ${OUT_DIR}/mlst_results.tsv"
echo "Lista FASTA: ${OUT_DIR}/lista_fastas.txt"