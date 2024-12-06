# **RNA-Seq Analysis Pipeline with Snakemake**



## **Description**
Ce projet implémente un pipeline RNA-Seq pour l’analyse de données de séquençage à l’aide de **Snakemake**.  
L'objectif est de reproduire une partie de l'analyse décrite dans un article scientifique, incluant les étapes suivantes :  
- Téléchargement des fichiers FastQ.  
- Alignement des lectures sur un génome de référence.  
- Comptage des lectures par gène.  
- Analyse statistique de l’expression différentielle.  
- Génération de visualisations avec DESeq2.  

## **But du Snakemake**
Snakemake permet :  
- D’automatiser l'exécution des différentes étapes du pipeline.  
- De gérer les dépendances entre étapes.  
- De garantir une exécution reproductible et optimisée.  

## **Inputs et Outputs**
### **Inputs**
Le pipeline prend en entrée :  
- Un fichier de métadonnées pour décrire les échantillons et les conditions (par exemple, `samples.csv`).  
- Les **identifiants SRA** ou les fichiers **FastQ bruts**.  

### **Outputs**
Le pipeline produit :  
1. Fichiers d’alignement : fichiers **BAM** alignés et triés.  
2. Fichiers de comptage des lectures par gène : tables de comptage au format **TSV**.  
3. Résultats d’analyse statistique :  
   - Liste des gènes différentiellement exprimés.  
   - Graphiques (volcano plot, heatmap, etc.).  

---

## **Structure du Projet**
- **Snakefile** : Définit toutes les étapes du pipeline.  
- **config.yaml** : Contient les chemins des fichiers d'entrée et des paramètres pour le pipeline.  
- **rules/** : Répertoire contenant les règles individuelles du pipeline (ex. `alignment.smk`, `counting.smk`).  
- **envs/** : Fichiers de spécifications des environnements conda nécessaires.  
- **Singularity/Docker** : Fichiers de recette pour la création des conteneurs.  

---

## **Installation**
### **Prérequis**
- **Python** ≥ 3.7  
- **Snakemake** ≥ 7.0  
- Conteneurs **Docker** ou **Singularity** (selon votre environnement)  
- Outils bioinformatiques nécessaires (Bowtie, Samtools, FeatureCounts, R avec DESeq2)  

