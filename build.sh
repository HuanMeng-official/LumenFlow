#!/usr/bin/env bash
#
# LumenFlow build script -- Linux / macOS / iOS / Android
#
# Usage:  ./build.sh
#
# Injects the build date so the About page can show a real build timestamp
# instead of a value derived from runtime DateTime.now().
#
# Note: iOS and macOS builds require a macOS host, and Linux builds require a
# Linux host -- they cannot be cross-compiled. The script checks the host up
# front and fails with a clear message rather than letting flutter emit a
# confusing error.

set -euo pipefail

cd "$(dirname "$0")"

build_date="$(date +%F)"
host="$(uname -s)"

require_host() {
    if [ "$host" != "$1" ]; then
        echo "Error: $2 builds require a $1 host (current host: $host)." >&2
        exit 1
    fi
}

PS3="Select: "
echo "Select the platform to build:"
select target in \
    "Linux" \
    "macOS" \
    "iOS (Unsigned .ipa)" \
    "iOS (Signed .ipa)" \
    "Android"
do
    case "$target" in
        "Linux")
            require_host "Linux" "Linux"
            echo "Building Linux (release), BUILD_DATE=$build_date"
            flutter build linux --release --dart-define=BUILD_DATE="$build_date"
            break
            ;;
        "macOS")
            require_host "Darwin" "macOS"
            echo "Building macOS (release), BUILD_DATE=$build_date"
            flutter build macos --release --dart-define=BUILD_DATE="$build_date"

            release_dir="build/macos/Build/Products/Release"
            app_path="$release_dir/LumenFlow.app"
            dmg_path="$release_dir/app-universal-release.dmg"
            stage_dir="$release_dir/dmg_stage"

            if [ ! -d "$app_path" ]; then
                echo "Error: expected app bundle not found at $app_path" >&2
                exit 1
            fi

            echo "Packaging macOS DMG"
            rm -rf "$stage_dir" "$dmg_path" "$dmg_path.sha1"
            mkdir -p "$stage_dir"
            ditto "$app_path" "$stage_dir/LumenFlow.app"
            ln -s /Applications "$stage_dir/Applications"
            hdiutil create -volname "LumenFlow" -srcfolder "$stage_dir" \
                -ov -format UDZO "$dmg_path"
            rm -rf "$stage_dir"

            echo "Generating SHA-1 checksum"
            shasum -a 1 "$dmg_path" | awk '{print $1}' > "$dmg_path.sha1"

            echo "Built: $dmg_path"
            echo "SHA-1: $(cat "$dmg_path.sha1")"
            break
            ;;
        "iOS (Unsigned .ipa)")
            require_host "Darwin" "iOS"
            echo "Building iOS (release, no codesign), BUILD_DATE=$build_date"
            flutter build ios --no-codesign --release --dart-define=BUILD_DATE="$build_date"

            app_path="build/ios/iphoneos/Runner.app"
            ipa_dir="build/ios/ipa"
            ipa_path="$ipa_dir/app-arm64-release.ipa"
            stage_dir="$ipa_dir/ipa_stage"
            ipa_abs="$(pwd)/$ipa_path"

            if [ ! -d "$app_path" ]; then
                echo "Error: expected app bundle not found at $app_path" >&2
                exit 1
            fi

            echo "Packaging unsigned iOS IPA"
            rm -rf "$stage_dir" "$ipa_path" "$ipa_path.sha1"
            mkdir -p "$stage_dir/Payload"
            ditto "$app_path" "$stage_dir/Payload/Runner.app"
            ( cd "$stage_dir" && zip -qry "$ipa_abs" Payload )
            rm -rf "$stage_dir"

            echo "Generating SHA-1 checksum"
            shasum -a 1 "$ipa_path" | awk '{print $1}' > "$ipa_path.sha1"

            echo "Built: $ipa_path"
            echo "SHA-1: $(cat "$ipa_path.sha1")"
            break
            ;;
        "iOS (Signed .ipa)")
            require_host "Darwin" "iOS"
            echo "Building iOS (release, signed ipa), BUILD_DATE=$build_date"
            flutter build ipa --dart-define=BUILD_DATE="$build_date"
            break
            ;;
        "Android")
            echo "Building Android universal APK (release), BUILD_DATE=$build_date"
            flutter build apk --release --dart-define=BUILD_DATE="$build_date"
            mv build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/app-universal-release.apk
            mv build/app/outputs/flutter-apk/app-release.apk.sha1 build/app/outputs/flutter-apk/app-universal-release.apk.sha1

            echo "Building Android split APKs (release), BUILD_DATE=$build_date"
            flutter build apk --release --split-per-abi --dart-define=BUILD_DATE="$build_date"
            break
            ;;
        *)
            echo "Invalid selection: $REPLY"
            ;;
    esac
done
