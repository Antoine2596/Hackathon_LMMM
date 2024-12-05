#Vérification de la présence des bonnes librairies sinon installation 
if (!require("BiocManager", quietly = TRUE)){
   install.packages("BiocManager", version = '1.30.25')}

if (!require("EnrichmentBrowser", quietly = TRUE)){
   install.packages("EnrichmentBrowser", version = '2.36.0')}

if (!require("DESeq2", quietly = TRUE)){
   install.packages("DESeq2", version = '1.46.0')}

if (!require("readxl", quietly = TRUE)){
   install.packages("readxl", version = '1.4.3')}

if (!require("tidyverse", quietly = TRUE)){
   install.packages("tidyverse")}

if (!require("ggplot2", quietly = TRUE)){
   install.packages("ggplot2", version = '3.5.1')}

if (!require("dplyr", quietly = TRUE)){
   install.packages("dplyr", version = '1.1.4')}

if (!require("ggrepel", quietly = TRUE)){
   install.packages("ggrepel")}

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
data_dir <- paste(path,"featureCounts_files/", sep = "")
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

# Extraire les identifiants des gènes (généralement dans la clé 'GENE' de chaque élément)
gene_ids <- unique(unlist(lapply(kegg_translation, function(x) x$GENE)))

# Vérification des identifiants des gènes extraits
head(gene_ids)

genes_name_file  <- read_excel(
  "GeneSpecificInformation_NCTC8325.xlsx")
head(genes_name_file)

################### JE CROIS QUE CELA N'EST PAS NÉCESSAIRE #######################
# Nettoyer les identifiants des gènes pour garder uniquement le nom du gène
# On utilise une expression régulière pour enlever tout ce qui suit un point-virgule ou les crochets
# gene_ids_clean <- gsub(";.*", "", gene_ids)  # Retirer ce qui suit un point-virgule
# gene_ids_clean <- gsub("\\[.*\\]", "", gene_ids_clean)  # Retirer ce qui est entre crochets

# Affichage des premiers identifiants nettoyés
# head(gene_ids_clean)
##################################################################################

# Filtrage du dataframe "res" pour ne conserver que les lignes correspondant aux gènes nettoyés
res_filtered <- res[rownames(res) %in% genes_name_file$`locus tag`, ]

# Vérification du résultat
head(res_filtered)

# Convertir "res_filtered" en dataframe
res_filtered_df <- as.data.frame(res_filtered)

# Fusionner "res_filtered_df" avec "genes_name_file" en utilisant "row.names(res_filtered_df)" et "locus tag"
res_final <- merge(res_filtered_df, genes_name_file, by.x = "row.names", by.y = "locus tag", all.x = TRUE)

# Vérification du résultat après la fusion
head(res_final)

# Ajouter une nouvelle colonne avec la transformation log2 de baseMean
res_final$log2_baseMean <- log2(res_final$baseMean + 1)  # Ajouter 1 pour éviter les problèmes avec les valeurs nulles

# Créer le graphique avec le log2(baseMean) sur l'axe X
ggplot(res_final, aes(x = log2_baseMean, y = log2FoldChange)) + 
  geom_point() +  # Ajouter des points
  labs(x = "Log2 base Mean", y = "log2FoldChange") +  # Modifier l'étiquette de l'axe X
  theme_minimal() +  # Appliquer un thème minimal
  ggtitle("Graphique de Log2 baseMean vs log2FoldChange") + # Ajouter un titre au graphique
  geom_text(aes(label = res_final$`symbol`), vjust = -1)

########################################

#PCA plot
rld <- rlog(dds)
plotPCA(rld)

#Volcano plots
# add an additional column that identifies a gene as unregulated, downregulated, or unchanged
# note the choice of pvalue and log2FoldChange cutoff. 
res_final <- res_final %>%
  mutate(
  Expression = case_when(log2FoldChange >= log(1) & padj <= 0.05 ~ "Up-regulated",
  log2FoldChange <= -log(1) & padj <= 0.05 ~ "Down-regulated",
  TRUE ~ "Unchanged")
  )

top <- 10
# we are getting the top 10 up and down regulated genes by filtering the column Up-regulated and Down-regulated and sorting by the adjusted p-value. 
top_genes <- bind_rows(
  res_final %>%
  filter(Expression == 'Up-regulated') %>%
  arrange(padj, desc(abs(log2FoldChange))) %>%
  head(top),
  res_final %>%
  filter(Expression == 'Down-regulated') %>%
  arrange(padj, desc(abs(log2FoldChange))) %>%
  head(top)
  )
# create a datframe just holding the top 10 genes
Top_Hits = head(arrange(res_final,pvalue),10)
Top_Hits

#Up/DOwn Regulated
volcano_plot_final <- ggplot(res_final, aes(log2FoldChange, -log(pvalue,10))) + # -log10 conversion
geom_point(aes(color = Expression), size = 2/5) +
# geom_hline(yintercept=-log10(0.05), linetype="dashed", linewidth = .4) +
xlab(expression("log"[2]*"FC")) +
ylab(expression("-log"[10]*"P-Value")) +
scale_color_manual(values = c("dodgerblue3", "black", "firebrick3")) +
xlim(-4.5, 4.5) +
geom_text_repel(aes(label = res_final$Expression), size = 2.5)

volcano_plot_final
