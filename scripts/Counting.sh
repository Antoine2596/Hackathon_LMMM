#!/bin/bash

mkdir -p featureCounts_files
rm featureCounts_files/*
if test -f featureCounts_v1.4.6-p3.sif; then
  echo "File exists"
else
   echo "File NO EXIST"
   sudo singularity build featureCounts_v1.4.6-p3.sif def_files/install_featuresCount_v1.4.6-p3.def
fi

singularity exec featureCounts_v1.4.6-p3.sif featureCounts -v

annotation_gtf="genome/ncbi_dataset/data/GCF_000013425.1/genomic_exons.gtf"

for sam_file in bowtie_files/*sam; do
	echo "$sam_file"
	filename=$(basename "$sam_file" ".sam")
	echo "$filename"
	singularity exec featureCounts_v1.4.6-p3.sif featureCounts -t exon -g gene_id -a "$annotation_gtf" -o featureCounts_files/"$filename"_counts.txt "$sam_file"
	echo -e "\n doed"
done
