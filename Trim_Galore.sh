#!/bin/bash

cat << 'EOF' > Singularity.def
Bootstrap: docker
From: ubuntu:20.04

%labels
    Maintainer YourName

%post
    apt-get update && apt-get install -y \
        python3 \
        python3-pip \
        curl \
        unzip \
        wget

    pip3 install --upgrade pip
    pip3 install cutadapt

    # Télécharger et installer Trim Galore
    wget https://github.com/FelixKrueger/TrimGalore/archive/refs/tags/0.6.7.zip
    unzip 0.6.7.zip
    cd TrimGalore-0.6.7
    cp trim_galore /usr/local/bin/
    chmod +x /usr/local/bin/trim_galore

%runscript
    exec "$@"
EOF


singularity build --fakeroot --force trimgalore.sif Singularity.def

mkdir -p Trim_file

for file in mini_data/*fastq;do
        filename=$(basename "$file" .fastq)
        singularity exec trimgalore.sif trim_galore --quality 20 "$file" --output_dir Trim_file/trimed_"$filename"
done
done

ls -lrth Trim_file/*
