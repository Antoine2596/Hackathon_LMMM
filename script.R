# Installer BiocManager si nécessaire
if (!require("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

# Forcer la réinstallation de Bioconductor version 3.5 en rétrogradant les packages
# Cette commande rétrograde les packages nécessaires pour utiliser Bioconductor 3.5 avec R 3.4.1
BiocManager::install(version = "3.5", ask = FALSE, force = TRUE)

# Vérifier si les packages nécessaires sont installés ou les réinstaller
# Cette étape permet d'assurer que les dépendances de Bioconductor sont correctes
BiocManager::install(c("Biobase", "BiocGenerics", "DelayedArray", "GenomeInfoDb",
                       "GenomicRanges", "IRanges", "S4Vectors", "SummarizedExperiment",
                       "XVector", "zlibbioc", "GenomeInfoDbData"), ask = FALSE, force = TRUE)

# Installer DESeq2 version 1.16
# Installer la version spécifiée de DESeq2
BiocManager::install("DESeq2", version = "1.16", ask = FALSE)

# Vérifier la version installée de DESeq2 pour confirmation
cat("Version de DESeq2 installée : ", packageVersion("DESeq2"), "\n")

# Vous pouvez également vérifier les autres packages installés
cat("Version de BiocManager installée : ", packageVersion("BiocManager"), "\n")
