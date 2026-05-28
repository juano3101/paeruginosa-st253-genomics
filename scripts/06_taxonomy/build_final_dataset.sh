#!/bin/bash
set -euo pipefail

# crear dataset final curado de ensamblajes

INPUT_DIR="results/polishing/medaka/filtered"
OUT_DIR="data/final_fastas"

mkdir -p "$OUT_DIR"

echo "Copiando ensamblajes finales"

# copiar ensamblajes finales excepto Rectal_P11
for dir in "$INPUT_DIR"/*; do
  [ -d "$dir" ] || continue

  muestra=$(basename "$dir")

  # excluir muestra contaminada
  if [[ "$muestra" == "Rectal_P11__SRR26135179_filt" ]]; then
    echo "Excluyendo $muestra"
    continue
  fi

  fasta="${dir}/${muestra}_medaka_filtered.fasta"

  if [[ -f "$fasta" ]]; then
    cp "$fasta" "${OUT_DIR}/${muestra}.fasta"
    echo "Copiado: ${muestra}.fasta"
  else
    echo "No se encontró: $fasta"
  fi
done

echo "Dataset final disponible en: $OUT_DIR"

ls -lh "$OUT_DIR"