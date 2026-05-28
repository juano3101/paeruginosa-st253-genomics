#!/bin/bash
set -euo pipefail

# filtrado de lecturas Nanopore con Filtlong
MAX_JOBS=12
MIN_LENGTH=1000
MIN_MEAN_Q=10

# parámetros de entrada y salida
INPUT_DIR="${1:-data/seq}"
OUT_DIR="${2:-data/filt}"

# crear directorios de salida y logs
LOG_DIR="logs/qc/filtlong"
mkdir -p "$OUT_DIR" "$LOG_DIR"

# función para esperar a que haya un slot disponible para ejecutar un nuevo trabajo
# espera a que el número de trabajos en segundo plano sea menor que el máximo permitido
# sirve para evitar sobrecargar el sistema con demasiados procesos en paralelo
esperar_slot() {
  local max_jobs=$1
  while [ "$(jobs -rp | wc -l)" -ge "$max_jobs" ]; do
    sleep 1
  done
}

echo "Iniciando filtrado con Filtlong"
echo "Entrada: $INPUT_DIR"
echo "Salida: $OUT_DIR"

# iterar sobre los archivos fastq en el directorio de entrada y filtrar cada uno en paralelo
for archivo in "$INPUT_DIR"/*.fastq; do
  [ -f "$archivo" ] || continue
  esperar_slot "$MAX_JOBS"

  (
    nombre_base=$(basename "$archivo" .fastq) # extraer el nombre base del archivo sin extensión
    muestra="${nombre_base}_filt" # agregar sufijo para indicar que es filtrado

    echo "Filtrando $muestra"
# ejecutar Filtlong con los parámetros especificados y redirigir la salida a los archivos correspondientes
    filtlong \
      --min_length "$MIN_LENGTH" \
      --min_mean_q "$MIN_MEAN_Q" \
      "$archivo" \
      > "${OUT_DIR}/${muestra}.fastq" \
      2> "${LOG_DIR}/${muestra}.log"
  ) &
done

wait

echo "Filtrado terminado"
echo "Lecturas filtradas en: $OUT_DIR"