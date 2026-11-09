
#!/usr/bin/env bash
set -e

echo "Installing Flutter SDK..."

git clone --depth 1 --branch stable \
  https://github.com/flutter/flutter.git /tmp/flutter

export PATH="/tmp/flutter/bin:$PATH"

flutter --version
flutter pub get
flutter build web --release

echo "Flutter Web build completed!"
