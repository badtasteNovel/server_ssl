@echo off
chcp 65001 > nul
REM ---------- 設定 ----------
REM set PHP_DIR=<path-to-php>
REM set NGINX_DIR=<path-to-nginx>
set PHP_FCGI_LISTEN=127.0.0.1:9000

REM ---------- 強制 PHP-CGI 讀 php.ini ----------
set PHPRC=%PHP_DIR%

REM ---------- 停止舊 PHP-CGI ----------
tasklist /FI "IMAGENAME eq php-cgi.exe" 2>NUL | find /I "php-cgi.exe" >NUL
if %ERRORLEVEL%==0 (
    taskkill /f /im php-cgi.exe >nul 2>&1
)

REM ---------- 啟動 PHP-CGI ----------
start "" /B "%PHP_DIR%\php-cgi.exe" -b %PHP_FCGI_LISTEN%
echo PHP-CGI 已啟動
echo ===================
nginx -s reload >nul 2>&1 || (
    echo Reload failed, trying to start Nginx... >nul 2>&1
    nginx 
)
echo ===================
echo NGINX 已啟動