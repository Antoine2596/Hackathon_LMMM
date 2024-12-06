#!/bin/bash

# prérequis : avoir le génome (fna file)
# output : les sam

rm bowtie_files/*sam


#singularity exec bowtie_v0.12.7.sif bowtie

# créer l'index
singularity exec bowtie_v0.12.7.sif bowtie-build genome/reference.fasta bowtie_files/bowtie_index/index
# apt-get install unzip

for file in mini_data/*; do
	filename=$(basename "$file" ".fastq.gz")
	gunzip "$file"
	echo "$filename"
        singularity exec bowtie_v0.12.7.sif bowtie -q -S bowtie_files/bowtie_index/index mini_data/"$filename".fastq > bowtie_files/"$filename".sam
	gzip mini_data/"$filename".fastq
done

echo "finished bud"
