#!/bin/bash

# 1. Clone Flutter stable branch
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# 2. Add Flutter to the PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Trigger tool download and check version
flutter --version

# 4. Enable Web support
flutter config --enable-web

# 5. Fetch dependencies
echo "Fetching dependencies..."
flutter pub get

# 6. Build the web project
echo "Building Web App..."
flutter build web --release --no-tree-shake-icons
