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
