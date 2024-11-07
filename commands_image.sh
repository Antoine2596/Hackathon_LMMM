#!/bin/bash

singularity build --fakeroot --force trimgalore.sif Singularity.def
sudo singularity build bowtie_v0.12.7.sif def_files/install_bowtie.def
sudo singularity build featureCounts_v1.4.6-p3.sif def_files/install_featuresCount_v1.4.6-p3.def