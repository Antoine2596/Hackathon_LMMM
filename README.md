# Introduction

Ce projet s'inscrit dans le cadre de l'UC Repro Hackathon du master AMI2B de l'Université Paris-Saclay. Il s'agit de s'approprier les notions de reproductibilité scientifique en reproduisant certaines figures obtenues par Peyrusson et al. dans "[Intracellular Staphylococcus aureus persisters upon antibiotic exposure](https://doi.org/10.1038/s41467-020-15966-7)".

# Prérequis

Afin d'obtenir les résultats, il est nécessaire de se placer dans une machine sous Ubuntu 20.04 sur lequel sont installés Snakemake (le pipeline a été développé pour snakemake 8.25.3) et Singularity-CE (la version Afin d'obtenir les résultats, il est nécessaire de se placer dans une machine sous Ubuntu 20.04 sur lequel sont installés Snakemake (le pipeline a été développé pour snakemake 8.25.3) et Singularity-CE (la version 4.2.0 a été utilisée). Il est également nécessaire de disposer d'au moins 4 threads et 14 gigaoctets de mémoire vive. Cloner le dépôt Github fournira tous les fichiers nécessaires à l'exécution, à savoir :

 - le snakefile contenant le pipeline
 - le script R permettant la création des images finales
 - un fichier de données génétiques en provenance de KEGG, dont le téléchargement ne se fait pas comme prévu dans le script (l'erreur venant du site)
 - un fichier d'information génétiques xlsx dont le site n'autorise pas un téléchargement direct sans passer par une interface utilisateur
 - un fichier run.sh permettant de lancer directement l'exécution du pipeline sans passer par la ligne de commande

Le dépôt contient également les recettes de création des conteneurs singularity utilisés dans le snakefile ; ceux-ci étant hébergés sur Zenodo et téléchargés à la volée, les recettes ne sont présente que pour pouvoir inspecter leur contenu.

# Exécution
Une fois snakemake activé, la commande pour lancer le pipeline est la suivante :

    snakemake --cores all --use-singularity
   Cela permet à snakemake d'utiliser tous les threads disponibles sur la machine. S'il la machine dispose d'au moins 24 coeurs, elle sera en mesure de lancer tous les jobs s'appliquant à une séquence d'ADN en parallèle.
   L'exécution du pipeline peut également s'effectuer en exécutant `run.sh` .
