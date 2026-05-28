#!/bin/bash
set -euo pipefail

# ejeplo de uso:
#bash scripts/06_assembly_qc/assembly_qc.sh results/assembly/flye/raw raw
#bash scripts/06_assembly_qc/assembly_qc.sh results/assembly/flye/filtered filtered
#bash scripts/06_assembly_qc/assembly_qc.sh results/polishing/medaka/raw medaka_raw
#bash scripts/06_assembly_qc/assembly_qc.sh results/polishing/medaka/filtered medaka_filtered

# evaluación de calidad de ensamblajes con QUAST y BUSCO

THREADS=32 # ajustar según recursos disponibles
MODE="genome" # BUSCO mode
LINEAGE="pseudomonas_odb12" # BUSCO lineage dataset, ajustar según el organismo de interés

# argumentos: carpeta de FASTA y nombre de corrida
INPUT_DIR="${1:-results/polishing/medaka/filtered}"
RUN_NAME="${2:-medaka_filtered}"

# crear carpetas de salida
QUAST_OUT="results/assembly_qc/quast/${RUN_NAME}"
BUSCO_OUT="results/assembly_qc/busco/${RUN_NAME}"
LOG_DIR="logs/assembly_qc/${RUN_NAME}"

mkdir -p "$QUAST_OUT" "$BUSCO_OUT" "$LOG_DIR"

echo "Iniciando QUAST: $RUN_NAME"
FASTAS=( "$INPUT_DIR"/*/*.fasta ) # asume que los FASTA están en subcarpetas dentro de INPUT_DIR

# ejecutar QUAST
# solo me devuelve el reporte general, no el detalle por muestra
quast "${FASTAS[@]}" \
  -o "$QUAST_OUT" \
  --threads "$THREADS" \
  > "${LOG_DIR}/quast_${RUN_NAME}.log" 2>&1

echo "QUAST terminado: $RUN_NAME"

echo "Iniciando BUSCO: $RUN_NAME"

# ejecutar BUSCO para cada muestra individualmente, guardando logs separados
# BUSCO devulve un reporte por muestra, no un resumen general
for fasta in "${FASTAS[@]}"; do
  [ -f "$fasta" ] || continue
  muestra=$(basename "$fasta" .fasta)
  echo "BUSCO: $muestra"
# ejecutar BUSCO para cada muestra
  busco \
    -i "$fasta" \
    -o "$muestra" \
    -l "$LINEAGE" \
    -m "$MODE" \
    -c "$THREADS" \
    --out_path "$BUSCO_OUT" \
    > "${LOG_DIR}/${muestra}_busco_${RUN_NAME}.log" 2>&1
done

echo "BUSCO terminado: $RUN_NAME"