@echo off
chcp 65001 >nul
SETLOCAL

REM ---------- 設定路徑 ----------
REM　set SSL_DIR=<path-to-your-ssl-dir>
set SITE_INF=%SSL_DIR%\example.local.inf
set SITE_CSR=%SSL_DIR%\example.local.csr
set SITE_CRT=%SSL_DIR%\example.local.crt
set SITE_KEY=%SSL_DIR%\example.local.key
set SITE_PFX=%SSL_DIR%\example.local.pfx
set DOMAIN=exmpale.local
REM ---------- 設定企業 CA ----------
REM certutil -config - -ping 
REM 該指令可以查找目前正在使用的ca 名稱
REM set CA_NAME=<電腦名稱>\<ca名稱>
REM 工具 → certification authority → 憑證範本 → 管理 → Web server 複製範本
REM 工具 → certification authority → 憑證範本 → 新增 → 範本新增
REM 來自 web server 的複製範本 名稱自訂
set TEMPLATE_NAME=WebServer_Internal

REM ---------- 檢查 INF ----------
if not exist "%SITE_INF%" (
    echo ERROR: INF file not found: %SITE_INF%
    pause
    exit /b 1
)

REM ---------- 生成 CSR ----------
echo [1/6] Generating CSR from INF...
certreq -new "%SITE_INF%" "%SITE_CSR%"
if not exist "%SITE_CSR%" (
    echo ERROR: CSR generation failed.
    pause
    exit /b 1
)
echo CSR generated successfully.
echo.

REM ---------- 提交 CSR 給企業 CA ----------
echo [2/6] Submitting CSR to enterprise CA...
certreq -submit -attrib "CertificateTemplate:%TEMPLATE_NAME%" -config "%CA_NAME%" "%SITE_CSR%" "%SITE_CRT%"
if errorlevel 1 (
    echo ERROR: certreq -submit failed. Check CA connectivity or template/permissions.
    pause
    exit /b 1
)
if not exist "%SITE_CRT%" (
    echo ERROR: Certificate file not found: %SITE_CRT%
    pause
    exit /b 1
)
echo Certificate received from CA.
echo.

REM ---------- 接受憑證到 Store (關鍵步驟!) ----------
echo [3/6] Installing certificate into LocalMachine\My store...
certreq -accept "%SITE_CRT%"
if errorlevel 1 (
    echo ERROR: certreq -accept failed. Cannot bind certificate with private key.
    pause
    exit /b 1
)
echo Certificate installed successfully with private key.
echo.

REM ---------- 驗證私鑰 ----------
echo [4/6] Verifying private key in certificate store...
REM 從 certreq -accept 輸出中取得 Thumbprint
for /f "tokens=2" %%T in ('certutil -store My ^| findstr /C:"%DOMAIN%" /A:-1 ^| findstr /C:"Cert Hash(sha1):"') do set THUMBPRINT=%%T
set THUMBPRINT=%THUMBPRINT: =%

if "%THUMBPRINT%"=="" (
    echo WARNING: Could not find thumbprint, trying alternative method...
    REM 使用 Subject 查詢
    certutil -store My > "%SSL_DIR%\cert_check.txt" 2>&1
    findstr /i "CN=%DOMAIN%" "%SSL_DIR%\cert_check.txt" >nul
    if errorlevel 1 (
        echo ERROR: Certificate not found in store!
        pause
        exit /b 1
    )
) else (
    echo Found certificate with thumbprint: %THUMBPRINT%
    certutil -store My %THUMBPRINT% > "%SSL_DIR%\cert_check.txt" 2>&1
)

REM 檢查是否有私鑰
findstr /i "Private.*Key" "%SSL_DIR%\cert_check.txt" >nul
if errorlevel 1 (
    echo WARNING: Private key marker not found in standard location.
    echo Attempting PFX export test to verify private key exists...
    REM 直接嘗試匯出來驗證私鑰是否存在
    goto :skip_verify
)
echo Private key verified successfully.
echo.
:skip_verify

REM ---------- 匯出 PFX ----------
echo [5/6] Exporting certificate with private key to PFX...
certutil -exportpfx -p "" -f -privatekey My "%DOMAIN%" "%SITE_PFX%"
if errorlevel 1 (
    echo ERROR: PFX export failed.
    pause
    exit /b 1
)
echo PFX exported successfully.
echo.

REM ---------- 轉換為 PEM 格式 ----------
echo [6/6] Converting PFX to PEM format (.key + .crt)...
openssl pkcs12 -in "%SITE_PFX%" -nocerts -nodes -out "%SITE_KEY%" -passin pass:
if errorlevel 1 (
    echo ERROR: OpenSSL failed to extract private key.
    pause
    exit /b 1
)

openssl pkcs12 -in "%SITE_PFX%" -clcerts -nokeys -out "%SITE_CRT%.new" -passin pass:
if errorlevel 1 (
    echo ERROR: OpenSSL failed to extract certificate.
    pause
    exit /b 1
)

REM 覆蓋原本的 CRT (改為 PEM 格式)
move /y "%SITE_CRT%.new" "%SITE_CRT%" >nul

echo.
echo ============================================
echo     Certificate Generation Complete!
echo ============================================
echo.
echo Files created:
echo   CSR:         %SITE_CSR%
echo   Certificate: %SITE_CRT% (PEM format)
echo   Private Key: %SITE_KEY% (PEM format)
echo   PFX:         %SITE_PFX%
echo   INF Config:  %SITE_INF%
echo.
echo You can now copy the .crt and .key files to your Nginx server.
echo.
echo Nginx configuration example:
echo   ssl_certificate     /path/to/%DOMAIN%.crt;
echo   ssl_certificate_key /path/to/%DOMAIN%.key;
echo.
pause