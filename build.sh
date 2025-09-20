#!/bin/bash
set -e

echo "Setting up build environment..."
git config --global --add safe.directory '*' 2>/dev/null || true

echo "Checking for Flutter..."
if command -v flutter &> /dev/null
then
    echo "✅ Using system-installed Flutter"
else
    echo "⬇️  Flutter not found, downloading Flutter 3.32.5..."
    if [ ! -d "flutter" ]; then
        mkdir -p flutter_temp
        curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.5-stable.tar.xz | tar -xJ -C flutter_temp --strip-components=1
        mv flutter_temp flutter
    fi
    export PATH="$PWD/flutter/bin:$PATH"
    export FLUTTER_ROOT="$PWD/flutter"
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
