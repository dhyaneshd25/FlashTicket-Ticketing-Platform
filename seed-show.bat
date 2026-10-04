@echo off
echo Seeding sample show into PostgreSQL flashticket database...
set PGPASSWORD=Saibaba25$
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d flashticket -f "%~dp0src\main\resources\db\seed.sql"
echo Done.
