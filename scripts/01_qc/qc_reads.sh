#!/bin/bash
set -euo pipefail

# control de calidad de lecturas Nanopore crudas o filtradas
THREADS=8
MEMORY=8192

# carpeta de entrada y nombre de corrida
INPUT_DIR="${1:-data/seq}"
RUN_NAME="${2:-raw}"

# ejemplo de uso:
# bash scripts/01_qc/qc_reads.sh data/seq raw
# bash scripts/01_qc/qc_reads.sh results/filtered filtered

# directorios de salida
OUT_DIR="results/qc/${RUN_NAME}"
NANO_DIR="${OUT_DIR}/nano_output"
FASTQC_DIR="${OUT_DIR}/fastqc_output"
MULTIQC_DIR="${OUT_DIR}/multiqc"
TMP_DIR="${OUT_DIR}/tmp_fastqc_input"

# archivo de log
LOG_DIR="logs/qc"
LOG_FILE="${LOG_DIR}/qc_${RUN_NAME}.log"

# crear directorios si no existen y guardar salida en log
mkdir -p "$NANO_DIR" "$FASTQC_DIR" "$MULTIQC_DIR" "$TMP_DIR" "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

# procesar archivos fastqc de la carpeta indicada
for archivo in "$INPUT_DIR"/*.fastq; do
  nombre_base=$(basename "$archivo" .fastq)
  muestra="$nombre_base"
  echo "Procesando $muestra"
  mkdir -p "${NANO_DIR}/${muestra}" "${FASTQC_DIR}/${muestra}"

  # nanoplot
  NanoPlot \
      --threads "$THREADS" \
      --fastq "$archivo" \
      -o "${NANO_DIR}/${muestra}"

  # eliminar archivo residual si existe
  rm -f "${NANO_DIR}/${muestra}/NanoStats_post_filtering.txt"

  # renombrar salidas principales de NanoPlot
  if [[ -f "${NANO_DIR}/${muestra}/NanoStats.txt" ]]; then
    mv "${NANO_DIR}/${muestra}/NanoStats.txt" "${NANO_DIR}/${muestra}/${muestra}_NanoStats.txt"
  fi

  if [[ -f "${NANO_DIR}/${muestra}/NanoPlot-report.html" ]]; then
    mv "${NANO_DIR}/${muestra}/NanoPlot-report.html" "${NANO_DIR}/${muestra}/${muestra}_NanoPlot-report.html"
  fi

  # fastqc
  ln -sf "$(realpath "$archivo")" "${TMP_DIR}/${muestra}.fastq" # crear enlace simbólico para FastQC
  
  fastqc \
      --memory "$MEMORY" \
      "${TMP_DIR}/${muestra}.fastq" \
      -o "${FASTQC_DIR}/${muestra}"

  # renombrar salidas de FastQC
  if ls "${FASTQC_DIR}/${muestra}/"*"_fastqc.html" 1> /dev/null 2>&1; then
    mv "${FASTQC_DIR}/${muestra}/"*"_fastqc.html" "${FASTQC_DIR}/${muestra}/${muestra}_fastqc.html"
  fi

  if ls "${FASTQC_DIR}/${muestra}/"*"_fastqc.zip" 1> /dev/null 2>&1; then
    mv "${FASTQC_DIR}/${muestra}/"*"_fastqc.zip" "${FASTQC_DIR}/${muestra}/${muestra}_fastqc.zip"
  fi
done

# multiqc
multiqc "$OUT_DIR" -o "$MULTIQC_DIR" -f --fn_as_s_name

# eliminar archivos temporales
rm -rf "$TMP_DIR"

echo "QC terminado"
echo "Entrada: $INPUT_DIR"
echo "Resultados en: $OUT_DIR"
echo "Log en: $LOG_FILE"