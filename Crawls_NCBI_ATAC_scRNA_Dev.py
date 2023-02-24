import pandas as pd
import requests
from bs4 import BeautifulSoup

# 構建搜尋詞
search_term = "((ATAC-seq AND RNA-seq) AND development) AND (human OR mouse) AND \"2000/01/01\"[PDAT]:\"2023/02/24\"[PDAT]"

# 構建NCBI搜尋頁面的網址
base_url = "https://www.ncbi.nlm.nih.gov"
search_url = f"{base_url}/gds/?term={search_term}"

# 下載搜尋頁面HTML並解析
response = requests.get(search_url)
soup = BeautifulSoup(response.content, "html.parser")

# 找到包含搜尋結果的表格
table = soup.find("table", {"class": "tbl"})

# 找到表格中的行
rows = table.findAll("tr")[1:]

# 構建空的DataFrame，將匹配的研究添加到其中
df = pd.DataFrame(columns=["Series", "PMID", "Organism", "Cell line"])

# 遍歷表格中的每一行，提取所需的信息
for row in rows:
    cols = row.findAll("td")
    series = cols[0].find("a").text.strip()
    pmid = cols[1].find("a").text.strip()
    organism = cols[4].text.strip()
    cell_line = cols[5].text.strip()
    
    # 將符合條件的研究添加到DataFrame中
    if organism in ["Homo sapiens", "Mus musculus"] and cell_line != "":
        df = df.append({"Series": series, "PMID": pmid, "Organism": organism, "Cell line": cell_line}, ignore_index=True)

# 保存結果為Excel檔案
df.to_excel("result.xlsx", index=False)
