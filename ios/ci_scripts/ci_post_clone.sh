#!/bin/bash

# Navigate to the Flutter project directory
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Install Flutter (if not already available in the environment)
if ! command -v flutter &> /dev/null
then
    echo "Flutter is not installed. Installing Flutter SDK..."
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
    export PATH="$PATH:$HOME/flutter/bin"
else
    echo "Flutter is already installed."
fi

# Verify Flutter installation
flutter --version

# Install dependencies
echo "Running Flutter pub get..."
# Install Flutter artifacts for iOS platform.
flutter precache --ios

flutter pub get

cd ios

echo "Resolving Swift Package Manager dependencies..."


defaults write com.apple.dt.Xcode IDEPackageOnlyUseVersionsFromResolvedFile -bool false
defaults write com.apple.dt.Xcode IDEDisableAutomaticPackageResolution -bool false

# 2. Delete Package.resolved from BOTH the workspace and the project caches
rm -f Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved
rm -f Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

# 3. Resolve packages safely depending on what Flutter generated
if [ -d "Runner.xcworkspace" ]; then
    xcodebuild -resolvePackageDependencies -workspace Runner.xcworkspace -scheme Runner
else
    xcodebuild -resolvePackageDependencies -project Runner.xcodeproj -scheme Runner
fi

# Go back to the workspace root
cd "$CI_PRIMARY_REPOSITORY_PATH"

echo "Flutter Build running..."
flutter pub run build_runner build --delete-conflicting-outputs
flutter build ios --no-codesign -t lib/main.dart