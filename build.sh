#!/bin/bash

# Build script for MyMouser

set -e

echo "Building MyMouser..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "Error: This project can only be built on macOS"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: Xcode is not installed"
    exit 1
fi

# Build the project
cd "$(dirname "$0")"

xcodebuild -project MyMouser.xcodeproj \
    -scheme MyMouser \
    -configuration Debug \
    -derivedDataPath build/DerivedData \
    build

echo "Build completed successfully!"
echo "App location: build/DerivedData/Build/Products/Debug/MyMouser.app"
