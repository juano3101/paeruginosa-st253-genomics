#!/bin/bash
set -euo pipefail

# exportar resultados necesarios para análisis y visualización en Quarto

OUT_DIR="${1:-work}"

echo "Creando carpeta de exportación: $OUT_DIR"

rm -rf "$OUT_DIR"

mkdir -p \
  "$OUT_DIR"/metadata \
  "$OUT_DIR"/qc/raw \
  "$OUT_DIR"/qc/filt \
  "$OUT_DIR"/qc_assembly/busco \
  "$OUT_DIR"/qc_assembly/quast \
  "$OUT_DIR"/kraken \
  "$OUT_DIR"/mlst \
  "$OUT_DIR"/phylogeny \
  "$OUT_DIR"/annotation/amrfinder \
  "$OUT_DIR"/annotation/bakta

############################
# metadata
############################

cp metadata/metadata.xlsx \
  "$OUT_DIR"/metadata/ 2>/dev/null || true

cp work/metadata.xlsx \
  "$OUT_DIR"/metadata/ 2>/dev/null || true

############################
# QC lecturas
############################

cp results/qc/raw/multiqc_general_stats.txt \
  "$OUT_DIR"/qc/raw/ 2>/dev/null || true

cp results/qc/filtered/multiqc_general_stats.txt \
  "$OUT_DIR"/qc/filt/ 2>/dev/null || true

############################
# BUSCO
############################

if [[ -d results/qc_assembly/busco ]]; then
  cp -r results/qc_assembly/busco \
    "$OUT_DIR"/qc_assembly/
fi

############################
# QUAST
############################

if [[ -d results/qc_assembly/quast ]]; then
  cp -r results/qc_assembly/quast \
    "$OUT_DIR"/qc_assembly/
fi

############################
# Kraken2
############################

find results/taxonomy/kraken2 \
  -name "*report.txt" \
  -exec cp {} "$OUT_DIR"/kraken/ \; \
  2>/dev/null || true

############################
# MLST
############################

find results/mlst \
  -name "*.tsv" \
  -exec cp {} "$OUT_DIR"/mlst/ \; \
  2>/dev/null || true

############################
# Filogenia
############################

cp results/phylogeny/snippy_iqtree/core.snp.aln.treefile \
  "$OUT_DIR"/phylogeny/ 2>/dev/null || true

cp results/phylogeny/snippy_iqtree/snippy_distancias.tsv \
  "$OUT_DIR"/phylogeny/ 2>/dev/null || true

cp results/phylogeny/snippy_iqtree/core.snp.aln \
  "$OUT_DIR"/phylogeny/ 2>/dev/null || true

cp results/phylogeny/snippy_iqtree/core.full.aln \
  "$OUT_DIR"/phylogeny/ 2>/dev/null || true

cp results/phylogeny/snippy_iqtree/core.snp.aln.iqtree \
  "$OUT_DIR"/phylogeny/ 2>/dev/null || true

############################
# AMRFinderPlus
############################

find results/annotation/amrfinder \
  -name "*.tsv" \
  -exec cp --parents {} "$OUT_DIR"/annotation/ \; \
  2>/dev/null || true

############################
# Bakta
############################

find results/annotation/bakta \
  \( \
    -name "*.faa" -o \
    -name "*.fna" -o \
    -name "*.gff3" -o \
    -name "*.tsv" -o \
    -name "*.json" \
  \) \
  ! -name "*.hypotheticals.*" \
  -exec cp --parents {} "$OUT_DIR"/annotation/ \; \
  2>/dev/null || true

############################
# comprimir
############################

tar -czf "${OUT_DIR}.tar.gz" "$OUT_DIR"

echo
echo "Exportación finalizada"
echo "Carpeta: $OUT_DIR"
echo "Archivo comprimido: ${OUT_DIR}.tar.gz"

du -sh "$OUT_DIR"
ls -lh "${OUT_DIR}.tar.gz"