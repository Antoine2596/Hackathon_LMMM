#if (!require("BiocManager", quietly = TRUE))
#    install.packages("BiocManager")

#BiocManager::install("EnrichmentBrowser")


#BiocManager::install("DESeq2")

#install.packages("readxl")

# BiocManager::install("org.Hs.eg.db")
# BiocManager::install("AnnotationDbi")

#Chargement des librairies
library("DESeq2")
library("EnrichmentBrowser")
library("readxl")
library(readxl)

# library("AnnotationDbi")
# library("org.Hs.eg.db")

#chemin absolu d'accès au répertoire du dossier des feature_counts --> A MODIFIER ! 
#path <- "C:/Users/Melo/Downloads/"
path <- paste(getwd(),"/", sep = "")
#chemin absolu du dossier feature_counts --> NOM A MODIFIER !
data_dir <- paste(path,"featureCounts_files", sep = "")
print(data_dir)
#Sélection des fichiers feature_counts dans une liste
count_files <- list.files(
  data_dir, 
  pattern = "_counts.txt$", 
  full.names = TRUE)

#Fonction permettant de lire et charger les fichiers feature_counts
read_count_file <- function(file) {
  count_data <- read.table(
    file, 
    header = TRUE, 
    stringsAsFactors = FALSE,
    comment.char = "#", 
    sep = "\t")
  # Supprimer le substring "gene-" des valeurs de "Geneid"
  count_data$Geneid <- gsub("gene-", "", count_data$Geneid)
  # Affecter "Geneid" comme noms des lignes
  rownames(count_data) <- count_data$Geneid
  # Conserver uniquement la dernière colonne
  count_data <- count_data[, ncol(count_data), drop = FALSE]
  return(count_data)
}

#Application de la fonction sur les fichiers
all_counts <- do.call(cbind, lapply(count_files, read_count_file))

#Remplacement des colonnes par le nom de chacun des échantillons
colnames(all_counts) <- gsub("_counts.txt", "", basename(count_files))

#Construction de la liste des conditions
conditions <- factor(rep(
  c(
    "persister",
    "control"),
    each = 3
    ))

#Construction du dataframe associant chaque échantillon à sa condition (persister ou control)
metadata <- data.frame(
  sample = colnames(all_counts),
  condition = conditions, 
  row.names = colnames(all_counts)
)

## Check that match metadata and counts data
all(colnames(all_counts) %in% rownames(metadata))
all(colnames(all_counts) == rownames(metadata))

## Create DESeq2Dataset object
dds <- DESeqDataSetFromMatrix(countData = all_counts, 
                              colData = metadata, 
                              design = ~condition)


#Perform median of ratios method of normalization
dds <- DESeq(dds)
res <- results(dds, alpha = 0.05) # alpha 0.05 par dépit

#Affichage du résultat mean (FIG 3 SUPP)
png(
  filename = paste(
    path,"Mean_of_normalized_counts_log_fold_change.png"),
    width = 1080, 
    height = 1080)

plotMA(
  object = res,
  colSig = "red",
  colNonSig = "black"
 )

dev.off()
    
#Affichage du résultat log (FIG 3)

#On obtient les informations générales sur les gènes de translation (mais il en manque, voir commentaires ci-dessous)
# Source : https://www.genome.jp/kegg-bin/get_htext?sao00001.keg
# Étape 1 : Récupération des informations générales sur les gènes de traduction depuis KEGG
kegg_translation <- KEGGREST::keggGet(
  c("sao03010", "sao00970")
)

#ajouter à la main "SAOUHSC_01203", "K03685" selon un collègue de promo
#il manque peut-être aussi le code sao03012
#kegg_sao03012 <- KEGGREST::keggGet("sao03012")

############################# Antoine ######################"
# Le problème était au dessus de ce que tu pensais
# Les données étaient mal formatées, il fallait les nettoyer
# Tu peux supprimer mes annotations si dessus une fois que tu as lu y compris le "#####....#"

# Extraire les identifiants des gènes (généralement dans la clé 'GENE' de chaque élément)
gene_ids <- unique(unlist(lapply(kegg_translation, function(x) x$GENE)))



genes_name_file  <- read_excel("GeneSpecificInformation_NCTC8325.xlsx")
head(genes_name_file)


# Vérification des identifiants des gènes extraits
head(gene_ids)


# Nettoyer les identifiants des gènes pour garder uniquement le nom du gène
# On utilise une expression régulière pour enlever tout ce qui suit un point-virgule ou les crochets

gene_ids_clean <- gsub(";.*", "", gene_ids)  # Retirer ce qui suit un point-virgule
gene_ids_clean <- gsub("\\[.*\\]", "", gene_ids_clean)  # Retirer ce qui est entre crochets

# Affichage des premiers identifiants nettoyés
head(gene_ids_clean)


# Filtrage du dataframe "res" pour ne conserver que les lignes correspondant aux gènes nettoyés
res_filtered <- res[rownames(res) %in% gene_ids_clean, ]

# Vérification du résultat
head(res_filtered)


# Convertir "res_filtered" en dataframe
res_filtered_df <- as.data.frame(res_filtered)

# Fusionner "res_filtered_df" avec "genes_name_file" en utilisant "row.names(res_filtered_df)" et "locus tag"
res_final <- merge(res_filtered_df, genes_name_file, by.x = "row.names", by.y = "locus tag", all.x = TRUE)

# Vérification du résultat après la fusion
head(res_final)

library(ggplot2)
library(ggplot2)

# Ajouter une nouvelle colonne avec la transformation log2 de baseMean
res_final$log2_baseMean <- log2(res_final$baseMean + 1)  # Ajouter 1 pour éviter les problèmes avec les valeurs nulles

# Créer le graphique avec le log2(baseMean) sur l'axe X
ggplot(res_final, aes(x = log2_baseMean, y = log2FoldChange)) + 
  geom_point() +  # Ajouter des points
  labs(x = "Log2 base Mean", y = "log2FoldChange") +  # Modifier l'étiquette de l'axe X
  theme_minimal() +  # Appliquer un thème minimal
  ggtitle("Graphique de Log2 baseMean vs log2FoldChange")  # Ajouter un titre au graphique

########################################
