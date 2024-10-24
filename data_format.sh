#!/bin/bash

mkdir -p data/mini_data

for file in data/SRA_fastq/*.fastq; do
	filename=$(basename "$file")
	head -n 100000 "$file" > data/mini_data/mini_"$filename"
	echo "fichier $file réduit à data/mini_data$filename"
	gzip data/mini_data/mini_"$filename"
	echo "fichier mini_$filename à été compressé"
done

#chmod +x data_format.sh
