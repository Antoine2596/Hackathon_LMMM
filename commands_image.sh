#!/bin/bash

# IL EST IMPORTANT DE SE PLACER DANS UN REPERTOIRE sif_files 
# "mkdir sif_files "
# "cd ./sif_files"

# SRATOOLKIT
# ajouter la version de SRATOOLKIT dans le nom de l'image (le .sif)
singularity build --fakeroot SRATOOLKIT.sif ../def_files/install_SRATOOLKIT.def

# BOWTIE
singularity build --fakeroot bowtie_v0.12.7.sif ../def_files/install_bowtie.def

# CUTADAPT
singularity build --fakeroot cutAdapt.sif ../def_files/install_cutAdapt.def

# FEATURECOUNTS
singularity build --fakeroot featureCounts_v1.4.6-p3.sif ../def_files/install_featuresCount_v1.4.6-p3.def
