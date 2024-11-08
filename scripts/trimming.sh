*#!/bin/bash
# j'ai ajouter la création à l'instant du sif, je fais faire une boucle pour faire la vérif

mkdir -p trimming

if test -f cutadapt_v1.11.sif; then
  echo "File exists"
else
   echo "This file exist"
   sudo singularity build cutadapt_v1.11.sif def_files/install_cutAdapt.def
fi

for file in mini_data/*gz ; do
        filename=$(basename "$file" ".fastq.gz")
        echo "$filename"
	# singularity exec cutadapt_v1.11.sif cutadapt -a file:fastqc/formated_ADAPTERS.fasta -o trimming/"$filename".fastq.gz  mini_data/"$filename".fastq.gz
	singularity exec cutadapt_v1.11.sif cutadapt -o trimming/"$filename".fastq.gz  mini_data/"$filename".fastq.gz
done
