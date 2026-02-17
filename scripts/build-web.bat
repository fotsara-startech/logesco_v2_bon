@echo off
echo ========================================
echo LOGESCO v2 - Build Web Application
echo ========================================

cd /d "%~dp0\..\logesco_v2"

echo Cleaning previous builds...
flutter clean

echo Getting dependencies...
flutter pub get

echo Building web application for production...
flutter build web --release --web-renderer html --base-href /

echo Optimizing web build...
echo Compressing assets...

echo Web build completed!
echo Output directory: build\web\

pause