#!/bin/bash
set -e

echo "Setting up build environment..."
git config --global --add safe.directory '*' 2>/dev/null || true

echo "Installing Flutter..."
# Use a smaller, cached Flutter installation
if [ ! -d "flutter" ]; then
    curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz | tar -xJ --strip-components=1 -C flutter_temp
    mv flutter_temp flutter
fi

export PATH="$PWD/flutter/bin:$PATH"
export FLUTTER_ROOT="$PWD/flutter"

echo "Configuring Flutter..."
flutter config --no-analytics --suppress-analytics 2>/dev/null
flutter precache --web --no-android --no-ios --no-linux --no-macos --no-windows 2>/dev/null

echo "Getting dependencies..."
flutter pub get --no-example 2>/dev/null

echo "Building for web..."
flutter build web --release --web-renderer html --dart-define=FLUTTER_WEB_USE_SKIA=false --no-tree-shake-icons 2>/dev/null

echo "Build completed!"