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

echo "Running Flutter doctor to check setup..."
flutter doctor -v || echo "Flutter doctor completed with warnings/errors"

echo "Setting up Flutter..."
# Accept Android licenses and setup
flutter config --no-analytics
flutter precache --web --verbose

echo "Cleaning previous builds..."
flutter clean

echo "Getting dependencies..."
flutter pub get --verbose

echo "Running pub deps to check for issues..."
flutter pub deps || echo "Dependency check completed"

echo "Building web app with platform compatibility..."
# Add more verbose output and error handling
set +e  # Temporarily disable exit on error
flutter build web --release --web-renderer html --dart-define=FLUTTER_WEB_USE_SKIA=false --verbose

if [ $? -ne 0 ]; then
    echo "Build failed. Trying alternative build options..."
    
    # Try with canvas renderer
    echo "Trying with canvaskit renderer..."
    flutter build web --release --web-renderer canvaskit --verbose
    
    if [ $? -ne 0 ]; then
        echo "Canvas build failed. Trying debug build..."
        flutter build web --debug --web-renderer html --verbose
        
        if [ $? -ne 0 ]; then
            echo "All build attempts failed. Checking for common issues..."
            echo "Pub cache location: $PUB_CACHE"
            echo "Flutter cache: $FLUTTER_ROOT"
            ls -la build/ 2>/dev/null || echo "No build directory found"
            exit 1
        fi
    fi
fi

set -e  # Re-enable exit on error

echo "Build completed successfully!"
echo "Output directory: build/web"
ls -la build/web/ || echo "Could not list build output"