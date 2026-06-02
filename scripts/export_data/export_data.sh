#!/bin/bash
set -euo pipefail

OUT_DIR="${1:-work}"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"/{metadata,qc/raw,qc/filt,qc_assembly/busco,qc_assembly/quast,kraken,mlst,phylogeny,annotation/amrfinder,annotation/bakta}

echo "Exportando a: $OUT_DIR"

# metadata
mkdir -p "$OUT_DIR/metadata"
cp -v data/metadata/metadata.xlsx "$OUT_DIR/metadata/"

# qc
mkdir -p "$OUT_DIR/qc/raw" "$OUT_DIR/qc/filt"
cp -v results/qc/raw/multiqc/multiqc_data/multiqc_general_stats.txt "$OUT_DIR/qc/raw/"
cp -v results/qc/filt/multiqc/multiqc_data/multiqc_general_stats.txt "$OUT_DIR/qc/filt/"

# assembly_qc
mkdir -p "$OUT_DIR/qc_assembly/busco/raw" \
         "$OUT_DIR/qc_assembly/busco/filt" \
         "$OUT_DIR/qc_assembly/busco/raw_medaka" \
         "$OUT_DIR/qc_assembly/busco/filt_medaka" \
         "$OUT_DIR/qc_assembly/quast"

find results/assembly_qc/busco/raw -name "*.json" -exec cp -v {} "$OUT_DIR/qc_assembly/busco/raw/" \;
find results/assembly_qc/busco/filtered -name "*.json" -exec cp -v {} "$OUT_DIR/qc_assembly/busco/filt/" \;
find results/assembly_qc/busco/medaka_raw -name "*.json" -exec cp -v {} "$OUT_DIR/qc_assembly/busco/raw_medaka/" \;
find results/assembly_qc/busco/medaka_filtered -name "*.json" -exec cp -v {} "$OUT_DIR/qc_assembly/busco/filt_medaka/" \;

cp -v results/assembly_qc/quast/raw/report.tsv "$OUT_DIR/qc_assembly/quast/quast_raw.tsv"
cp -v results/assembly_qc/quast/filtered/report.tsv "$OUT_DIR/qc_assembly/quast/quast_filt.tsv"
cp -v results/assembly_qc/quast/medaka_raw/report.tsv "$OUT_DIR/qc_assembly/quast/quast_raw_medaka.tsv"
cp -v results/assembly_qc/quast/medaka_filtered/report.tsv "$OUT_DIR/qc_assembly/quast/quast_filt_medaka.tsv"

# kraken
mkdir -p "$OUT_DIR/kraken/controles" "$OUT_DIR/kraken/muestras"
cp -v results/taxonomy/kraken2/medaka_filtered/controles/*_output.txt "$OUT_DIR/kraken/controles/"
cp -v results/taxonomy/kraken2/medaka_filtered/muestras/*_output.txt "$OUT_DIR/kraken/muestras/"

# mlst
mkdir -p "$OUT_DIR/mlst"
cp -v results/typing/mlst/mlst_results.tsv "$OUT_DIR/mlst/"

# phylogeny
mkdir -p "$OUT_DIR/phylogeny"
cp -v results/phylogeny/snippy_iqtree/core.snp.aln "$OUT_DIR/phylogeny/"
cp -v results/phylogeny/snippy_iqtree/core.full.aln "$OUT_DIR/phylogeny/"
cp -v results/phylogeny/snippy_iqtree/core.aln "$OUT_DIR/phylogeny/"
cp -v results/phylogeny/snippy_iqtree/core.snp.aln.iqtree "$OUT_DIR/phylogeny/"
cp -v results/phylogeny/snippy_iqtree/core.snp.aln.log "$OUT_DIR/phylogeny/"
cp -v results/phylogeny/snippy_iqtree/core.snp.aln.contree "$OUT_DIR/phylogeny/"
cp -v results/phylogeny/snippy_iqtree/core.snp.aln.ufboot "$OUT_DIR/phylogeny/"
cp -v results/phylogeny/snippy_iqtree/core.tab "$OUT_DIR/phylogeny/"
cp -v results/phylogeny/snippy_iqtree/core.txt "$OUT_DIR/phylogeny/"
cp -v results/phylogeny/snippy_iqtree/core.snp.aln.treefile "$OUT_DIR/"
cp -v results/phylogeny/snippy_iqtree/snippy_distancias.tsv "$OUT_DIR/"

# annotation bakta
mkdir -p "$OUT_DIR/annotation/bakta"

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

# annotation amrfinder
mkdir -p "$OUT_DIR/annotation/amrfinder"

for d in results/annotation/amrfinder/*; do
  [ -d "$d" ] || continue
  muestra=$(basename "$d")
  mkdir -p "$OUT_DIR/annotation/amrfinder/$muestra"

  cp "$d"/*.tsv "$OUT_DIR/annotation/amrfinder/$muestra/"
done

tar -czf "${OUT_DIR}.tar.gz" "$OUT_DIR"

echo "Exportación finalizada"
du -sh "$OUT_DIR"
ls -lh "${OUT_DIR}.tar.gz"