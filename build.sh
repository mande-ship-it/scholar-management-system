#!/bin/bash

# 1. Download Flutter
git clone https://github.com/flutter/flutter.git -b $FLUTTER_CHANNEL

# 2. Add Flutter to Path
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Check Flutter version
flutter --version

# 4. Enable Web
flutter config --enable-web

# 5. Build for Web
flutter build web --release
