# Snakefile

# Charger la liste des échantillons
SAMPLES = [line.strip() for line in open("samples.txt")]

# Définir les fichiers de sortie
rule all:
    input:
        expand("fastq/{sample}.fastq", sample=SAMPLES)      #on va les ajouter dans le répertoire "fastq/"

# Règle pour télécharger les fichiers FASTQ
rule download_fastq:
    output:
        "fastq/{sample}.fastq"      #pareil, mise des fichiers dans le répertoire "fastq"
    shell:
        """
        fasterq-dump {wildcards.sample} -O fastq/ --mem 6 --threads 2 
        """

#{wildcards.sample} va récupérer les éléments de "sample.txt" pour les remplacer dans la commande
#shell que snakemake va faire.
#lancer le workflow : snakemake -j 2 
#"-j 2" lui dit de lancer deux tâches ne parallèle, c'est à dire qu'il va télécharger les fichiers
#deux par deux tout seul : une parallélisation simple !
