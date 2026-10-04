@echo off
echo ======================================================================
echo           FlashTicket - Seeding Users and Shows into PostgreSQL
echo ======================================================================
set PGPASSWORD=Saibaba25$
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d flashticket -f "%~dp0src\main\resources\db\seed.sql"
if %ERRORLEVEL% equ 0 (
    echo.
    echo [SUCCESS] Database seeded successfully!
    echo.
    echo User Accounts Created:
    echo   - ADMIN:     admin@flashticket.com     / admin123
    echo   - ORGANIZER: organizer@flashticket.com / organizer123
    echo   - ORGANIZER: promoter@flashticket.com  / promoter123
    echo   - USER:      user@flashticket.com      / user123
    echo   - USER:      alice@flashticket.com     / password123
    echo ======================================================================
) else (
    echo.
    echo [ERROR] Failed to seed database. Check PostgreSQL service and credentials.
)
