#!/bin/bash

# 1. Clone Flutter stable branch if not exists
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# 2. Add Flutter to the PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Check Flutter version (This also triggers tool download)
flutter --version

# 4. Precache web artifacts
flutter precache --web

# 5. Enable Web support
flutter config --enable-web

# 6. Build the web project
echo "Building Web App..."
flutter build web --release --no-tree-shake-icons
