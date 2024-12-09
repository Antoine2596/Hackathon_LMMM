# Snakefile


#Listes utiles : noms de gènes à télécharger, suffixes de mapping, nom des images de sortie
SAMPLES = ["SRR10379724", "SRR10379725", "SRR10379726", "SRR10379723", "SRR10379722", "SRR10379721"]
SUFFIX = ["1", "2", "3", "4", "rev.1", "rev.2"]

#Règle finale "all"
rule all:
    input:
        "genome/reference_genome.fasta",  #génome de référence
        "genome/reference_annotations.gff",
        expand("fastq/{sample}.fastq.gz", sample=SAMPLES),  #fichiers FASTQ
        expand("bowtie_files/bowtie_index/index.{suffix}.ebwt", suffix=SUFFIX),    #output bowtie
        expand("trimming/{sample}.fastq.gz", sample=SAMPLES),   #output cutAdapt
        expand("mapping/{sample}.sam", sample=SAMPLES),   #output mapping
        expand("featureCounts_files/{sample}_count.txt", sample=SAMPLES),
        expand("featureCounts_files/{sample}_count.txt.summary", sample=SAMPLES),
        "results/Mean_of_normalized_counts_log_fold_change.png",
        "results/log_base_mean_log_fold_change.png",
        "results/PCA_plot.png",
        "results/Volcano_plot.png"


#Téléchargement du génome de référence
rule download_genome:
    output:
        gff = "genome/reference_annotations.gff",
        fasta = "genome/reference_genome.fasta"
    container:
        "https://zenodo.org/records/14261800/files/SRAtoolkit.sif?download=1"
    shell:
        """ 
        wget -q -O {output.fasta} "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=CP000253.1&rettype=fasta"
        wget -O {output.gff} "https://www.ncbi.nlm.nih.gov/sviewer/viewer.cgi?db=nuccore&report=gff3&id=CP000253.1"
        """


#Indexation du génome de référence
rule bowtie:
    input:
        "genome/reference_genome.fasta"     #nécessite que le génome ait été téléchargé
    output:
        bowtie_index=expand("bowtie_files/bowtie_index/index.{suffix}.ebwt", suffix=SUFFIX)
    container:
        "https://zenodo.org/records/14261800/files/bowtie_v0.12.7.sif?download=1"
    shell:
        """bowtie-build {input} bowtie_files/bowtie_index/index"""


#Téléchargenet des fichiers FASTQ
rule download_fastq:
    output:
        "fastq/{sample}.fastq"      #utilisation de {sample} permet de paralléliser cette tâche (et les suivantes)
    container:
        "https://zenodo.org/records/14261800/files/SRAtoolkit.sif?download=1"
    shell:
        "fasterq-dump {wildcards.sample} -O fastq/ --mem 14 --threads 4"   #ajuster à terme


#Compression fastq
rule compress_fastq:
    input : 
        "fastq/{sample}.fastq"
    output : 
        "fastq/{sample}.fastq.gz"
    container :
        "https://zenodo.org/records/14261800/files/SRAtoolkit.sif?download=1"       #ce container contient gunzip
    shell :
        """
        gzip fastq/{wildcards.sample}.fastq -c > fastq/{wildcards.sample}.fastq.gz
        rm fastq/{wildcards.sample}.fastq
        echo "fichier {input} réduit et compressé à {output}"
        """


#Prétraitement des fichiers FASTQ : trimming
rule cutAdapt:
    input:
        "fastq/{sample}.fastq.gz"
    output:
        "trimming/{sample}.fastq.gz"
    container:
        "https://zenodo.org/records/14261800/files/cutadapt_v1.11.sif?download=1"
    shell:
        """
        cutadapt -q 20 -m 25 -o {output} {input}
        """


#Mapping des lectures sur le génome de référence avec Bowtie
rule mapping:
    input:
        trimmed_fastq="trimming/{sample}.fastq.gz",  # Sortie de la règle cutAdapt
        bowtie_index=expand("bowtie_files/bowtie_index/index.{ext}", ext=["1.ebwt", "2.ebwt", "3.ebwt", "4.ebwt", "rev.1.ebwt", "rev.2.ebwt"])
    output:
        sam="mapping/{sample}.sam"
    threads:
        4       #4 coeurs/exécution (-p {threads})
    container:
        "https://zenodo.org/records/14261800/files/bowtie_v0.12.7.sif?download=1"
    shell:
        """
        gunzip -c {input.trimmed_fastq} | bowtie -q -S -p {threads} bowtie_files/bowtie_index/index - {output.sam}
        """


#Comptage des caractéristiques (gènes/exons) dans les données alignées
rule featurecount:
    input:
        sam="mapping/{sample}.sam",  #fichier SAM généré par bowtie
        annotations="genome/reference_annotations.gff"  #fichier GTF
    output:
        counts="featureCounts_files/{sample}_count.txt",  #résultats des comptes
        summary="featureCounts_files/{sample}_count.txt.summary"  #résumé
    threads:
        4     #là aussi 4 threads
    container:
        "https://zenodo.org/records/14261800/files/featureCounts_v1.4.6-p3.sif?download=1"
    shell:
        """
        featureCounts -T {threads} -t gene -g ID -s 1 -a {input.annotations} -o {output.counts} {input.sam}
        """


#Construction des images finales
rule deseq2:
    input:
        "featureCounts_files/SRR10379724_count.txt",    #ici impossible d'utiliser les wildcards car y a besoin de tous les fichiers en entrée
        "featureCounts_files/SRR10379725_count.txt",
        "featureCounts_files/SRR10379726_count.txt",
        "featureCounts_files/SRR10379723_count.txt",
        "featureCounts_files/SRR10379722_count.txt",
        "featureCounts_files/SRR10379721_count.txt"
    output:
        "results/Mean_of_normalized_counts_log_fold_change.png",   #pas de sens de mettre un wildcard car le script sort toutes les images d'un coup
        "results/log_base_mean_log_fold_change.png",
        "results/PCA_plot.png",
        "results/Volcano_plot.png"
    container:
        "https://zenodo.org/records/14293893/files/R-4.4.2.sif?download=1"
    shell:
        """
        Rscript DESeq2_final.r
        """

# Commandes pour exécuter le workflow :
# - Pour exécuter le workflow avec tous les jobs possbinles en parallèle : `snakemake --cores all --use-singularity`
# - Le paramètre `-cores all` permet la parallélisation, et `--use-singularity` indique d'utiliser Singularity pour chaque conteneur spécifié.