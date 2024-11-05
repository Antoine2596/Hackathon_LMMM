# Snakefile

# Charger la liste des échantillons
SAMPLES = [line.strip() for line in open("samples.txt")]

# Définir les fichiers de sortie
rule all:
    input:
        "genome/GCF_000013425.1.fna",
        expand("fastq/{sample}.fastq", sample=SAMPLES)      #on va les ajouter dans le répertoire "fastq/"

# Règle pour télécharger le génome 
rule download_genome:
    output:
        "genome/GCF_000013425.1.fna"      #mise du fichier dans le répertoire "genome"
    shell:
        """ 
        wget  -O genome/GCF_000013425.1.zip "https://api.ncbi.nlm.nih.gov/datasets/v2/genome/accession/GCF_000013425.1/download?include_annotation_type=GENOME_FASTA&include_annotation_type=GENOME_GFF&include_annotation_type=RNA_FASTA&include_annotation_type=CDS_FASTA&include_annotation_type=PROT_FASTA&include_annotation_type=SEQUENCE_REPORT&hydrated=FULLY_HYDRATED"
        unzip -p genome/GCF_000013425.1.zip > {output}    #attention !! il faut l'installer car il n'est apparemment pas là par défaut
        """

# Règle pour télécharger les fichiers FASTQ
rule download_fastq:
    input:
        "genome/GCF_000013425.1.fna"    #permet de télécharger d'abord la référence car implique obligatoirement d'avoir le fichier pour commencer le téléchargement
    output:
        "fastq/{sample}.fastq"      #pareil, mise des fichiers dans le répertoire "fastq"
    container:
	# ajout de l'adresse vers la recette .def singularity (avoir la recette dans un fichier def sur github)
    shell:
        """
        fasterq-dump {wildcards.sample} -O fastq/ --mem 8 --threads 3 
        """

#{wildcards.sample} va récupérer les éléments de "sample.txt" pour les remplacer dans la commande
#shell que snakemake va faire.
#lancer le workflow : snakemake -j 2 --use-singularity
#"-j 2" lui dit de lancer deux tâches en parallèle, c'est à dire qu'il va télécharger les fichiers
#deux par deux tout seul : une parallélisation simple !
# --use-singularity c'est pour dire que faut utiliser singularity









