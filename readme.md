# 如何active directory 架設內網伺服器。(會建立dns和企業ssl憑證)
1. 增加active directory domain service。
2. 增加active directory ca。
3. domain service 建立時會自動委任dns 伺服器。 此網域皆會使用該dns 伺服器。
# dns 伺服器
1. 使用正向區域，輸入網域名稱，為該網域名稱增加A紀錄(主機位置)。
2. dns 為中轉站，可進行A紀錄的增加將不同網址發配給不同機器。
3. 為該dns伺服器進行轉寄，轉給8.8.8.8 和1.1.1.1
## 客戶端使用dns 伺服器 於網際網路中指派該dns 伺服器網址。


**建議active directory 網域最好加一個ad作為前綴**