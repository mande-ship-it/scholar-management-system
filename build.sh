#!/bin/bash

# 1. Clone Flutter SDK if not already present
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# 2. Add Flutter to the PATH
export PATH="$PWD/flutter/bin:$PATH"

# 3. Check version
flutter --version

# 4. Enable Web support
flutter config --enable-web

# 5. Fetch Flutter dependencies
echo "Fetching Flutter dependencies..."
flutter pub get

# 6. Build the web project
echo "Building Web App..."
# No tree shake icons to avoid common issues with Material Icons on web
flutter build web --release --no-tree-shake-icons

# 7. Install serve for production serving (since Render needs to serve build/web)
if [ -f "package.json" ]; then
    echo "Installing Node dependencies..."
    npm install
fi
