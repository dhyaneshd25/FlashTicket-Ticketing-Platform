@echo off
echo ======================================================================
echo           FlashTicket - Starting Local Development Environment
echo ======================================================================

:: 1. Check PostgreSQL
echo [1/3] Checking PostgreSQL service...
sc query postgresql-x64-18 | find "RUNNING" >nul
if %ERRORLEVEL% equ 0 (
    echo       PostgreSQL service is RUNNING on port 5432.
) else (
    echo       Starting PostgreSQL service...
    net start postgresql-x64-18 >nul 2>&1
)

:: 2. Check and start Redis
echo [2/3] Checking Redis (port 6379)...
powershell -NoProfile -Command "(Get-Process -Name redis-server -ErrorAction SilentlyContinue) -ne $null" | find "True" >nul
if %ERRORLEVEL% equ 0 (
    echo       Redis is ALREADY RUNNING.
) else (
    echo       Starting Redis server in background...
    start "Redis Server" /min "C:\tools\redis\redis-server.exe" "C:\tools\redis\redis.windows.conf"
    powershell -NoProfile -Command "Start-Sleep -Seconds 2"
)

:: 3. Check and start Kafka (KRaft mode)
echo [3/3] Checking Apache Kafka (port 9092)...
powershell -NoProfile -Command "(Get-NetTCPConnection -LocalPort 9092 -State Listen -ErrorAction SilentlyContinue) -ne $null" | find "True" >nul
if %ERRORLEVEL% equ 0 (
    echo       Kafka is ALREADY RUNNING.
) else (
    echo       Starting Kafka broker in background...
    start "Kafka Broker" /min cmd.exe /c "C:\tools\kafka\bin\windows\kafka-server-start.bat C:\tools\kafka\config\server.properties"
    powershell -NoProfile -Command "Start-Sleep -Seconds 5"
)

echo.
echo ======================================================================
echo Service Status Verification:
powershell -NoProfile -Command "Write-Host ' - PostgreSQL (5432): ' (Test-NetConnection -Port 5432 -ComputerName localhost -WarningAction SilentlyContinue).TcpTestSucceeded; Write-Host ' - Redis      (6379): ' (Test-NetConnection -Port 6379 -ComputerName localhost -WarningAction SilentlyContinue).TcpTestSucceeded; Write-Host ' - Kafka      (9092): ' (Test-NetConnection -Port 9092 -ComputerName localhost -WarningAction SilentlyContinue).TcpTestSucceeded"
echo ======================================================================
echo All infrastructure services are ready!
echo You can now run: mvn spring-boot:run
echo ======================================================================
