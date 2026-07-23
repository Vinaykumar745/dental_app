@echo off
echo ==========================================
echo   DentalScan AI - Backend Startup
echo ==========================================
echo.

:: Check if Node.js is installed
node --version >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Node.js is not installed!
    echo Please download from: https://nodejs.org
    pause
    exit /b 1
)

echo [OK] Node.js found
node --version

:: Check if MongoDB is running
echo.
echo [INFO] Checking MongoDB...
sc query MongoDB >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    sc start MongoDB >nul 2>&1
    echo [OK] MongoDB service started
) ELSE (
    echo [WARN] MongoDB service not found as Windows service.
    echo [INFO] Make sure MongoDB is running manually.
    echo        Or use MongoDB Atlas (update .env with Atlas URI)
)

echo.
echo [INFO] Installing dependencies...
cd /d "%~dp0backend"
call npm install

echo.
echo [INFO] Starting backend server...
echo [INFO] API will be at: http://localhost:5000/api
echo [INFO] Press Ctrl+C to stop the server
echo.
call npm run dev

pause
