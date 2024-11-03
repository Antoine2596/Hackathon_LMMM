# Download xls file
wget https://ftp.ncbi.nlm.nih.gov/geo/series/GSE139nnn/GSE139659/suppl/GSE139659%5FIPvsctrl.complete.xls.gzwget https://ftp.ncbi.nlm.nih.gov/geo/series/GSE139nnn/GSE139659/suppl/GSE139659%5FIPvsctrl.complete.xls.gz

# Decompress
gunzip GSE139659_IPvsctrl.complete.xls.gz

# Convert xls to csv

## Installation avec gnumeric (pour l'instant peut-être à éviter)
## Install gnumeric (https://stackoverflow.com/questions/10557360/convert-xlsx-to-csv-in-linux-with-command-line)
## Ubuntu
# apt-get install gnumeric


docker pull sanrep/gnumeric
docker run -it --rm -u $(id -u):$(id -g) -v .:/data sanrep/gnumeric bash

# Dans le docker
ssconvert GSE139659_IPvsctrl.complete.xls csv.csv

# Remplacer les "," du csv par des tabulations (je n'ai pas trouvé pour le faire directement via gnumeric)
sed -i -e 's/,/\t/g' csv.csv


# Installer singularity
# enlever les anciennes installations
sudo rm -rf /usr/local/go
sudo rm -rf ~/singularity-ce-4.2.0

#lancer les scripts de la docu (juste du copier-coller)
sudo apt-get update

sudo apt-get install -y    autoconf    automake    cryptsetup    fuse2fs    git    fuse    libfuse-dev    libglib2.0-dev    libseccomp-dev    libtool    pkg-config    runc    squashfs-tools    squashfs-tools-ng    uidmap    wget    zlib1g-dev

export VERSION=1.22.6 OS=linux ARCH=amd64 &&   wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz &&   sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz &&   rm go$VERSION.$OS-$ARCH.tar.gz

echo 'export PATH=/usr/local/go/bin:$PATH' >> ~/.bashrc &&   source ~/.bashrc

export VERSION=4.2.0 &&     wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-ce-${VERSION}.tar.gz &&     tar -xzf singularity-ce-${VERSION}.tar.gz &&     cd singularity-ce-${VERSION}

./mconfig &&     make -C builddir &&     sudo make -C builddir install

cd ../

singularity --version





### DOCKER SINGULARITY

sudo apt-get update
sudo apt-get upgrade


'''
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
'''

'''
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
'''

'''
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
'''

'''
sudo apt-get update
'''

'''
sudo apt-get install docker-ce
'''

'''
sudo systemctl status docker
'''

# vérifier docker
'''
docker run hello-world
'''

# TRIMGALORE
# j'ai pris celui ci car il est assez recent et il est de paris
'''
docker pull genomicpariscentre/trimgalore
'''

# conversion docker en sigularity image
'''
singularity pull trimgalore.sif docker://genomicpariscentre/trimgalore
'''

'''
singularity exec trimgalore.sif trim_galore --h
'''

# super ça marche
# il manque des trucs pour pouvoir faire le trim

# faut faire une image manuellement
'''
nano Singularity.def
'''

# contenu :
'''
Bootstrap: docker
From: ubuntu:20.04  # ou une autre version de ton choix

%post
    # Installer les dépendances
    apt-get update && \
    apt-get install -y \
    python3-pip \
    cutadapt \
    wget \
    && \
    # Installer Trim Galore via pip
    pip3 install trim-galore

%environment
    # Ajouter le chemin à l'environnement
    export PATH="/usr/local/bin:$PATH"

'''


# J'essaye d'installer avec pip3
'''
singularity build --fakeroot trimgalore.sif Singularity.def
'''

'''
You are using pip version 8.1.1, however version 24.2 is available.
You should consider upgrading via the 'pip install --upgrade pip' command.
'''

'''
pip install --upgrade pip
'''

# bon ça foire donc je vais faire autrement.

'''
Bootstrap: docker
From: genomicpariscentre/trimgalore

%post
    apt-get update && apt-get install -y \
        python3 \
        cutadapt \
        && apt-get clean

%environment
    export PATH=/usr/local/bin:$PATH
'''

# j'ai un problème avec l'installation de cutadapt via pip
# faut mettre à jouer pip


# d'ailleur j'ai décidé d'installer Trim_galore via github
# Car la version que j'ai pris via docker n'était qu'une version amateur
'''
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

    # Installer Trim Galore
    wget https://github.com/FelixKrueger/TrimGalore/archive/refs/tags/0.6.7.zip
    unzip 0.6.7.zip
    cd TrimGalore-0.6.7
    cp trim_galore /usr/local/bin/
    chmod +x /usr/local/bin/trim_galore

%runscript
    exec "$@"
'''

# je met un fakeroot pour pouvoir lancer le build, cependant je suis pas censé le faire normalent via singularity, donc à voir le soucis
'''
singularity build --fakeroot trimgalore_with_cutadapt.sif Singularity.def
'''

# test commande
'''
singularity exec trimgalore_with_cutadapt.sif trim_galore --quality 20 mini_data/mini_SRR10379721.fastq
'''
# ça fonctionne
# Pourquoi --quality 20 ? car c'est la valeur par défaut, je le même quand même au cas où on décide de changer ce paramètre par une autre valeur.
# Via cette commande on obtient 2 fichiers
# mini_SRR10379721.fastq_trimming_report.txt
# mini_SRR10379721_trimmed.fq
# Je vais faire pour tout les fichiers via une boucle


# Voici le script qui fonctionne :
'''
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
'''

# MAPPING
# On va faire le mapping avec bowtie, je vais utiliser le TP pour faire mes trucs

# En premier temps je lance les commandes seules en manuelle pour voir si ça passe
'''
pip3 install --upgrade pip
'''

'''
pip3 install damona
'''

'''
damona
'''
# rien ne se passe, pourtant pip3 m'avait assurer que l'installation c'était produit
# alors on regarde si il est dans /bin/


'''
ls ~/.local/bin/damona
'''
#/home/ubuntu/.local/bin/damona
# Cet idiot y est, donc il est juste pas pas ajouter au chemin d'exécution

'''
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
source ~/.bashrc
'''


'''
damona
'''

#Before using Damona, you have to copy/paste the following code in
#your ~/.bashrc file once for all (start a new shell afterwards):
#
#    if [ ! -f  "~/.config/damona/damona.sh" ] ; then
#        source ~/.config/damona/damona.sh
#    fi

# Alors on fait ce qu'il demande

'''
if [ ! -f  "~/.config/damona/damona.sh" ] ; then
        source ~/.config/damona/damona.sh
    fi

source ~/.bashrc
'''


'''
damona
'''
#======================================
#          Welcome to DAMONA
# ======================================

# Ok, je crois que c'est bon
# Dans le TP ensuite il y a cette commande:
'''
damona search bowtie2
'''

# On le fais pour voir les packages à disposition
# damona install bowtie2:2.5.1 y est

'''
damona install bowtie2:2.5.1
'''


# ERROR: [damona.environ,l 260]: You do not have any environment activated.

damona activate
'''

# https://damona.readthedocs.io/en/latest/userguide.html#DAMONA_SINGULARITY_OPTIONS
'''
damona --help
'''

'''
damona --version
'''
# damona, version 0.14.3

'''
damona activate BOWTIE
'''

# Faut d'abord check si lui est bon

'''
damona env
'''
# Your current env is 'TEST'.


'''
damona activate base
'''
# nothing done

'''
damona install bowtie2:2.5.1
'''
# installation working gud gud gud

'''
bowtie2
'''
# ça marche

# bowtie2 [options]* -x <bt2-idx> {-1 <m1> -2 <m2> | -U <r> | --interleaved <i> | -b <bam>} [-S <sam>]


# Premier essai
'''
bowtie2 -q --very-fast -x <bt2-index???> ??
'''
# Déjà c'est quoi l'index bowtie2?
# après un moment de recherche enfaite on doit le créer nous-même, c'est même pas spécifié dans la docu sérieux

https://bowtie-bio.sourceforge.net/bowtie2/manual.shtml

'''
bowtie2-build
'''

# Ah ok, enfaite comme c'est dans le schéma du projet
# on doit créer l'index à partir du génome de référence


#############################
# Enfaite faut pas utiliser Trim mais cut adapt (sans passser par trim)

# https://cutadapt.readthedocs.io/en/stable/installation.html
'''
conda config --add channels bioconda
conda config --add channels conda-forge
conda config --set channel_priority strict
'''

'''
conda create -n cutadapt cutadapt
'''

'''
conda activate cutadapt
'''

'''
cutadapt --version
'''
#4.9

# ça marche du coup je vais faire avec la bonne version de l'article, version 1.11



# test
# alors pour cutadapt il faut spécifier les adapter
# Faut que HEURESEMENT, les chercheurs ont pensée à nous et ont enlever les adapter comme dit dans l'article

'''
cutadapt -a
'''

# faire refait un def singularity avec les commandes précédentes
# + un conda update pour être à jour sur conda
'''
Bootstrap: docker
From: ubuntu:20.04


%post
    conda update -n base -c defaults conda -y
    conda config --add channels bioconda
    conda config --add channels conda-forge
    conda config --set channel_priority strict

    conda create -n cutadapt_env cutadapt=1.11 -y
    echo "source activate cutadapt_env" >> ~/.bashrc

%environment
    source activate cutadapt_env
%runscript
    exec cutadapt "$@"
'''

'''
sudo singularity build cutadapt_v1.11.sif Singularity.def
'''
# conda not found
# nice



# je vais faire les opérations manuellement

'''
sudo apt-get update && apt-get install -y wget
'''

# J'installe miniconda
'''
sudo bash /tmp/miniconda.sh -b -p /opt/conda
'''

'''
conda activate cutadapt_env
'''

'''
cutadapt --version
'''
# 1.11
# bien, du coup je l'intège dans mon def

'''
Bootstrap: docker
From: continuumio/miniconda3

%post
        # je met à jour conda au où
    conda update -n base -c defaults conda -y
        # commande tu tp
    conda config --add channels bioconda
    conda config --add channels conda-forge
    conda config --set channel_priority strict

# commande du tp mais je veux la bonne version
    conda create -n cutadapt_env cutadapt=1.11 -y

%environment

    export CONDA_DEFAULT_ENV=cutadapt_env
    export PATH="/opt/conda/envs/cutadapt_env/bin:$PATH"

%runscript
    # Exécuter Cutadapt
    exec cutadapt "$@"
'''

'''
sudo singularity build cutadapt_v1.11.sif Singularity.def
'''

'''cutadapt_env
singularity exec cutadapt_v1.11.sif cutadapt --version
'''
#1.11

'''
singularity exec cutadapt_v1.11.sif cutadapt --help
'''


# Pour utiliser cutadapt il me faut les séquence des adapter
# Selon ce forum : https://www.biostars.org/p/238517/#238530 il faut utiliser fastqc

'''
sudo apt install fastqc

fastqc --h
'''


'''
mkdir fastqc_results
fastqc -o fastqc_results -f fastq input.fastq
'''

################ VU QUE J'AI PAS LE TEMPS ############
# On va essayer avec la séquence de test du docu
# https://cutadapt.readthedocs.io/en/stable/guide.html

'''
singularity exec cutadapt_v1.11.sif cutadapt -a AACCGGTT -o cutadapt_file/file.fastq mini_data/mini_SRR10379721.fastq
'''

'''
ls -lrth cutadapt_file/
'''
total 4.8M
-rw-rw-r-- 1 ubuntu ubuntu 4.8M Oct 25 11:17 file.fastq
############### EXTRACTION GENOME REFERENCE ###########

# Via un code d'accession il serait possible de télécharger la séquence
# https://www.ncbi.nlm.nih.gov/datasets/docs/v2/how-tos/genomes/download-genome/
# https://www.ncbi.nlm.nih.gov/datasets/docs/v2/download-and-install/

'''
conda create -n ncbi_datasets # faut valider y avant
conda activate ncbi_datasets
conda install -c conda-forge ncbi-datasets-cli
'''

# A présent on va télécharger la séquence de référence

'''
ncbi-datasets --help
#ncbi-datasets: command not found
'''

# on passe par linux

'''
curl -o datasets 'https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/v2/linux-amd64/datasets'
curl -o dataformat 'https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/v2/linux-amd64/dataformat'
chmod +x datasets dataformat
'''

#############################


# On refait tout à partir du trimming inclu


#############################

# Créer l'image cutadapt version 1.11 (article)
sudo singularity build cutadapt_v1.11.sif def_files/install_cutAdapt.def
	
# Tester si ça marche
singularity exec cutadapt_v1.11.sif cutadapt --version
# 1.11

# Maintenant que ça marche, on va via fastq tenté d'indentifier les séquences artificielles


##########################
#        Fastqc
##########################

sudo apt install fastqc
fastqc mini_data/*


mv mini_data/*zip fastqc/
mv mini_data/*html fastqc/

# faut décompresser les fichiers zip, je n'arrive étrangement pas avec gzip donc je vais voir les forums
# https://askubuntu.com/questions/86849/how-to-unzip-a-zip-file-from-the-terminal


sudo apt-get install unzip

for file in fastqc/*zip; do
	filename=$(basename "$file")
	unzip "$file"
	echo "$file décompréssé"
done

# Bien, on a plein de nouveaux dossiers, je vais les déplacer dans "fastqc"

# Je regarde les résultats pour une seule séquence 
more fastqc/mini_SRR10379721_fastqc/fastqc_data.txt

#>>Overrepresented sequences     warn
#Sequence       Count   Percentage      Possible Source
#TGTTTATCACTTTTCATGATGCGAAACCTATCGATAAACTACACACGTAGAAAGATGTGTATCAG       1900.76     No Hit
#ATGCCCGAAGGTTATGTACAGGAACGCACTATATCTTTCAAAGATGACGGGAACTACAAGACGCG       67 0.268    No Hit
#AGCGTGACCACATGGTCCTTCTTGAGTTTGTAACTGCTGCTGGGATTACACATGGCATGGATGAG       66 0.264    No Hit
#GCCCGAAGGTTATGTACAGGAACGCACTATATCTTTCAAAGATGACGGGAACTACAAGACGCGTG       64 0.256    No Hit
#AATAACTGCAGTTAAGCCGAATTCGGCTTACGCGTCGACTAGGGAGGTTTTAAACATGATTAAAG       60 0.24     No Hit
#AGGAGTGATTTCAATGGCACAAGATATCATTTCAACAATCGGTGACTTAGTAAAATGGATTATCG       57 0.22799999999999998      No Hit

# On observe que la première séquence ici est présente 1900 fois, ce qui est bien plus élevé que les autres séquences présentent 60 fois maximum


# Pour ajouter du poids sur la théorie que cette séquence serait une séquence artificielle, nous allons faire un blast contre cette séquence pour voir si elle est présente chez d'autres.
# TGTTTATCACTTTTCATGATGCGAAACCTATCGATAAACTACACACGTAGAAAGATGTGTATCAG

# blast via nr
# la séquence est présentes chez staphylocoques, possiblement naturellement
# Pour l'instant on va se dire qu'il s'agit de la séquence artificielle

# On va voir chez une autres séquences
more fastqc/mini_SRR10379722_fastqc/fastqc_data.txt

# On a également des séquences sureprésenté tel que 
# AATAACTGCAGTTAAGCCGAATTCGGCTTACGCGTCGACTAGGGAGGTTTTAAACATGATTAAAG présente 1190 fois
# Peut-être qu'il s'agissent toute de séquences artificielles ? faudra-t-il toute les trimmer ?


# En lisant la listes des séquencess dites sureprésentées, j'observe que pour cette deuxième séquence : 
>>Overrepresented sequences     warn
#Sequence       Count   Percentage      Possible Source
#AATAACTGCAGTTAAGCCGAATTCGGCTTACGCGTCGACTAGGGAGGTTTTAAACATGATTAAAG       1190.47600000000000003      No Hit
#TGTTTATCACTTTTCATGATGCGAAACCTATCGATAAACTACACACGTAGAAAGATGTGTATCAG       88 0.35200000000000004      No Hit
#AGCGTGACCACATGGTCCTTCTTGAGTTTGTAACTGCTGCTGGGATTACACATGGCATGGATGAG       82 0.328    No Hit
#ACTTTTTCAAGAGTGCCATGCCCGAAGGTTATGTACAGGAACGCACTATATCTTTCAAAGATGAC       74 0.296    No Hit
#GGTGATGCAACATACGGAAAACTTACCCTTAAATTTATTTGCACTACTGGAAAACTACCTGTTCC       73 0.292    No Hit
#GCCAACTTACTTCTGACAACGATCGGAGGACCGAAGGAGCTAACCGCTTTTTTGCACAACATGGG       68 0.272    No Hit
#TCGCACTAACATCTAAGAATCAACATCAAGTATTATATTAACATCATAGATAACTTCATCAAGAC       62 0.248    No Hit
#ATGCCCGAAGGTTATGTACAGGAACGCACTATATCTTTCAAAGATGACGGGAACTACAAGACGCG       61 0.244    No Hit
#ACAGGGCACCCACCTGTATATAACAGGCCGAATGATCAAGCTATTATAACTACGGCAATACGGAC       60 0.24     No Hit
#ATGGCATGGATGAGCTCTACAAATAACTGCAGTTAAGCCGAATTCGGCTTACGCGTCGACTAGGG       58 0.232    No Hit
#GCCCGAAGGTTATGTACAGGAACGCACTATATCTTTCAAAGATGACGGGAACTACAAGACGCGTG       51 0.20400000000000001      No Hit
#GTATTTTTGCGAAGTCTGCCCAAAGCACGTAGTGTTTGAAGATTTCGGTCCTATGCAATATGAAC       50 0.2      No Hit

# La deuxième séquence sureprésenté ici est idententique à la première de la séquence précédente, cela est possible puisqu'il s'agit de la même espèce, mais peut-être que toutes les séquences ici sont des adapters, en tout cas c'est soit oui pour tous, soit non pour tous.

# Pour la 3ème séquences :
more fastqc/mini_SRR10379723_fastqc/fastqc_data.txt

>>Overrepresented sequences     warn
#Sequence       Count   Percentage      Possible Source
#TGTTTATCACTTTTCATGATGCGAAACCTATCGATAAACTACACACGTAGAAAGATGTGTATCAG       1460.584    No Hit
#AATAACTGCAGTTAAGCCGAATTCGGCTTACGCGTCGACTAGGGAGGTTTTAAACATGATTAAAG       1160.464    No Hit
#ATGCCCGAAGGTTATGTACAGGAACGCACTATATCTTTCAAAGATGACGGGAACTACAAGACGCG       1040.416    No Hit
#GCCAACTTACTTCTGACAACGATCGGAGGACCGAAGGAGCTAACCGCTTTTTTGCACAACATGGG       1010.404    No Hit
#AGCGTGACCACATGGTCCTTCTTGAGTTTGTAACTGCTGCTGGGATTACACATGGCATGGATGAG       98 0.392    No Hit
#GCCCGAAGGTTATGTACAGGAACGCACTATATCTTTCAAAGATGACGGGAACTACAAGACGCGTG       97 0.388    No Hit
#ACTTTTTCAAGAGTGCCATGCCCGAAGGTTATGTACAGGAACGCACTATATCTTTCAAAGATGAC       76 0.304    No Hit
#TCGGACACAAACTCGAGTACAACCATAACTCACACAATGTATACATCACGGCAGACAAACAAAAG       71 0.28400000000000003      No Hit
#ATGGCATGGATGAGCTCTACAAATAACTGCAGTTAAGCCGAATTCGGCTTACGCGTCGACTAGGG       67 0.268    No Hit
#GAGTTTGTAACTGCTGCTGGGATTACACATGGCATGGATGAGCTCTACAAATAACTGCAGTTAAG       64 0.256    No Hit
#TCGCACTAACATCTAAGAATCAACATCAAGTATTATATTAACATCATAGATAACTTCATCAAGAC       54 0.216    No Hit
#TTAAAGGAGAAGAACTTTTCACTGGAGTTGTCCCAATTCTTGTTGAATTAGATGGTGATGTTAAT       54 0.216    No Hit
#TTTACCAGACAACCATTACCTGTCGACACAATCTGCCCTTTCGAAAGATCCCAACGAAAAGCGTG       53 0.212    No Hit
#GGATTGTTAAGGGTTCCGAGGCTCAACGTCAATAAAGCAATTGGAATAAAGAAGCGAAAAAGGAG       49 0.196    No Hit

# On a plusieurs séquences qui sont présentent plus de 1000 fois dont les deux qui étaient premières pour 21 et 22.

# Pour la 4ème séquence : c'est TGTTTATCACTTTTCATGATGCGAAACCTATCGATAAACTACACACGTAGAAAGATGTGTATCAG qui est la seul présente plus de 100 fois avec une présence de 2040 fois.
# Pour la 5ème séquence
more fastqc/mini_SRR10379725_fastqc/fastqc_data.txt
# On a TGTTTATCACT.. qui est la plus présente, mais accompagné d'autres séquences, 
# et la séquence qui était la plus (et la seule) présente pour la seq 22 n'est pas présente ici.

 
# Bon, il semblerait qui y a plusieurs séqeunces adaptateurs différentes pour toute nos séquences étudiée, donc je vais devoir toute les enlever, j'espère que cutadapt peut me prendre une liste de séqunece à enelver.

# Ok je crois qu'avec -a on peut également mettre un fichier selon leur site web de la docu

# Je fais faire une liste de toute les séquences sureprésentés présentent au moins 50 fois

# nano ADAPTERS.txt
	
# Selon la docu, chaque séquence doit être précédé d'un ">..."
# Afin de formater le fichier txt et enlevé les doublons, j'utilise l'IA Claud pour formater le fichier.
# Voici le prompt que j'ai utiliser en mettant en pièce jointe mon fichier ADAPTERS.txt

###################################################################
#voici mon fichier, je veux que avant chaque séquence du mette un ">adapter1[X]" où [X] est un nombre. Et je veux que tu enlèves les doublons.
#voici ce que je veux en exemple : 
#fdsfdsfsd
#fsdfezrez
#zerzrzzrz
#
#devient 
#
#>adapter1
#fdsfdsfsd
#>adapter2
#fsdfezrez
#>adapter3
#zerzrzzrz
####################################################################

# J'obtients un fichier formaté par Claud et je vérifie si les séquences on bien était écrites, pour cela je vérifie via ctr+f sur vscode les séquences de l'IA sont bien les mêmes que les séquences initiales.

# Les séquences sont identiques (j'ai vérifier pour les 10 premières séquences avec succès)

# le fichier fomarté et le fichier non formaté sont présentent dans le dossier fastqc

###############################################################

#                    TRIMMING

###############################################################

# Selon la docu, je dois faire cette commande

# cutadapt -a file:adapters.fasta -o output.fastq input.fastq

# singularity exec cutadapt_v1.11.sif cutadapt -a file:fastqc/formated_ADAPTERS.fasta -o trimming/output.fastq.gz  mini_data/mini_SRR10379721.fastq.gz
je vais  faire encore une boucle pour le faire avec chaque

./trimming.sh

# Le script fait le trim pour tous et déponse dans le dossier trimming
