#!/bin/bash

# prérequis : avoir le génome (fna file)
# output : les sam


if test -f bowtie_v0.12.7.sif; then
  echo "File exists."
else
   echo "File NO EXIST WTF"
   sudo singularity build bowtie_v0.12.7.sif def_files/install_bowtie.def
fi

#singularity exec bowtie_v0.12.7.sif bowtie

# créer l'index
singularity exec bowtie_v0.12.7.sif bowtie-build genome/ncbi_dataset/data/GCF_000013425.1/GCF_000013425.1_ASM1342v1_genomic.fna bowtie_files/bowtie_index/index
# apt-get install unzip

for file in mini_data/*; do
	filename=$(basename "$file" ".fastq.gz")
	gunzip "$file"
	echo "$filename"
	singularity exec bowtie_v0.12.7.sif bowtie -q bowtie_files/bowtie_index/index mini_data/"$filename".fastq > bowtie_files/"$filename".sam
	gzip mini_data/"$filename".fastq
done

echo "finished bud"
