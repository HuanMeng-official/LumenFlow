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
    "iOS (Unsigned .app)" \
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
            break
            ;;
        "iOS (Unsigned .app)")
            require_host "Darwin" "iOS"
            echo "Building iOS (release, no codesign), BUILD_DATE=$build_date"
            flutter build ios --no-codesign --dart-define=BUILD_DATE="$build_date"
            break
            ;;
        "iOS (Signed .ipa)")
            require_host "Darwin" "iOS"
            echo "Building iOS (release, signed ipa), BUILD_DATE=$build_date"
            flutter build ipa --dart-define=BUILD_DATE="$build_date"
            break
            ;;
        "Android")
            echo "Building Android (release, split-per-abi), BUILD_DATE=$build_date"
            flutter build apk --release --split-per-abi --dart-define=BUILD_DATE="$build_date"
            break
            ;;
        *)
            echo "Invalid selection: $REPLY"
            ;;
    esac
done
