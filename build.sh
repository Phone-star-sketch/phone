#!/bin/bash
set -e

echo "Setting up build environment..."
git config --global --add safe.directory '*' 2>/dev/null || true

echo "Using system-installed Flutter..."
# Make sure Flutter is in PATH
if ! command -v flutter &> /dev/null
then
    echo "❌ Flutter not found. Please install Flutter (>=3.32.5) and add it to PATH."
    exit 1
fi

echo "Flutter version:"
flutter --version

echo "Configuring Flutter..."
flutter config --no-analytics || true
flutter precache --web || true

echo "Getting dependencies..."
flutter pub get

echo "Building for web..."
flutter build web --release --web-renderer html || flutter build web --release

echo "✅ Build completed!"
