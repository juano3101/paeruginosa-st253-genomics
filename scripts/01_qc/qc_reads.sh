#!/bin/bash
set -euo pipefail

# Configuración de recursos y directorios
THREADS=8 # ajusta este valor según la cantidad de núcleos disponibles en tu sistema
MEMORY=8192 # en MB, por ejemplo 8192 para 8 GB
INPUT_DIR="${1:-data/seq}" # el segundo argumento es opcional para nombrar la corrida, por defecto "raw"
RUN_NAME="${2:-raw}" # el segundo argumento es opcional para nombrar la corrida, por defecto "raw"

# Crear directorios de salida y log
OUT_DIR="results/qc/${RUN_NAME}"
NANO_DIR="${OUT_DIR}/nano_output"
FASTQC_DIR="${OUT_DIR}/fastqc_output"
MULTIQC_DIR="${OUT_DIR}/multiqc"
TMP_DIR="${OUT_DIR}/tmp_fastqc_input"
LOG_DIR="logs/qc"
LOG_FILE="${LOG_DIR}/qc_${RUN_NAME}.log"

# crear directorios necesarios
mkdir -p "$NANO_DIR" "$FASTQC_DIR" "$MULTIQC_DIR" "$TMP_DIR" "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

# verificar que el directorio de entrada existe
if [[ ! -d "$INPUT_DIR" ]]; then
  echo "ERROR: el directorio de entrada $INPUT_DIR no existe"
  exit 1
fi

# procesar cada archivo .fastq en el directorio de entrada
shopt -s nullglob
archivos=("$INPUT_DIR"/*.fastq)

if [[ ${#archivos[@]} -eq 0 ]]; then
  echo "ERROR: no se encontraron archivos .fastq en $INPUT_DIR"
  exit 1
fi

echo "Archivos encontrados: ${#archivos[@]}"

# procesar cada archivo con NanoPlot y FastQC
for archivo in "${archivos[@]}"; do
  nombre_base=$(basename "$archivo" .fastq)
  muestra="$nombre_base"
  echo "Procesando $muestra"

  mkdir -p "${NANO_DIR}/${muestra}" "${FASTQC_DIR}/${muestra}"

  # ejecutar NanoPlot
  NanoPlot --threads "$THREADS" --fastq "$archivo" -o "${NANO_DIR}/${muestra}"
  # organizar resultados de NanoPlot
  rm -f "${NANO_DIR}/${muestra}/NanoStats_post_filtering.txt"
  [[ -f "${NANO_DIR}/${muestra}/NanoStats.txt" ]] && mv "${NANO_DIR}/${muestra}/NanoStats.txt" "${NANO_DIR}/${muestra}/${muestra}_NanoStats.txt"
  [[ -f "${NANO_DIR}/${muestra}/NanoPlot-report.html" ]] && mv "${NANO_DIR}/${muestra}/NanoPlot-report.html" "${NANO_DIR}/${muestra}/${muestra}_NanoPlot-report.html"
  
  ln -sf "$(realpath "$archivo")" "${TMP_DIR}/${muestra}.fastq" # crear enlace simbólico para FastQC
  # ejecutar FastQC
  fastqc --memory "$MEMORY" "${TMP_DIR}/${muestra}.fastq" -o "${FASTQC_DIR}/${muestra}"
  html_fastqc=$(find "${FASTQC_DIR}/${muestra}" -maxdepth 1 -name "*_fastqc.html" | head -n 1 || true)
  zip_fastqc=$(find "${FASTQC_DIR}/${muestra}" -maxdepth 1 -name "*_fastqc.zip" | head -n 1 || true)
  [[ -n "$html_fastqc" && "$(basename "$html_fastqc")" != "${muestra}_fastqc.html" ]] && mv "$html_fastqc" "${FASTQC_DIR}/${muestra}/${muestra}_fastqc.html"
  [[ -n "$zip_fastqc" && "$(basename "$zip_fastqc")" != "${muestra}_fastqc.zip" ]] && mv "$zip_fastqc" "${FASTQC_DIR}/${muestra}/${muestra}_fastqc.zip"
done

# ejecutar MultiQC
multiqc "$OUT_DIR" -o "$MULTIQC_DIR" -f --fn_as_s_name
rm -rf "$TMP_DIR"

echo "QC terminado"
echo "Entrada: $INPUT_DIR"
echo "Resultados en: $OUT_DIR"
echo "Log en: $LOG_FILE"