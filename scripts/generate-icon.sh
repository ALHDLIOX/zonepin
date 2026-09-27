#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
source_icon="$project_root/app/Resources/ZonePinIcon.png"
output_icon="$project_root/app/Resources/AppIcon.icns"
mkdir -p "$project_root/tmp"
working_dir="$(mktemp -d "$project_root/tmp/zonepin-icon.XXXXXX")"
trap 'rm -rf "$working_dir"' EXIT
iconset="$working_dir/AppIcon.iconset"
mkdir -p "$iconset"

for size in 16 32 128 256 512; do
    sips -s format png -z "$size" "$size" "$source_icon" \
        --out "$iconset/icon_${size}x${size}.png" > /dev/null
    double_size=$((size * 2))
    sips -s format png -z "$double_size" "$double_size" "$source_icon" \
        --out "$iconset/icon_${size}x${size}@2x.png" > /dev/null
done

iconutil -c icns "$iconset" -o "$output_icon"
echo "Generated $output_icon"
