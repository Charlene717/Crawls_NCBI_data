# 載入必要的套件
library("rentrez")
library("tidyverse")
library("httr")
library("rvest")
library("openxlsx")

# 設定搜尋的關鍵字，時間範圍及查詢的資料庫
query <- "ATAC-seq AND RNA-seq AND development"
mindate <- "2012/01/01"
maxdate <- Sys.Date()
database <- "gds"

# 使用rentrez套件進行查詢
search <- entrez_search(db = database, term = query, mindate = mindate, maxdate = maxdate)
count <- search$count

# 擷取符合條件的GEO編號(GSE ID)
id_list <- entrez_fetch(db = database, web_history = search$web_history, rettype = "xml") %>%
  xml_find_all(".//Id") %>%
  xml_text()

# 設定輸出的Excel檔案名稱和檔案路徑
filename <- "result.xlsx"
path <- "~/"

# 建立一個空的data frame
df <- data.frame(GSE = character(),
                 PMID = character(),
                 Organism = character(),
                 Cell_Line = character(),
                 stringsAsFactors = FALSE)

# 使用for迴圈，逐一爬取每個符合條件的GEO編號(GSE ID)的詳細資訊
for(i in id_list){
  # 用entrez_summary取得每個GEO ID的摘要資訊
  summary <- entrez_summary(db = database, id = i, rettype = "xml")
  # 用rvest套件解析XML檔案中的網頁資訊，並且取得PMC ID
  pmc_id <- read_xml(summary) %>% html_nodes(".//Dbtag[Db='PMC']/Dbtag/Tag/Object-id") %>% html_text()
  # 設定查詢PMC ID的網址
  url <- paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/PMC", pmc_id)
  # 使用httr套件讀取網頁內容
  html <- content(GET(url))
  # 使用rvest套件解析網頁資訊
  organism <- html %>% html_nodes(".content .info-box tr:nth-child(1) td:nth-child(2)") %>% html_text()
  cell_line <- html %>% html_nodes(".content .info-box tr:nth-child(3) td:nth-child(2)") %>% html_text()
  # 將所需資訊儲存到data frame中
  df <- df %>% add_row(GSE = i, PMID = pmc_id, Organism = organism, Cell_Line = cell_line)
}

# 將data frame輸出成Excel檔案
write.xlsx(df, file = paste0(path, filename), row.names = FALSE)

# 提示程式執行完成
cat("Done!")
