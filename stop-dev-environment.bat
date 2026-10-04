@echo off
echo ======================================================================
echo           FlashTicket - Stopping Local Development Environment
echo ======================================================================

echo Stopping Redis...
taskkill /F /IM redis-server.exe >nul 2>&1

echo Stopping Kafka...
wmic process where "commandline like '%%kafka.Kafka%%'" call terminate >nul 2>&1
wmic process where "commandline like '%%kafka-server-start%%'" call terminate >nul 2>&1

echo Services stopped.
