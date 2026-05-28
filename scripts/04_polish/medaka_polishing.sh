#!/bin/bash
set -euo pipefail

# ejemplo de uso

# ensamblaje y pulido utilizando lecturas crudas
# bash scripts/03_assembly/flye_assembly.sh data/seq raw
# bash scripts/04_polish/medaka_polishing.sh results/assembly/flye/raw data/seq raw

# ensamblaje y pulido utilizando lecturas filtradas
# bash scripts/03_assembly/flye_assembly.sh data/filt filtered
# bash scripts/04_polish/medaka_polishing.sh results/assembly/flye/filtered data/filt filtered


# pulido de ensamblajes Flye con Medaka

THREADS_PER_JOB=16 # número de hilos por trabajo de Medaka
MAX_JOBS=4 # número máximo de trabajos en paralelo
MODEL="r1041_e82_400bps_sup_v5.2.0" # modelo de Medaka para datos R10.4.1 sup es

# argumentos: carpeta de ensamblajes, carpeta de lecturas y nombre de corrida
ASSEMBLY_DIR="${1:-results/assembly/flye/raw}"
READS_DIR="${2:-data/seq}"
RUN_NAME="${3:-raw}"

# directorios de salida
OUT_DIR="results/polishing/medaka/${RUN_NAME}"
LOG_DIR="logs/polishing/medaka_${RUN_NAME}"

mkdir -p "$OUT_DIR" "$LOG_DIR"

# función para esperar a que exista un slot libre
esperar_slot() {
  local max_jobs=$1
  while [ "$(jobs -rp | wc -l)" -ge "$max_jobs" ]; do
    sleep 1
  done
}

echo "Iniciando Medaka: $RUN_NAME"
echo "Ensamblajes: $ASSEMBLY_DIR"
echo "Lecturas: $READS_DIR"
echo "Salida: $OUT_DIR"

# recorrer ensamblajes Flye
for dir in "$ASSEMBLY_DIR"/*; do
  [ -d "$dir" ] || continue
  esperar_slot "$MAX_JOBS"

  (
    muestra=$(basename "$dir")

    ensamblaje="${dir}/${muestra}_flye_${RUN_NAME}.fasta"
    lectura="${READS_DIR}/${muestra}.fastq"
    outdir="${OUT_DIR}/${muestra}"

    # verificar existencia de ensamblaje
    if [[ ! -f "$ensamblaje" ]]; then
      echo "No se encontró ensamblaje para $muestra"
      exit 1
    fi

    # verificar existencia de lecturas
    if [[ ! -f "$lectura" ]]; then
      echo "No se encontró FASTQ para $muestra"
      exit 1
    fi

    echo "Medaka: $muestra"

    # eliminar resultados previos
    rm -rf "$outdir"
    mkdir -p "$outdir"

    # pulido con Medaka
    # conseso final se guardará como consensus.fasta dentro de outdir
    medaka_consensus \
      -i "$lectura" \
      -d "$ensamblaje" \
      -o "$outdir" \
      -t "$THREADS_PER_JOB" \
      -m "$MODEL" \
      > "${LOG_DIR}/${muestra}.log" 2>&1

    # renombrar el consensus.fasta generado con el nombre de muestra y corrida
    if [[ -f "${outdir}/consensus.fasta" ]]; then
      mv -f "${outdir}/consensus.fasta" \
            "${outdir}/${muestra}_medaka_${RUN_NAME}.fasta"
    else
      echo "No se generó consensus.fasta para $muestra"
      exit 1
    fi

  ) &
done

wait

echo "Pulido Medaka terminado: $RUN_NAME"