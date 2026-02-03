echo "Build APK"
flutter build apk --split-per-abi

echo "Build EXE"
flutter build windows --release