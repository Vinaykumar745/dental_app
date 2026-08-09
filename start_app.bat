@echo off
echo Starting DentalScan AI...

:: Start the backend in a new window
echo Starting Backend...
start cmd /k "cd backend && start.bat"

:: Wait a few seconds for the backend to initialize
timeout /t 3 /nobreak >nul

:: Start the Flutter app
echo Starting Frontend...
flutter run
