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

# Set Flutter environment variables for web builds
export FLUTTER_WEB_USE_SKIA=false
export PUB_CACHE="$PWD/.pub-cache"

echo "Flutter version:"
flutter --version

echo "Setting up Flutter..."
# Accept Android licenses and setup
flutter config --no-analytics
flutter precache --web

echo "Cleaning previous builds..."
flutter clean

echo "Getting dependencies with retry mechanism..."
# Add retry logic for pub get
for i in {1..3}; do
    echo "Attempt $i: Getting dependencies..."
    if flutter pub get --verbose; then
        echo "Dependencies resolved successfully"
        break
    else
        echo "Attempt $i failed, retrying in 10 seconds..."
        sleep 10
        if [ $i -eq 3 ]; then
            echo "Failed to resolve dependencies after 3 attempts"
            exit 1
        fi
    fi
done

echo "Building web app with optimized settings..."
# Build with enhanced web optimizations
flutter build web \
    --release \
    --web-renderer html \
    --dart-define=FLUTTER_WEB_USE_SKIA=false \
    --dart-define=FLUTTER_WEB_AUTO_DETECT=false \
    --source-maps \
    --tree-shake-icons \
    --verbose

echo "Build completed successfully!"
echo "Output directory: build/web"