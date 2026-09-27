#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
mkdir -p "$project_root/tmp"
temporary_dir="$(mktemp -d "$project_root/tmp/zonepin-build.XXXXXX")"
trap 'rm -rf "$temporary_dir"' EXIT

sdk_path="$(xcrun --sdk macosx --show-sdk-path)"
source_files=("$project_root"/app/Sources/*.swift)
bundle="$temporary_dir/ZonePin.app"

mkdir -p "$bundle/Contents/MacOS" "$bundle/Contents/Resources" "$project_root/dist"
cp "$project_root/app/Info.plist" "$bundle/Contents/Info.plist"
cp "$project_root/app/Resources/AppIcon.icns" "$bundle/Contents/Resources/AppIcon.icns"

for architecture in arm64 x86_64; do
    xcrun swiftc \
        -O \
        -target "$architecture-apple-macosx13.0" \
        -sdk "$sdk_path" \
        -framework AppKit \
        -framework SwiftUI \
        -framework ServiceManagement \
        "${source_files[@]}" \
        -o "$temporary_dir/ZonePin-$architecture"
done

xcrun lipo -create \
    "$temporary_dir/ZonePin-arm64" \
    "$temporary_dir/ZonePin-x86_64" \
    -output "$bundle/Contents/MacOS/ZonePin"

codesign --force --sign - "$bundle"

output_bundle="$project_root/dist/ZonePin.app"
rm -rf "$output_bundle"
ditto "$bundle" "$output_bundle"

echo "Built local app: $output_bundle"
xcrun lipo -info "$output_bundle/Contents/MacOS/ZonePin"
