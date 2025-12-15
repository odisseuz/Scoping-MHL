library(tidyverse)
library(bibliometrix)
library(revtools)
library(janitor)

#checking 
list.files("raws")
#moving the data to R
scopus_df <- convert2df(
  file="raws/scopus.bib",
  dbsource = "scopus",
  format = "bibtex"
)

wos_df <- convert2df(
  file = "raws/wos.bib", 
  dbsource = "wos",  
  format = "bibtex"
)
#had to use rev-tools or else it wouldn't work
eric_raw <- revtools::read_bibliography("raws/eric.bib")
#standardizing ERIC with others
eric_df <- eric_raw %>%
  dplyr::rename(
    TI = title,
    AU = author,
    PY = year,
    SO = journal, 
    AB = abstract 
  ) %>%
  mutate(
    DB = "ERIC",
    PY = as.numeric(PY),
    DT = if("type" %in% names(.)) type else "ARTICLE",
    TI = str_to_upper(TI),
    SO = str_to_upper(SO)
  )

#merging the tables
master_data <- mergeDbSources(
  scopus_df, wos_df, eric_df, 
  remove.duplicated = FALSE)

#checking 
nrow(master_data)
cat("Scopus:", nrow(scopus_df), "\n")
cat("WoS:", nrow(wos_df), "\n")
cat("ERIC:", nrow(eric_df), "\n")
soma_real <- nrow(scopus_df) + nrow(wos_df) + nrow(eric_df)
cat("Soma dos 3:", soma_real, "\n")
cat("Master Data:", nrow(master_data), "\n")

#normalizing data
names(master_data)
master_data <- master_data %>%
  mutate(title_clean = str_to_lower(TI)) %>%
  mutate(title_clean = str_remove_all(title_clean, "[[:punct:]]")) %>%
  mutate(title_clean = str_squish(title_clean))

#deduplicating
dados_unicos <- master_data %>%
  distinct(title_clean, .keep_all = TRUE)

#checking
cat("Total Original:", nrow(master_data), "\n")
cat("Total Únicos:", nrow(dados_unicos), "\n")
cat("Duplicatas removidas:", nrow(master_data) - nrow(dados_unicos), "\n")

#to Rayyan
write_csv(dados_unicos, "upload_rayyan_completo.csv")

