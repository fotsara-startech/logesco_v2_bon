#!/bin/bash

echo "========================================"
echo "LOGESCO v2 - Build Desktop Application"
echo "========================================"

cd "$(dirname "$0")/../logesco_v2"

echo "Cleaning previous builds..."
flutter clean

echo "Getting dependencies..."
flutter pub get

echo "Building Windows desktop application..."
flutter build windows --release

echo "Build completed!"
echo "Output directory: build/windows/x64/runner/Release/"