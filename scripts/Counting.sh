#!/bin/bash

mkdir -p featureCounts_files
rm featureCounts_files/*

if test -f reference.gff; then
  echo "gff exists."

else
   wget -O reference.gff "https://www.ncbi.nlm.nih.gov/sviewer/viewer.cgi?db=nuccore&report=gff3&id=CP000253.1"
fi

if test -f featureCounts_v1.4.6-p3.sif; then
  echo "sif exists"
else
   sudo singularity build featureCounts_v1.4.6-p3.sif def_files/install_featuresCount_v1.4.6-p3.def
fi

singularity exec featureCounts_v1.4.6-p3.sif featureCounts -v

annotation_gff="reference.gff"

for sam_file in bowtie_files/*sam; do
	echo "$sam_file"
	filename=$(basename "$sam_file" ".sam")
	echo "$filename"
	singularity exec featureCounts_v1.4.6-p3.sif featureCounts -t exon -g gene_id -a "$annotation_gff" -o featureCounts_files/"$filename"_counts.txt "$sam_file"
	echo -e "\n doed"
done
