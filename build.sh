#!/bin/bash
set -e

echo "Setting up build environment..."
# Fix git safe directory issue
git config --global --add safe.directory '*'

echo "Installing Flutter..."
# Download and extract Flutter
curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz | tar -xJ

# Set Flutter path
export PATH="$PWD/flutter/bin:$PATH"
export FLUTTER_ROOT="$PWD/flutter"

echo "Flutter version:"
flutter --version

echo "Setting up Flutter..."
# Accept Android licenses and setup
flutter config --no-analytics
flutter precache --web

echo "Getting dependencies..."
flutter pub get

echo "Building web app..."
flutter build web --release --web-renderer html

echo "Build completed successfully!"
echo "Output directory: build/web"