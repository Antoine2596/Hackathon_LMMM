#Vérification de la présence des bonnes librairies sinon installation 
if (!require("BiocManager", quietly = TRUE)){
   install.packages("BiocManager", version = '1.30.25')}

if (!require("EnrichmentBrowser", quietly = TRUE)){
   install.packages("EnrichmentBrowser", version = '2.36.0')}

if (!require("DESeq2", quietly = TRUE)){
   install.packages("DESeq2", version = '1.16.0')}

if (!require("readxl", quietly = TRUE)){
   install.packages("readxl", version = '1.4.3')}

if (!require("tidyverse", quietly = TRUE)){
   install.packages("tidyverse")}

if (!require("ggplot2", quietly = TRUE)){
   install.packages("ggplot2", version = '3.5.1')}

if (!require("dplyr", quietly = TRUE)){
   install.packages("dplyr", version = '1.1.4')}

if (!require("ggrepel", quietly = TRUE)){
   install.packages("ggrepel", version = '0.9.6')}

#Chargement des librairies
library("EnrichmentBrowser")
library("DESeq2")
library("readxl")
library("tidyverse")
library("ggplot2")
library("dplyr")
library("ggrepel")

#chemin du répertoire du dossier 
path <- paste(getwd(),"/", sep = "")

#chemin du dossier des fichiers de comptage
data_dir <- paste(path,"featureCounts_files", sep = "")
print(data_dir)

#Sélection des fichiers feature_counts dans une liste
count_files <- list.files(
  data_dir, 
  pattern = "_count.txt$", 
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

## Vérifier que metadata et counts data correspondent
all(colnames(all_counts) %in% rownames(metadata))
all(colnames(all_counts) == rownames(metadata))

## Creation objet DESeq2Dataset
dds <- DESeqDataSetFromMatrix(countData = all_counts, 
                              colData = metadata, 
                              design = ~condition)


#Analyse différentielle d'expression
dds <- DESeq(dds)
res <- results(dds, alpha = 0.05) # alpha 0.05 par dépit

#Affichage de la figure 3 supp

#Création d'une image au format png
png(
  filename = paste(
    path,"results/Mean_of_normalized_counts_log_fold_change.png"))

#Affichage
plotMA(
  object = res,
  colSig = "red",
  colNonSig = "black"
 )

#Fin des modifications de l'image et enregistrement
dev.off()
    
# Récupération des informations générales sur les gènes de traduction depuis KEGG
# Source : https://www.genome.jp/kegg-bin/get_htext?sao00001.keg
kegg_translation <- KEGGREST::keggGet(
  c("sao03010", "sao00970", "sao03013", "sao03015", "sao03008")
)

#Récupération des identifiants des facteurs de translations
#Source "sao03012.keg" : https://www.genome.jp/kegg-bin/download_htext?htext=sao03012
factor_translation <- read.table("sao03012.keg", sep = ";")

# Convertir les identifiants des facteurs de translation en dataframe
factor_translation_df <- data.frame(
  V1 = factor_translation, stringsAsFactors = FALSE)

# Extraire les identifiants débutant par SAOUHSC_..
identifiants <- str_extract_all(factor_translation_df$V1, "\\bSAOUHSC_\\d+\\b")

# Afficher les noms de gènes extraits
factor_translation_gene_name <- unlist(identifiants)

# Extraire les identifiants des gènes (généralement dans la clé 'GENE' de chaque élément)
gene_ids <- unique(unlist(lapply(kegg_translation, function(x) x$GENE)))

#Fusion des 2 listes : factor_translation_gene_name et gene_ids
genes_translation_final <- c(factor_translation_gene_name, gene_ids)

# Vérification des identifiants des gènes extraits
head(genes_translation_final)

#Lecture du fichier de correspondance entre nom de gènes et leur symbole
#Source : https://aureowiki.med.uni-greifswald.de/download_gene_specific_information
genes_name_file  <- read_excel(
  "GeneSpecificInformation_NCTC8325.xlsx")

head(genes_name_file)

#Filtrage des gènes traduits
res_filtered <- res[rownames(res) %in% genes_translation_final, ]

# Vérification du résultat
head(res_filtered)

# Convertir "res_filtered" en dataframe
res_filtered_df <- as.data.frame(res_filtered)

# Correspondance entre noms de gène et leur symbol et la présence de ARN synthétase
res_final <- merge(
  res_filtered_df, 
  genes_name_file, 
  by.x = "row.names", 
  by.y = "locus tag", 
  all.x = TRUE)

# Vérification du résultat après la fusion
head(res_final)

# Liste des gènes à annoter
genes_to_label <- c("frr", "infA", "tsf", "infC", "infB", "pth")

#Création de l'attribut "true_symbol"
res_final <- res_final %>%
  mutate(true_symbol = ifelse(res_final$symbol %in% genes_to_label, TRUE, FALSE))

#Trouver les gènes qui ont le RNA synthetase
RNA_synthetase <- c(grep('tRNA synthetase',res_final$product))

#Création attribut "is_RNA_synthetase"
res_final <- res_final %>% mutate(
  is_RNA_synthetase = row_number() %in% RNA_synthetase)

#Création attribut "log2_baseMean"
res_final$log2_baseMean <- log2(res_final$baseMean + 1) # Ajouter 1 pour éviter les problèmes avec les valeurs nulles
dim(res_final)

#Création attribut "significance"
res_final <- res_final %>%
  mutate(significance = ifelse(padj < 0.05, "Significant", "Non-significant"))

#Affichage de la figure 3c
png(
  filename = paste(
    path,"log_base_mean_log_fold_change_final.png"))

# Créer le graphique avec le log2(baseMean) sur l'axe X
ggplot(res_final, aes(x = log2_baseMean, y = log2FoldChange)) + 
  # Couche pour les points "is_RNA_synthetase" (avec contour noir)
  geom_point(
    aes(shape = is_RNA_synthetase),
    data = res_final %>% filter(is_RNA_synthetase),  # Filtrer seulement les RNA synthetase
    shape = 21,          # Cercle avec contour
    size = 3,            # Taille du point avec contour
    color = "black",     # Contour noir
    fill = "#FFFFFF00",        # Remplissage des points RNA synthetase (peut être ajusté)
    stroke = 1.2    # Épaisseur du contour
  ) +
  # Couche pour tous les points (sans contour spécifique)
  geom_point(aes(color = significance, shape = is_RNA_synthetase), size = 3) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  scale_color_manual(
    values = c("Significant" = "red", "Non-significant" = "grey"), # Couleurs des points
    name = "Significance") +  
  scale_shape_manual(
    values = c("TRUE" = 21, "FALSE" = 19),  # Différencier RNA synthetase (21) et autres (19)
    name = "RNA Synthetase"  # Légende pour les points avec/without RNA synthetase
  ) +
    geom_text_repel( #fonction qui gère les lignes noires entre les symboles annotés et les points correspondants
      data = res_final %>% filter(true_symbol == TRUE), 
      aes(x=log2_baseMean, y=log2FoldChange, label=symbol), 
      show.legend=FALSE, 
      size=3, 
      box.padding=4, 
      max.overlaps=2000)
   +
  labs(
    x = "Log₂ base Mean", # Modifier l'étiquette de l'axe Y
    y = "Log₂ Fold Change") +  # Modifier l'étiquette de l'axe X
  theme_minimal() + # Appliquer un thème minimal
  scale_y_continuous(
    breaks = seq(-6, 6, 1),  # Intervalles des graduations
    limits = c(-6, 6)        # Limites des ordonnées
  ) +
  scale_x_continuous(
    breaks = seq(4, 18, 2),  # Intervalles des graduations
    limits = c(4, 18)        # Limites des abscisses
  )

#Fin de la modification de l'image
dev.off()

#Affichage du PCA plot
png(
  filename = paste(
    path,"PCA_plot.png"))

#PCA plot
rld <- rlog(dds) #normalisation (stabilisation de la variance)
plotPCA(rld)

dev.off()

#Affichage de Volcano plot

# Création d'un attribut "Expression" qui différencie les gènes comme "up-regulated", "down-regulated", or "unchanged"
res_final <- res_final %>%
  mutate( 
  Expression = case_when(log2FoldChange >= log(1) & padj <= 0.05 ~ "Up-regulated",
  log2FoldChange <= -log(1) & padj <= 0.05 ~ "Down-regulated",
  TRUE ~ "Unchanged")
  )

#Création du graphique volcano plot
volcano_plot_final <- ggplot(res_final, aes(log2FoldChange, -log(pvalue,10))) + # -log10 conversion
geom_point(aes(color = Expression), size = 2/5) +
xlab(expression("log"[2]*"FC")) +
ylab(expression("-log"[10]*"P-Value")) +
scale_color_manual(values = c("dodgerblue3", "black", "firebrick3")) +
xlim(-4.5, 4.5) +
geom_text_repel(aes(label = res_final$Expression), size = 2.5)

png(
  filename = paste(
    path,"volcano_plot_v1.png"))

volcano_plot_final

dev.off()