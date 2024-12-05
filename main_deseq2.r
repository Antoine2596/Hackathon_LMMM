if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install("EnrichmentBrowser")

if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install("DESeq2")

install.packages("readxl")

# BiocManager::install("org.Hs.eg.db")
# BiocManager::install("AnnotationDbi")

#Chargement des librairies
library("DESeq2")
library("EnrichmentBrowser")
library("readxl")

# library("AnnotationDbi")
# library("org.Hs.eg.db")

#chemin absolu d'accès au répertoire du dossier des feature_counts --> A MODIFIER ! 
path <- "C:/Users/Melo/Downloads/"

#chemin absolu du dossier feature_counts --> NOM A MODIFIER !
data_dir <- paste(path,"featureCounts_files_10M", sep = "")

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

View(counts(dds))

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
kegg_translation <- KEGGREST::keggGet(
  c("sao03010","sao00970")
  )
#ajouter à la main "SAOUHSC_01203", "K03685" selon un collègue de promo
#il manque peut-être aussi le code sao03012
#kegg_sao03012 <- KEGGREST::keggGet("sao03012")

#permet de lister les identifiants des gènes de translation
gene_ids <- unique(unlist(lapply(kegg_translation, function(x) x$GENE)))

#filtrage sur le dataframe "res" à partir des id de gènes de translation
res_filtered <- res[rownames(res) %in% gene_ids,]

#fichier excel contenant les noms des gènes et s'ils sont t-RNA synthetase
#Source : https://aureowiki.med.uni-greifswald.de/download_gene_specific_information
gene_name_file_name = "GeneSpecificInformation_NCTC8325.xlsx"

#Chargement du fichier excel
genes_name_file <- read_excel(
  paste(path,gene_name_file_name, sep = ""))

#Ici, il faudrait réussir à intégrer une colonne avec le nom des gènes dans le dataframe "res"
#mais je galère un peu....c'est ici Antoine que tu peux m'aider stp ?
# Ci-dessous j'ai essayé la fonction "merge" par exemple, ça pourrait t'aider peut-être ? 

res_final <- merge(
  res_filtered, 
  genes_name_file, 
  by = )

#Affichage de la figure 3 supp
library(ggplot2)

ggplot(res_filtered, aes(x = log_baseMean, y = log2FoldChange)) +
  geom_point() +  # Ajouter des points
  labs(x = "baseMean", y = "log2FoldChange") +  # Ajouter des labels aux axes
  theme_minimal() +  # Appliquer un thème minimal
  ggtitle("Graphique de baseMean vs log2FoldChange") # Ajouter un titre au graphique



#------------------------------- à partir d'ici, c'est de l'ancien code ----------------------
# limma::plotMA(logNormalizedCounts)
# abline(h=0)
# dev.off()

#Download gene names + pathways
# browseVignettes("EnrichmentBrowser")
# kegg.gs <- getGenesets(org = "sao", db = "kegg")
# length(kegg.gs)
# kegg.gs["$sao05150_Staphylococcus_aureus_infection"]

# sbea.res <- sbea(method = "ora", se = res, gs = kegg.gs, perm = 0, alpha = 0.05) 
# gsRanking(sbea.res)

# aureus <- downloadPathways(
#     org = "hsa",
#     cache = TRUE,
#     out.dir = NULL,
#     zip = FALSE)