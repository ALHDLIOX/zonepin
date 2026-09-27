#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
mkdir -p "$project_root/tmp"
temporary_dir="$(mktemp -d "$project_root/tmp/zonepin-test.XXXXXX")"
trap 'rm -rf "$temporary_dir"' EXIT

xcrun swiftc \
    -parse-as-library \
    "$project_root/app/Sources/ClockFormatter.swift" \
    "$project_root/app/Tests/ClockFormatterTests.swift" \
    -o "$temporary_dir/ClockFormatterTests"

"$temporary_dir/ClockFormatterTests"
