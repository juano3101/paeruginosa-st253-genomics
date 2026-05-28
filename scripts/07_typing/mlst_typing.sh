#!/bin/bash
set -euo pipefail

# tipificación MLST del dataset final curado y controles 

INPUT_DIR="${1:-data/final_fastas}"
CONTROL_DIR="${2:-data/controles}"

#  crear directorios de salida y logs
OUT_DIR="results/typing/mlst"
LOG_DIR="logs/typing/mlst"

mkdir -p "$OUT_DIR" "$LOG_DIR"

# buscar archivos FASTA/FNA en muestras y controles
echo "Buscando FASTA de muestras en: $INPUT_DIR"
find "$INPUT_DIR" -type f \( -name "*.fasta" -o -name "*.fna" \) | sort > "${OUT_DIR}/lista_muestras.txt"

# buscar controles específicos PA14/PAO1
echo "Buscando controles PA14/PAO1 en: $CONTROL_DIR"
find "$CONTROL_DIR" -type f \( -name "PA14.fasta" -o -name "PAO1.fasta" -o -name "PA14.fna" -o -name "PAO1.fna" \) | sort > "${OUT_DIR}/lista_controles.txt"

cat "${OUT_DIR}/lista_muestras.txt" "${OUT_DIR}/lista_controles.txt" > "${OUT_DIR}/lista_fastas.txt"

if [[ ! -s "${OUT_DIR}/lista_fastas.txt" ]]; then
  echo "No se encontraron archivos FASTA/FNA"
  exit 1
fi

# ejecutar MLST en paralelo usando xargs
echo "Ejecutando MLST"
xargs mlst < "${OUT_DIR}/lista_fastas.txt" > "${OUT_DIR}/mlst_results.tsv" 2> "${LOG_DIR}/mlst.log"

echo "MLST terminado"
echo "Resultados: ${OUT_DIR}/mlst_results.tsv"
echo "Lista completa: ${OUT_DIR}/lista_fastas.txt"
echo "Muestras: ${OUT_DIR}/lista_muestras.txt"
echo "Controles: ${OUT_DIR}/lista_controles.txt"