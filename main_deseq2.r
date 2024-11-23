if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install("EnrichmentBrowser")

if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install("DESeq2")

BiocManager::install("org.Hs.eg.db")
BiocManager::install("KEGGREST")
BiocManager::install("AnnotationDbi")

#Chargement des librairies
library("DESeq2")
library("EnrichmentBrowser")
library("KEGGREST")
library("AnnotationDbi")
library("org.Hs.eg.db")


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
  rownames(count_data) <- count_data$Geneid
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

#Affichage du résultat mean (fig 3 supp)
png(
  filename = paste(
    path,"Mean_of_normalized_counts_log_fold_change_2.png"),
    width = 1080, 
    height = 1080)

plotMA(
  object = res,
  colSig = "red",
  colNonSig = "black"
 )

dev.off()

png(
  filename = paste(
    path,"test_log_normalized_counts_log_fold_change.png"),
    width = 1080, 
    height = 1080)
    
#Affichage du résultat log (fig 3) --> ICI QUE CA COINCE !!

# # Conversion des IDs de gènes vers KEGG
# entrez_ids <- mapIds(
#   org.Hs.eg.db, 
#   keys = rownames(res), 
#   column = "ENSEMBL", 
#   keytype = "SYMBOL", 
#   multiVals = "first")

# # Obtenir les annotations KEGG
# kegg_annotations <- keggGet(paste0("sau:", rownames(res)))

# limma::plotMA(logNormalizedCounts)
# abline(h=0)
# dev.off()

#Download gene names + pathways
browseVignettes("EnrichmentBrowser")
kegg.gs <- getGenesets(org = "hsa", db = "kegg")
length(kegg.gs)
length(kegg.gs["hsa05150_Staphylococcus_aureus_infection"])

sbea.res <- sbea(method = "ora", se = res, gs = kegg.gs, perm = 0, alpha = 0.05) 
gsRanking(sbea.res)

# aureus <- downloadPathways(
#     org = "hsa",
#     cache = TRUE,
#     out.dir = NULL,
#     zip = FALSE)