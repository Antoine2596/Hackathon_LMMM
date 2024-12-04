# Snakefile

# Amélioration 1 : Optimisation des ressources
# Ajouter des directives `resources` (mémoire, threads) et des benchmarks 
# pour chaque règle pour améliorer l'efficacité et faciliter la parallélisation
#+ ajouter parallélisation partout où c'est possible  : zip/dézip (avec pigz), cutadapt, bowtie si possible

# Amélioration 2 : Utilisation des wildcards
# Utiliser `{wildcards.sample}` dans les noms de fichiers pour adapter le workflow 
# dynamiquement à chaque échantillon sans duplication de code.

# Chargement de la liste des échantillons depuis le fichier "samples.txt"
SAMPLES = [line.strip() for line in open("samples.txt")]
SUFFIX = ["1", "2", "3", "4", "rev.1", "rev.2"]
CONTAIN = ["bowtie_v0.12.7","cutadapt_v1.11","featureCounts_v1.4.6-p3","R_v3.4.1", "SRAtoolkit"]

# Définir la règle finale "all"
# TODO 1 : modifier input une fois la version pré-finale du snakefile réalisé.
rule all:
    input:
        "genome/reference_genome.fasta",  # Génome de référence
        "genome/reference_annotations.gff",
        expand("fastq/{sample}.fastq.gz", sample=SAMPLES),  # Fichiers FASTQ
        #expand("minidata/mini_{sample}.fastq.gz", sample=SAMPLES),  # Données réduites
        # Ajouter les fichiers de sortie finaux des autres règles ici
        expand("bowtie_files/bowtie_index/index.{suffix}.ebwt", suffix=SUFFIX),
        expand("trimming/{sample}.fastq.gz", sample=SAMPLES),   # si output cutAdapt
        expand("mapping/{sample}.sam", sample=SAMPLES),   # si output mapping
        expand("featureCounts_files/{sample}_count.txt", sample=SAMPLES),
        expand("featureCounts_files/{sample}_count.txt.summary", sample=SAMPLES),
        expand("sif_files/{contain}.sif", contain=CONTAIN)
        # Compléter ici avec les autres fichiers finaux requis


# Règle pour télécharger les conteneurs
rule download_containers:
    output:
        "sif_files/{contain}.sif"
    shell:
        """
        wget -O sif_files/{wildcards.contain}.sif "https://zenodo.org/records/14261800/files/{wildcards.contain}.sif?download=1"
        """


# Règle pour télécharger le génome de référence
rule download_genome:
    input:
        "sif_files/SRAtoolkit.sif"
    output:
        gff = "genome/reference_annotations.gff",
        fasta = "genome/reference_genome.fasta"
    container:
        "./sif_files/SRAtoolkit.sif"
    shell:
        """ 
        wget -q -O {output.fasta} "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=CP000253.1&rettype=fasta"
        wget -O {output.gff} "https://www.ncbi.nlm.nih.gov/sviewer/viewer.cgi?db=nuccore&report=gff3&id=CP000253.1"
        """

# Règle pour l'indexation du génome de référence
rule bowtie:
    input:
        "genome/reference_genome.fasta"
    output:
        bowtie_index=expand("bowtie_files/bowtie_index/index.{suffix}.ebwt", suffix=SUFFIX)
    container:
        "./sif_files/bowtie_v0.12.7.sif"
    shell:
        # Note : le chemin d'entrée et de sortie pourrait nécessiter une adaptation en fonction des fichiers exacts.
        # TODO 3 : Vérifier le chemin d'accès pour éviter les erreurs
        """bowtie-build {input} bowtie_files/bowtie_index/index"""

# Règle pour télécharger les fichiers FASTQ
rule download_fastq:
    input:
        "sif_files/SRAtoolkit.sif"
    output:
        "fastq/{sample}.fastq"      # Pareil, mise des fichiers dans le répertoire "fastq"
    container:
        "./sif_files/SRAtoolkit.sif"  # Utilisation du fichier image .sif
    shell:
        "fasterq-dump {wildcards.sample} -O fastq/ --mem 14 --threads 4"   #ajuster à terme

#regle compression fastq
rule compress_fastq:
    input : 
        "fastq/{sample}.fastq"
    output : 
        "fastq/{sample}.fastq.gz"
    container : 
        "./sif_files/SRAtoolkit.sif"
    shell :
        """
        gzip fastq/{wildcards.sample}.fastq -c > fastq/{wildcards.sample}.fastq.gz
        rm fastq/{wildcards.sample}.fastq
        echo "fichier {input} réduit et compressé à {output}"
        """



# il y aura des des erreurs d’exécution ou de dépendances non résolues.
# Une fois qu'on a les fichiers attendus, faut penser a adapter (input/output)
# pour une exécution fluide.

# Règle pour le prétraitement des fichiers FASTQ (minidata) (trim des séquences)
rule cutAdapt:
    input:
        "fastq/{sample}.fastq.gz"
    output:
        "trimming/{sample}.fastq.gz"
        # a réadapter !!!
    container:
        "./sif_files/cutadapt_v1.11.sif"
    shell:
        """
        cutadapt -q 20 -m 25 -o {output} {input}
        """
        # A READAPTER !!! -> avec multithreading par exemple pour accélérer
   

# il y aura des des erreurs d’exécution ou de dépendances non résolues.
# Une fois qu'on a les fichiers attendus, faut penser a adapter (input/output)
# pour une exécution fluide.

# Règle de mappage des lectures sur le génome de référence avec Bowtie
rule mapping:
    input:
        trimmed_fastq="trimming/{sample}.fastq.gz",  # Sortie de la règle cutAdapt
        bowtie_index=expand("bowtie_files/bowtie_index/index.{ext}", ext=["1.ebwt", "2.ebwt", "3.ebwt", "4.ebwt", "rev.1.ebwt", "rev.2.ebwt"])
    output:
        sam="mapping/{sample}.sam"
    threads:
        4
    container:
        "./sif_files/bowtie_v0.12.7.sif"
    shell:
        """
        gunzip -c {input.trimmed_fastq} | bowtie -q -S -p {threads} bowtie_files/bowtie_index/index - {output.sam}
        """
    #c'est mis sur 4 coeurs/exécution (-p {threads})


# # il y aura des des erreurs d’exécution ou de dépendances non résolues.
# # Une fois qu'on a les fichiers attendus, faut penser a adapter (input/output)
# # pour une exécution fluide.

 # Règle pour compter les caractéristiques (gènes/exons) dans les données alignées
rule featurecount:
    input:
        sam="mapping/{sample}.sam",  # Fichier SAM généré par bowtie
        annotations="genome/reference_annotations.gff"  # Fichier GTF
    output:
        counts="featureCounts_files/{sample}_count.txt",  # Résultats des comptes
        summary="featureCounts_files/{sample}_count.txt.summary"  # Résumé
    threads:
        4
    container:
        "./sif_files/featureCounts_v1.4.6-p3.sif"
    shell:
        """
        featureCounts -T {threads} -t gene -g ID -s 1 -a {input.annotations} -o {output.counts} {input.sam}
        """
    #pareil ici 4 threads


# Commandes pour exécuter le workflow :
# - Pour exécuter le workflow avec deux tâches en parallèle : `snakemake --cores all --use-singularity`
# - Le paramètre `-cores all` permet la parallélisation, et `--use-singularity` indique d'utiliser Singularity pour chaque conteneur spécifié.
