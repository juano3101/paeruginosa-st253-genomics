#!/bin/bash
set -euo pipefail

# análisis filogenómico basado en SNPs del core genome
# Snippy -> snippy-core -> SNP-sites -> IQ-TREE -> snp-dists

THREADS=4 # ajustar según recursos disponibles
MODEL="GTR+ASC" # modelo de sustitución para SNPs con corrección por sitios constantes
BOOTSTRAP=1000 # número de réplicas para bootstrap ultrarrápido
ALRT=1000 # número de réplicas para test de soporte SH-aLRT

# entradas
INPUT_DIR="${1:-data/final_fastas}"
REF="${2:-data/controles/PA14.fasta}"
OUTGROUP="${3:-data/controles/PAO1.fasta}"

# salidas
OUT_DIR="results/phylogeny/snippy_iqtree"
LOG_DIR="logs/phylogeny"

mkdir -p "$OUT_DIR" "$LOG_DIR"
exec > >(tee -a "${LOG_DIR}/snippy_iqtree.log") 2>&1

# verificar programas
command -v snippy >/dev/null || { echo "ERROR: snippy no está activo"; exit 1; }
command -v snippy-core >/dev/null || { echo "ERROR: snippy-core no está activo"; exit 1; }
command -v snp-sites >/dev/null || { echo "ERROR: snp-sites no está activo"; exit 1; }
command -v snp-dists >/dev/null || { echo "ERROR: snp-dists no está activo"; exit 1; }
command -v iqtree3 >/dev/null || { echo "ERROR: iqtree3 no está activo"; exit 1; }

# verificar entradas
[[ -d "$INPUT_DIR" ]] || { echo "ERROR: no existe la carpeta de FASTA: $INPUT_DIR"; exit 1; }
[[ -f "$REF" ]] || { echo "ERROR: no existe la referencia: $REF"; exit 1; }
[[ -f "$OUTGROUP" ]] || { echo "ERROR: no existe el outgroup: $OUTGROUP"; exit 1; }

# convertir rutas a absolutas antes de entrar al directorio de salida
INPUT_DIR_ABS=$(realpath "$INPUT_DIR")
REF_ABS=$(realpath "$REF")
OUTGROUP_ABS=$(realpath "$OUTGROUP")
OUT_DIR_ABS=$(realpath "$OUT_DIR")

# limpiar salida previa
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
cd "$OUT_DIR"

echo "Iniciando análisis filogenómico"
echo "Dataset: $INPUT_DIR_ABS"
echo "Referencia: $REF_ABS"
echo "Outgroup: $OUTGROUP_ABS"
echo "Salida: $OUT_DIR_ABS"

# correr Snippy para cada muestra clínica curada
for fasta in "$INPUT_DIR_ABS"/*.fasta; do
  [[ -f "$fasta" ]] || continue
  muestra=$(basename "$fasta" .fasta)

  echo "Snippy muestra: $muestra"

  snippy \
    --outdir "snippy_${muestra}" \
    --ref "$REF_ABS" \
    --ctgs "$fasta" \
    --cpus "$THREADS"
done

# correr Snippy para PAO1 como outgroup
echo "Snippy outgroup: PAO1"

snippy \
  --outdir "snippy_PAO1" \
  --ref "$REF_ABS" \
  --ctgs "$OUTGROUP_ABS" \
  --cpus "$THREADS"

# verificar resultados de Snippy
for d in snippy_*; do
  if [[ -f "$d/snps.vcf" ]]; then
    echo "OK: $d"
  else
    echo "FALLA: $d"
    exit 1
  fi
done

# construir alineamiento core
snippy-core \
  --ref "$REF_ABS" \
  --prefix core \
  snippy_*

# extraer sitios SNP variables limpios
snp-sites \
  -c \
  -o core.snp.aln \
  core.full.aln

# inferencia filogenética por máxima verosimilitud
iqtree3 \
  -s core.snp.aln \
  -m "$MODEL" \
  -B "$BOOTSTRAP" \
  --alrt "$ALRT" \
  -bnni \
  -T "$THREADS" \
  -redo

# matriz de distancias SNP
snp-dists \
  -j "$THREADS" \
  core.snp.aln > snippy_distancias.tsv

echo "Análisis filogenómico terminado"
echo "Árbol: ${OUT_DIR_ABS}/core.snp.aln.treefile"
echo "Alineamiento core: ${OUT_DIR_ABS}/core.full.aln"
echo "Alineamiento SNP: ${OUT_DIR_ABS}/core.snp.aln"
echo "Matriz SNP: ${OUT_DIR_ABS}/snippy_distancias.tsv"
echo "Resumen IQ-TREE: ${OUT_DIR_ABS}/core.snp.aln.iqtree"
echo "Log IQ-TREE: ${OUT_DIR_ABS}/core.snp.aln.log"