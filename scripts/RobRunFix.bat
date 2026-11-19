@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Rob Run - Server Connection Fix Tool
mode con: cols=74 lines=42
color 0A

:: =====================================================================
::  ADMIN CHECK - auto elevate
:: =====================================================================
net session >nul 2>&1
if errorlevel 1 (
    echo.
    echo  [!] Administrator privileges are required. Restarting...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: =====================================================================
::  LOG FILE
:: =====================================================================
set "TIMESTAMP=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "TIMESTAMP=%TIMESTAMP: =0%"
set "LOG=%~dp0RobRunFix_%TIMESTAMP%.log"
echo [%date% %time%] Rob Run Fix Tool started >> "%LOG%"

:: =====================================================================
::  MAIN MENU
:: =====================================================================
:MENU
cls
echo.
echo  +===============================================================+
echo  ^|          R O B   R U N   -   S E R V E R   F I X              ^|
echo  +===============================================================+
echo.
echo    [1]  Quick Fix          Flush DNS, renew IP, reset Winsock
echo    [2]  Set DNS            Cloudflare (1.1.1.1) or Google (8.8.8.8)
echo    [3]  Reset DNS          Restore DHCP-assigned DNS
echo    [4]  Disable Proxy      Turn off system + WinHTTP proxy
echo    [5]  Firewall Reset     Restore Windows Firewall defaults
echo    [6]  Full Auto Fix      Quick Fix + Set DNS + Disable Proxy
echo    [7]  Show Network Info  Current adapters, DNS, proxy status
echo    [8]  Open Full Guide    Launch GitHub documentation
echo    [9]  Open Log File      View this session's log
echo    [0]  Exit
echo.
echo  +===============================================================+
set /p "choice=   Choose [0-9]: "

if "%choice%"=="1" goto QUICK
if "%choice%"=="2" goto SETDNS
if "%choice%"=="3" goto RESETDNS
if "%choice%"=="4" goto NOPROXY
if "%choice%"=="5" goto FWRESET
if "%choice%"=="6" goto FULLAUTO
if "%choice%"=="7" goto NETINFO
if "%choice%"=="8" goto GUIDE
if "%choice%"=="9" goto OPENLOG
if "%choice%"=="0" goto END

echo  [!] Invalid input. Try again.
timeout /t 2 >nul
goto MENU

:: =====================================================================
::  [1] QUICK FIX
:: =====================================================================
:QUICK
cls
echo.
echo  -- QUICK FIX ---------------------------------------------------
echo.
echo  [*] Releasing IP address...
ipconfig /release >nul 2>&1
echo  [*] Renewing IP address...
ipconfig /renew >nul 2>&1
echo  [*] Flushing DNS cache...
ipconfig /flushdns >nul 2>&1
echo  [*] Resetting Winsock catalog...
netsh winsock reset >nul 2>&1
echo  [*] Resetting TCP/IP stack...
netsh int ip reset >nul 2>&1
echo.
echo  [OK] Quick fix applied. A reboot is strongly recommended.
echo [%date% %time%] Quick Fix applied >> "%LOG%"
echo.
pause
goto MENU

:: =====================================================================
::  [2] SET DNS
:: =====================================================================
:SETDNS
cls
echo.
echo  -- SET DNS SERVER ----------------------------------------------
echo.
echo    [1] Cloudflare  (1.1.1.1 / 1.0.0.1)
echo    [2] Google      (8.8.8.8 / 8.8.4.4)
echo    [0] Back to menu
echo.
set /p "dns=   Choose DNS provider: "

if "%dns%"=="1" (
    set "P1=1.1.1.1"
    set "P2=1.0.0.1"
    set "PN=Cloudflare"
) else if "%dns%"=="2" (
    set "P1=8.8.8.8"
    set "P2=8.8.4.4"
    set "PN=Google"
) else (
    goto MENU
)

echo.
echo  [*] Applying !PN! DNS to all active physical adapters...
powershell -NoProfile -Command "Get-NetAdapter -Physical | Where-Object Status -eq 'Up' | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses ('!P1!','!P2!') -ErrorAction SilentlyContinue }"
ipconfig /flushdns >nul 2>&1
echo  [OK] DNS set to !PN!  (!P1!, !P2!)
echo [%date% %time%] DNS set to !PN! (%P1%, %P2%) >> "%LOG%"
echo.
pause
goto MENU

:: =====================================================================
::  [3] RESET DNS TO DHCP
:: =====================================================================
:RESETDNS
cls
echo.
echo  -- RESET DNS TO AUTOMATIC --------------------------------------
echo.
echo  [*] Restoring DHCP-assigned DNS on all active adapters...
powershell -NoProfile -Command "Get-NetAdapter -Physical | Where-Object Status -eq 'Up' | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses -ErrorAction SilentlyContinue }"
ipconfig /flushdns >nul 2>&1
echo  [OK] DNS restored to automatic mode (DHCP).
echo [%date% %time%] DNS reset to DHCP >> "%LOG%"
echo.
pause
goto MENU

:: =====================================================================
::  [4] DISABLE PROXY
:: =====================================================================
:NOPROXY
cls
echo.
echo  -- DISABLE PROXY -----------------------------------------------
echo.
echo  [*] Disabling Internet Settings proxy...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoConfigURL /f >nul 2>&1
echo  [*] Resetting WinHTTP proxy...
netsh winhttp reset proxy >nul 2>&1
echo.
echo  [OK] Proxy disabled. Restart Steam and Rob Run.
echo [%date% %time%] Proxy disabled >> "%LOG%"
echo.
pause
goto MENU

:: =====================================================================
::  [5] FIREWALL RESET
:: =====================================================================
:FWRESET
cls
echo.
echo  -- RESET WINDOWS FIREWALL --------------------------------------
echo.
echo  WARNING: This deletes ALL custom firewall rules on this PC.
set /p "confirm=   Continue? (Y/N): "
if /i not "%confirm%"=="Y" goto MENU
echo.
echo  [*] Resetting firewall configuration...
netsh advfirewall reset >nul 2>&1
echo  [OK] Firewall restored to default state.
echo [%date% %time%] Firewall reset >> "%LOG%"
echo.
pause
goto MENU

:: =====================================================================
::  [6] FULL AUTO FIX
:: =====================================================================
:FULLAUTO
cls
echo.
echo  -- FULL AUTO FIX -----------------------------------------------
echo.
echo  Runs: Quick Fix  +  Cloudflare DNS  +  Disable Proxy
set /p "confirm=   Continue? (Y/N): "
if /i not "%confirm%"=="Y" goto MENU
echo.
echo  [1/3] Running quick network fix...
ipconfig /release >nul 2>&1
ipconfig /renew   >nul 2>&1
ipconfig /flushdns >nul 2>&1
netsh winsock reset >nul 2>&1
netsh int ip reset  >nul 2>&1
echo  [2/3] Applying Cloudflare DNS...
powershell -NoProfile -Command "Get-NetAdapter -Physical | Where-Object Status -eq 'Up' | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses ('1.1.1.1','1.0.0.1') -ErrorAction SilentlyContinue }"
ipconfig /flushdns >nul 2>&1
echo  [3/3] Disabling proxies...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul
netsh winhttp reset proxy >nul 2>&1
echo.
echo  [OK] Full Auto Fix completed.
echo  [>>] Please REBOOT your PC before launching Rob Run again.
echo [%date% %time%] Full Auto Fix applied >> "%LOG%"
echo.
pause
goto MENU

:: =====================================================================
::  [7] NETWORK INFO
:: =====================================================================
:NETINFO
cls
echo.
echo  -- NETWORK INFORMATION -----------------------------------------
echo.
echo  [Active physical adapters]
powershell -NoProfile -Command "Get-NetAdapter -Physical | Where-Object Status -eq 'Up' | Format-Table Name,Status,LinkSpeed -AutoSize" 2>nul
echo  [Current DNS servers]
powershell -NoProfile -Command "Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses } | Format-Table InterfaceAlias,ServerAddresses -AutoSize" 2>nul
echo  [Proxy status]
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable 2>nul | findstr /C:"ProxyEnable"
if errorlevel 1 echo  ProxyEnable value not found.
echo.
pause
goto MENU

:: =====================================================================
::  [8] OPEN GUIDE
:: =====================================================================
:GUIDE
echo.
echo  [*] Opening GitHub documentation in browser...
start "" "https://github.com/mladytomato/rob-run-server-fix"
timeout /t 2 >nul
goto MENU

:: =====================================================================
::  [9] OPEN LOG
:: =====================================================================
:OPENLOG
if exist "%LOG%" (
    start "" notepad "%LOG%"
) else (
    echo  [!] No log file for this session yet.
    timeout /t 2 >nul
)
goto MENU

:: =====================================================================
::  EXIT
:: =====================================================================
:END
cls
echo.
echo  +===============================================================+
echo  ^|            Thank you for using Rob Run Fix Tool!              ^|
echo  +===============================================================+
echo.
echo    Log saved to: %LOG%
echo.
echo    Press any key to exit...
pause >nul
endlocal
exit /b
