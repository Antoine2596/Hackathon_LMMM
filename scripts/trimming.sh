#!/bin/bash
# j'ai ajouter la création à l'instant du sif, je fais faire une boucle pour faire la vérif

mkdir -p trimming

if test -f cutadapt_v1.11.sif; then
  echo "File exists"
else
   echo "This file exist bro"
   sudo singularity build featureCounts_v1.4.6-p3.sif def_files/install_featuresCount_v1.4.6-p3.def
fi

sudo singularity build cutadapt_v1.11.sif install_cutAdapt.def

for file in mini_data/*gz ; do
        filename=$(basename "$file" ".fastq.gz")
        echo "$filename"
	singularity exec cutadapt_v1.11.sif cutadapt -a file:fastqc/formated_ADAPTERS.fasta -o trimming/"$filename".fastq.gz  mini_data/"$filename".fastq.gz
done
