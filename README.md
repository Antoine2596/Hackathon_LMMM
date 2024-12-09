# Introduction

Ce projet s'inscrit dans le cadre de l'Unité d'Enseignement ReproHackathon du master AMI2B de l'Université Paris-Saclay.  
Il vise à explorer les notions de reproductibilité scientifique en reproduisant certaines figures obtenues par Peyrusson et al. dans leur publication :  
["Intracellular Staphylococcus aureus persisters upon antibiotic exposure"](https://doi.org/10.1038/s41467-020-15966-7).

Le projet consiste en la création d'un pipeline bioinformatique reproductible permettant de répliquer les analyses décrites dans l'article.

---

# Prérequis

Pour exécuter le pipeline et reproduire les résultats, deux options sont disponibles :  

1. **Utiliser vos propres ressources** :  
   - Snakemake version **8.25.3**  
   - SingularityCE version **4.2.0** (ou Singularity 4.2.0)  
   - Git  
   - Conda  
   - La machine doit disposer d’au moins **4 threads** et **14 Go de mémoire vive**.

2. **Utiliser une machine virtuelle via Biosphère** :  
   - Sélectionnez l'appliance [BioPipes](https://biosphere.france-bioinformatique.fr/catalogue/appliance/119/) sous Ubuntu 22.04, qui inclut Snakemake (préconfiguré pour la version 8.25.3).  
   - Installez SingularityCE en suivant les instructions du [wiki d'installation](https://github.com/Antoine2596/Hackathon_LMMM/wiki/singularity%E2%80%90installation).  
   - Installez Git avec la commande suivante après connexion à la machine virtuelle :  
     ```
     sudo apt-get install git
     ```
   - Assurez-vous que la machine virtuelle dispose des ressources nécessaires : **au moins 4 threads et 14 Go de RAM**.

---

# Structure du répertoire GitHub

Ce dépôt contient :  
- **`Snakefile`** : le fichier décrivant le pipeline d'analyse.  
- **Script R** : utilisé pour la création des images finales à partir des résultats.  
- **Fichier KEGG** : fichier de données génétiques requis mais non téléchargeable directement via le script, en raison de restrictions côté serveur.  
- **Fichier `.xlsx`** : contient des informations génétiques, non téléchargeables automatiquement sans interaction manuelle avec l'interface du site.  
- **`run.sh`** : script bash pour lancer l'exécution automatique du pipeline.  
- **Recettes des conteneurs Singularity** : les fichiers de définition utilisés pour créer les conteneurs. Ces derniers sont hébergés sur Zenodo et téléchargés automatiquement par le pipeline.

---

# Exécution manuelle

Pour exécuter le pipeline :  

1. Clonez ce dépôt GitHub :  
   ```
   git clone git@github.com:Antoine2596/Hackathon_LMMM.git
   ```
2. Activez l'environnement conda de base :  
   ```
   conda activate
   ```

3. Lancez le pipeline avec la commande suivante :
   ```
   snakemake --cores all --use-singularity
   ```
Cette commande utilise tous les threads disponibles sur votre machine. Si votre machine dispose d’au moins 24 cœurs, elle pourra paralléliser les tâches pour traiter plusieurs séquences d'ADN en simultané.

> L'option --use-singularity permet d'exécuter chaque étape dans son conteneur dédié pour garantir la reproductibilité.

---

# Exécution automatique

Pour exécuter le pipeline de manière automatique :
1. Lancez le script `run.sh` :
   `./run.sh`
Ce script activera automatiquement conda avant d'exécuter le pipeline complet.

   
