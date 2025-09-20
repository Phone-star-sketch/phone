#!/bin/bash
set -e

echo "Installing Flutter..."
curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz | tar -xJ
export PATH="$PWD/flutter/bin:$PATH"

echo "Flutter version:"
flutter --version

echo "Running flutter doctor..."
flutter doctor

echo "Getting dependencies..."
flutter pub get

echo "Building web app..."
flutter build web --release

echo "Build completed successfully!"