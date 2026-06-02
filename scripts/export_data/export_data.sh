#!/bin/bash
set -euo pipefail

OUT_DIR="${1:-work}"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"/{metadata,qc/raw,qc/filt,qc_assembly/busco,qc_assembly/quast,kraken,mlst,phylogeny,annotation/amrfinder,annotation/bakta}

echo "Exportando a: $OUT_DIR"

# metadata
cp -v data/metadata/metadata.xlsx "$OUT_DIR/metadata/" 2>/dev/null || true

# QC lecturas
cp -v results/qc/raw/multiqc_general_stats.txt "$OUT_DIR/qc/raw/" 2>/dev/null || true
cp -v results/qc/filtered/multiqc_general_stats.txt "$OUT_DIR/qc/filt/" 2>/dev/null || true

# QC ensamblajes
cp -rv results/assembly_qc/busco/* "$OUT_DIR/qc_assembly/busco/" 2>/dev/null || true
cp -rv results/assembly_qc/quast/* "$OUT_DIR/qc_assembly/quast/" 2>/dev/null || true

# Kraken2
find results/taxonomy/kraken2/medaka_filtered -type f \( -name "*_report.txt" -o -name "*_output.txt" \) -exec cp -v {} "$OUT_DIR/kraken/" \; 2>/dev/null || true

# MLST
find results/typing -type f \( -name "*.tsv" -o -name "*.txt" \) -exec cp -v {} "$OUT_DIR/mlst/" \; 2>/dev/null || true

# Filogenia
cp -v results/phylogeny/snippy_iqtree/core.snp.aln.treefile "$OUT_DIR/phylogeny/" 2>/dev/null || true
cp -v results/phylogeny/snippy_iqtree/core.snp.aln "$OUT_DIR/phylogeny/" 2>/dev/null || true
cp -v results/phylogeny/snippy_iqtree/core.full.aln "$OUT_DIR/phylogeny/" 2>/dev/null || true
cp -v results/phylogeny/snippy_iqtree/core.snp.aln.iqtree "$OUT_DIR/phylogeny/" 2>/dev/null || true
cp -v results/phylogeny/snippy_iqtree/core.snp.aln.log "$OUT_DIR/phylogeny/" 2>/dev/null || true
cp -v results/phylogeny/snippy_iqtree/snippy_distancias.tsv "$OUT_DIR/phylogeny/" 2>/dev/null || true

# AMRFinderPlus
find results/annotation/amrfinder -name "*.tsv" -exec cp -v {} "$OUT_DIR/annotation/amrfinder/" \; 2>/dev/null || true

# Bakta
find results/annotation/bakta -type f \( -name "*.faa" -o -name "*.fna" -o -name "*.gff3" -o -name "*.tsv" -o -name "*.json" \) ! -name "*.hypotheticals.*" -exec cp -v {} "$OUT_DIR/annotation/bakta/" \; 2>/dev/null || true

tar -czf "${OUT_DIR}.tar.gz" "$OUT_DIR"

echo "Listo:"
du -sh "$OUT_DIR"
ls -lh "${OUT_DIR}.tar.gz"