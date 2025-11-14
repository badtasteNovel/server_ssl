# active directory 是什麼
- 簡而言之是企業用管理系統。管理底下這些<br>
1.電腦<br>
2.使用者帳號<br>
3.群組<br>
4.權限<br>
5.檔案存取<br>
6.安全性政策<br>
7.登入驗證<br>
[僅僅使用則點此略過到達使用手冊](#客戶端加入域)
# 如何active directory 架設內網伺服器。(會建立dns和企業ssl憑證)
**建議active directory 網域最好加一個ad作為前綴**
1. 增加active directory domain service。
2. 增加active directory ca。
3. 第一次建立請建立新的樹系。
3. domain service 建立時會自動委任dns 伺服器。 此網域皆會使用該dns 伺服器。
# dns 伺服器
1. 使用正向區域，輸入網域名稱，為該網域名稱增加A紀錄(主機位置)。
2. dns 為中轉站，可進行A紀錄的增加將不同網址發配給不同機器。
3. 為該dns伺服器進行轉寄，轉給8.8.8.8 和1.1.1.1
## 客戶端使用dns 伺服器 於網際網路中指派該dns 伺服器網址。

# 將crt 加入 ad 信任中。
匯出你的 AD CA 根證書

在 AD CA 伺服器上打開 Certification Authority。

右鍵 CA 名稱 → Properties → View Certificate → Details → Copy to File…

使用 Base-64 encoded X.509 (.CER) 格式匯出到域控制器可存取的路徑。

2️⃣ 打開 Group Policy Management

在域控制器上，按 Win+R → 輸入 gpmc.msc → Enter。

選擇你要套用的範圍：

整個域 → 建議套用全域所有電腦

或 指定 OU → 只套用某個部門的電腦

3️⃣ 建立新的 GPO 或使用現有 GPO

右鍵 → Create a GPO in this domain, and Link it here…

給它一個名稱，例如：

AD-CA-Root-Distribution

4️⃣ 編輯 GPO 匯入根證書

右鍵新建的 GPO → Edit

導航到：

Computer Configuration
 └─ Policies
     └─ Windows Settings
         └─ Security Settings
             └─ Public Key Policies
                 └─ Trusted Root Certification Authorities


右鍵 → Import…

選擇剛剛匯出的 crt

完成匯入，按 OK。

5️⃣ 確認 GPO 已連結

在 GPMC 中，點選你的 GPO → Scope

確認 Linked to 欄位有你的域名或 OU

Enforced 可選，確保策略被強制套用。
# 將客戶端加入域
步驟 1：設定 DNS


客戶端的 首選 DNS 必須指向你的 AD DNS 伺服器（通常就是域控制器 IP）。


打開網路設定 → IPv4 → DNS → 輸入 該伺服器內網ip

步驟 2：加入域

方法 A：透過 GUI（最簡單）

打開 控制台 → 系統 → 關於 → 進階系統設定 → 電腦名稱 → 變更

選擇 域 (Domain)，輸入你的域名，例如：當時建立ad域的名稱
輸入 使用者(自訂義) 創建域時的密碼。


