#!/bin/bash
set -euo pipefail

OUT_DIR="${1:-work}"

rm -rf "$OUT_DIR"

mkdir -p \
  "$OUT_DIR"/metadata \
  "$OUT_DIR"/qc/raw \
  "$OUT_DIR"/qc/filt \
  "$OUT_DIR"/qc_assembly/busco/raw \
  "$OUT_DIR"/qc_assembly/busco/filt \
  "$OUT_DIR"/qc_assembly/busco/raw_medaka \
  "$OUT_DIR"/qc_assembly/busco/filt_medaka \
  "$OUT_DIR"/qc_assembly/quast \
  "$OUT_DIR"/kraken/controles \
  "$OUT_DIR"/kraken/muestras \
  "$OUT_DIR"/mlst \
  "$OUT_DIR"/phylogeny \
  "$OUT_DIR"/annotation/bakta \
  "$OUT_DIR"/annotation/amrfinder

echo "Exportando a: $OUT_DIR"

# metadata
cp -v data/metadata/metadata.xlsx "$OUT_DIR"/metadata/

# qc
cp -v results/qc/raw/multiqc/multiqc_data/multiqc_general_stats.txt "$OUT_DIR"/qc/raw/
cp -v results/qc/filt/multiqc/multiqc_data/multiqc_general_stats.txt "$OUT_DIR"/qc/filt/

# assembly_qc - BUSCO
cp -rv results/assembly_qc/busco/raw/* "$OUT_DIR"/qc_assembly/busco/raw/
cp -rv results/assembly_qc/busco/filtered/* "$OUT_DIR"/qc_assembly/busco/filt/
cp -rv results/assembly_qc/busco/medaka_raw/* "$OUT_DIR"/qc_assembly/busco/raw_medaka/
cp -rv results/assembly_qc/busco/medaka_filtered/* "$OUT_DIR"/qc_assembly/busco/filt_medaka/

# assembly_qc - QUAST
cp -v results/assembly_qc/quast/raw/report.tsv "$OUT_DIR"/qc_assembly/quast/quast_raw.tsv
cp -v results/assembly_qc/quast/filtered/report.tsv "$OUT_DIR"/qc_assembly/quast/quast_filt.tsv
cp -v results/assembly_qc/quast/medaka_raw/report.tsv "$OUT_DIR"/qc_assembly/quast/quast_raw_medaka.tsv
cp -v results/assembly_qc/quast/medaka_filtered/report.tsv "$OUT_DIR"/qc_assembly/quast/quast_filt_medaka.tsv

# kraken
cp -v results/taxonomy/kraken2/medaka_filtered/controles/*_output.txt "$OUT_DIR"/kraken/controles/
cp -v results/taxonomy/kraken2/medaka_filtered/muestras/*_output.txt "$OUT_DIR"/kraken/muestras/

# mlst
cp -v results/typing/mlst/mlst_results.tsv "$OUT_DIR"/mlst/

# phylogeny
cp -v results/phylogeny/snippy_iqtree/core.snp.aln "$OUT_DIR"/phylogeny/
cp -v results/phylogeny/snippy_iqtree/core.full.aln "$OUT_DIR"/phylogeny/
cp -v results/phylogeny/snippy_iqtree/core.aln "$OUT_DIR"/phylogeny/
cp -v results/phylogeny/snippy_iqtree/core.snp.aln.iqtree "$OUT_DIR"/phylogeny/
cp -v results/phylogeny/snippy_iqtree/core.snp.aln.log "$OUT_DIR"/phylogeny/
cp -v results/phylogeny/snippy_iqtree/core.snp.aln.contree "$OUT_DIR"/phylogeny/
cp -v results/phylogeny/snippy_iqtree/core.snp.aln.ufboot "$OUT_DIR"/phylogeny/
cp -v results/phylogeny/snippy_iqtree/core.tab "$OUT_DIR"/phylogeny/
cp -v results/phylogeny/snippy_iqtree/core.txt "$OUT_DIR"/phylogeny/
cp -v results/phylogeny/snippy_iqtree/core.snp.aln.treefile "$OUT_DIR"/
cp -v results/phylogeny/snippy_iqtree/snippy_distancias.tsv "$OUT_DIR"/

# annotation - Bakta
for d in results/annotation/bakta/*; do
  [ -d "$d" ] || continue
  muestra=$(basename "$d")
  mkdir -p "$OUT_DIR/annotation/bakta/$muestra"

  cp "$d"/*.faa "$OUT_DIR/annotation/bakta/$muestra/" 2>/dev/null || true
  cp "$d"/*.fna "$OUT_DIR/annotation/bakta/$muestra/" 2>/dev/null || true
  cp "$d"/*.gff3 "$OUT_DIR/annotation/bakta/$muestra/" 2>/dev/null || true
  cp "$d"/*.tsv "$OUT_DIR/annotation/bakta/$muestra/" 2>/dev/null || true
  cp "$d"/*.json "$OUT_DIR/annotation/bakta/$muestra/" 2>/dev/null || true
  cp "$d"/*.txt "$OUT_DIR/annotation/bakta/$muestra/" 2>/dev/null || true

  rm -f "$OUT_DIR/annotation/bakta/$muestra"/*.hypotheticals.*
done

# annotation - AMRFinderPlus
for d in results/annotation/amrfinder/*; do
  [ -d "$d" ] || continue
  muestra=$(basename "$d")
  mkdir -p "$OUT_DIR/annotation/amrfinder/$muestra"

  cp "$d"/*.tsv "$OUT_DIR/annotation/amrfinder/$muestra/"
done

# comprimir exportación
tar -czf "${OUT_DIR}.tar.gz" "$OUT_DIR"

echo
echo "Exportación finalizada"
echo "Carpeta: $OUT_DIR"
echo "Archivo comprimido: ${OUT_DIR}.tar.gz"

du -sh "$OUT_DIR"
ls -lh "${OUT_DIR}.tar.gz"