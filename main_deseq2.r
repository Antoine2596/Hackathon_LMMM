if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install("EnrichmentBrowser")

if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install("DESeq2")

library("DESeq2")
library("EnrichmentBrowser")

path <- "C:/Users/Melo/Downloads/"

data_dir <- paste(path,"featureCounts_files", sep = "")

count_files <- list.files(
  data_dir, 
  pattern = "_counts.txt$", 
  full.names = TRUE)

read_count_file <- function(file) {
  count_data <- read.table(
    file, header = TRUE, 
    stringsAsFactors = FALSE, 
    comment.char = "#")
  rownames(count_data) <- count_data$Geneid
  count_data <- count_data[, ncol(count_data)]
  return(count_data)
}

all_counts <- do.call(cbind, lapply(count_files, read_count_file))
colnames(all_counts) <- gsub("_counts.txt", "", basename(count_files))

conditions <- factor(rep(
  c(
    "persister",
    "control"),
    each = 3
    ))

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

#Normalization factor applied to each sample
sizeFactors(dds)

#Normalized counts matrix
normalized_counts <- counts(dds, normalized=TRUE)

View(normalized_counts)

# res <- results(dds, alpha = 0.05) # alpha 0.05 par dépit
# plotMA(res)

# browseVignettes("EnrichmentBrowser")

# kegg.gs <- getGenesets(org = "hsa", db = "kegg")


# aureus <- downloadPathways(
#     org = "sao",
#     cache = TRUE,
#     out.dir = NULL,
#     zip = FALSE)

