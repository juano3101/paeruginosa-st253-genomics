#!/bin/bash
set -euo pipefail

# ejemplo de uso
# para ensamblar las lecturas crudas
#bash scripts/03_assembly/flye_assembly.sh data/seq raw
# para ensamblar las lecturas filtradas
#bash scripts/03_assembly/flye_assembly.sh data/filt filtered

# ensamblaje de novo con Flye para lecturas Nanopore crudas o filtradas
THREADS_PER_JOB=16
MAX_JOBS=4
GENOME_SIZE="6.3m"

# argumentos: carpeta de entrada y nombre de corrida
INPUT_DIR="${1:-data/seq}"
RUN_NAME="${2:-raw}"

# directorios de salida y logs
OUT_DIR="results/assembly/flye/${RUN_NAME}"
LOG_DIR="logs/assembly/flye_${RUN_NAME}"

# crear directorios si no existen
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

echo "Iniciando ensamblaje Flye: $RUN_NAME"
echo "Entrada: $INPUT_DIR"
echo "Salida: $OUT_DIR"

# iterar sobre los archivos .fastq en la carpeta de entrada
for archivo in "$INPUT_DIR"/*.fastq; do
  [ -f "$archivo" ] || continue # verificar que el archivo existe
  esperar_slot "$MAX_JOBS" # esperar a que haya un slot disponible para ejecutar el siguiente trabajo
  (
    nombre_base=$(basename "$archivo" .fastq) # obtener el nombre base del archivo sin la extensión
    muestra="$nombre_base" # usar el nombre base como nombre de la muestra
    outdir="${OUT_DIR}/${muestra}" # definir el directorio de salida para esta muestra

    echo "Flye: $muestra"  # imprimir el nombre de la muestra que se está procesando
    rm -rf "$outdir" # eliminar el directorio de salida si ya existe para evitar conflictos
    mkdir -p "$outdir" # crear el directorio de salida para esta muestra

# ejecutar Flye con los parámetros especificados y redirigir la salida a un archivo de log
    flye \
      --nano-raw "$archivo" \
      --out-dir "$outdir" \
      --threads "$THREADS_PER_JOB" \
      --genome-size "$GENOME_SIZE" \
      > "${LOG_DIR}/${muestra}.log" 2>&1

# renombrar los archivos de salida para incluir el nombre de la muestra y la corrida
    if [[ -f "${outdir}/assembly.fasta" ]]; then
      mv "${outdir}/assembly.fasta" "${outdir}/${muestra}_flye_${RUN_NAME}.fasta"
    fi

# renombrar el archivo de información de ensamblaje si existe
    if [[ -f "${outdir}/assembly_info.txt" ]]; then
      mv "${outdir}/assembly_info.txt" "${outdir}/${muestra}_flye_${RUN_NAME}_assembly_info.txt"
    fi

# renombrar el archivo de log de Flye si existe
    if [[ -f "${outdir}/flye.log" ]]; then
      mv "${outdir}/flye.log" "${outdir}/${muestra}_flye_${RUN_NAME}.log"
    fi
  ) &
done

# esperar a que todos los trabajos en segundo plano terminen antes de continuar
wait

echo "Ensamblaje Flye terminado: $RUN_NAME"