#!/bin/bash
set -e

echo "Setting up build environment..."
git config --global --add safe.directory '*' 2>/dev/null || true

echo "Installing Flutter..."
# Create directory first, then extract
if [ ! -d "flutter" ]; then
    mkdir -p flutter_temp
    curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz | tar -xJ -C flutter_temp --strip-components=1
    mv flutter_temp flutter
fi

export PATH="$PWD/flutter/bin:$PATH"
export FLUTTER_ROOT="$PWD/flutter"

echo "Configuring Flutter..."
flutter config --no-analytics 2>/dev/null || true
flutter precache --web 2>/dev/null || true

echo "Getting dependencies..."
flutter pub get 2>/dev/null || flutter pub get

echo "Building for web..."
flutter build web --release --web-renderer html 2>/dev/null || flutter build web --release

echo "Build completed!"