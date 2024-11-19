# Snakefile

# Amélioration 1 : Optimisation des ressources
# Ajouter des directives `resources` (mémoire, threads) et des benchmarks 
# pour chaque règle pour améliorer l'efficacité et faciliter la parallélisation

# Amélioration 2 : Utilisation des wildcards
# Utiliser `{wildcards.sample}` dans les noms de fichiers pour adapter le workflow 
# dynamiquement à chaque échantillon sans duplication de code.

# Chargement de la liste des échantillons depuis le fichier "samples.txt"
SAMPLES = [line.strip() for line in open("samples.txt")]

# Définir la règle finale "all"
# TODO 1 : modifier input une fois la version pré-finale du snakefile réalisé.
rule all:
    input:
        "genome/reference_genome.fasta",  # Génome de référence
        "genome/reference_annotations.gff",
        expand("fastq/{sample}.fastq.gz", sample=SAMPLES),  # Fichiers FASTQ
        #expand("minidata/mini_{sample}.fastq.gz", sample=SAMPLES),  # Données réduites
        # Ajouter les fichiers de sortie finaux des autres règles ici
        expand("bowtie_files/bowtie_index/index.{n}.ebwt", n=[1,2,3,4]), #index de bowtie
        expand("bowtie_files/bowtie_index/index.rev.{n}.ebwt", n=[1,2]),
        #expand("featureCounts_files/{sample}_count.txt", sample=SAMPLES),
        #expand("featureCounts_files/{sample}_count.txt.summary", sample=SAMPLES)
        expand("trimming/{sample}.fastq.gz", sample=SAMPLES),   # si output cutAdapt
        expand("bowtie_files/{sample}.sam", sample=SAMPLES),   # si output mapping
        # Compléter ici avec les autres fichiers finaux requis

# Règle pour télécharger le génome de référence
rule download_genome:
    output:
        fasta="genome/reference_genome.fasta",  #mise des fichiers dans le répertoire "genome"
        gff="genome/reference_annotations.gff"
    container:
        "./sif_files/SRATOOLKIT.sif"  # Utilisation du fichier image .sif
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
        expand("bowtie_files/bowtie_index/index.{n}.ebwt", n=[1, 2, 3, 4]),
        expand("bowtie_files/bowtie_index/index.rev.{n}.ebwt", n=[1, 2])
    container:
        "./sif_files/bowtie_v0.12.7.sif"
    shell:
        # Note : le chemin d'entrée et de sortie pourrait nécessiter une adaptation en fonction des fichiers exacts.
        # TODO 3 : Vérifier le chemin d'accès pour éviter les erreurs
        """bowtie-build {input} bowtie_files/bowtie_index/index"""

# Règle pour télécharger les fichiers FASTQ
rule download_fastq:
    output:
        "fastq/{sample}.fastq"      # Pareil, mise des fichiers dans le répertoire "fastq"
    container:
        "./sif_files/SRATOOLKIT.sif"  # Utilisation du fichier image .sif
    shell:
        "fasterq-dump {wildcards.sample} -O fastq/ --mem 8 --threads 3"

#regle compression fastq
rule compress_fastq:
    input : 
        "fastq/{sample}.fastq"
    output : 
        "fastq/{sample}.fastq.gz"
    container : 
        "./sif_files/SRATOOLKIT.sif"
    shell :
        """
        gzip fastq/{wildcards.sample}.fastq -c > fastq/{wildcards.sample}.fastq.gz
        rm fastq/{wildcards.sample}.fastq
        echo "fichier {input} réduit et compressé à {output}"
        """

# règle qui est voué a disparaitre avec le temps
# règle de création de minidata
#rule minidata:
#    input : 
#        "fastq/{sample}.fastq"
#    output : 
#        "minidata/mini_{sample}.fastq.gz"
#    container : 
#        "./sif_files/SRATOOLKIT.sif"
#    shell :
#        """
#        head -n 100000 {input} > minidata/mini_{wildcards.sample}.fastq.tmp  # temporairement stocké avant compression
#        gzip minidata/mini_{wildcards.sample}.fastq.tmp -c > minidata/mini_{wildcards.sample}.fastq.gz
#        rm minidata/mini_{wildcards.sample}.fastq.tmp
#        echo "fichier {input} réduit et compressé à {output}"
#        """



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
        "./sif_files/cutAdapt.sif"
    shell:
        """
        cutadapt -q 20 -m 25 -o {output} {input}
        """
        # A READAPTER !!!
   

# il y aura des des erreurs d’exécution ou de dépendances non résolues.
# Une fois qu'on a les fichiers attendus, faut penser a adapter (input/output)
# pour une exécution fluide.

# Règle de mappage des lectures sur le génome de référence avec Bowtie
rule mapping:
    input:
        trimmed_fastq="trimming/{sample}.fastq.gz",  # Sortie de la règle cutAdapt
        bowtie_index="bowtie_files/bowtie_index/index"
    output:
        "bowtie_files/{sample}.sam"
        # A readapter
    container:
        "./sif_files/bowtie_v0.12.7.sif"
    shell:
        """gunzip -c {input.trimmed_fastq} > temp.fastq
        bowtie -q -S {input.bowtie_index} temp.fastq > {output}
        rm temp.fastq"""




# # il y aura des des erreurs d’exécution ou de dépendances non résolues.
# # Une fois qu'on a les fichiers attendus, faut penser a adapter (input/output)
# # pour une exécution fluide.

 # Règle pour compter les caractéristiques (gènes/exons) dans les données alignées
#rule featurecount:
#     input:
#         "bowtie_files/{sample}.sam",
#         "genome/annotations.gff"
#     output:
#         "featureCounts_files/{sample}_count.txt",
#         "featureCounts_files/{sample}_count.txt.summary"
#     container:
#         "./sif_files/install_featureCount.sif"
#     shell:
#         """annotation_gtf="genome/ncbi_dataset/data/GCF_000013425.1/genomic_exons.gtf"       
#         for sam_file in bowtie_files/*sam; do
#             echo "$sam_file"
#             filename=$(basename "$sam_file" ".sam")
#             echo "$filename"
#             singularity exec featureCounts_v1.4.6-p3.sif featureCounts -t exon -g gene_id -a "$annotation_gtf" -o featureCounts_files/"$filename"_counts.txt "$sam_file"
#             echo -e "\n doed"
#         done"""


# Commandes pour exécuter le workflow :
# - Pour exécuter le workflow avec deux tâches en parallèle : `snakemake --cores all --use-singularity`
# - Le paramètre `-cores all` permet la parallélisation, et `--use-singularity` indique d'utiliser Singularity pour chaque conteneur spécifié.
