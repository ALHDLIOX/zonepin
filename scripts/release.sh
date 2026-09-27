#!/bin/zsh
set -euo pipefail

if [[ -z "${DEVELOPER_ID_APPLICATION:-}" || -z "${NOTARY_PROFILE:-}" ]]; then
    echo "Set DEVELOPER_ID_APPLICATION and NOTARY_PROFILE before releasing." >&2
    exit 2
fi

project_root="${0:A:h:h}"
mkdir -p "$project_root/tmp"
temporary_dir="$(mktemp -d "$project_root/tmp/zonepin-release.XXXXXX")"
trap 'rm -rf "$temporary_dir"' EXIT

"$project_root/scripts/build.sh"
bundle="$project_root/dist/ZonePin.app"
version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$bundle/Contents/Info.plist")"
package_version="$(node -p "require('$project_root/package.json').version")"
if [[ "$version" != "$package_version" ]]; then
    echo "App version ($version) and npm version ($package_version) differ." >&2
    exit 2
fi

codesign --force --sign "$DEVELOPER_ID_APPLICATION" --options runtime --timestamp "$bundle"
codesign --verify --deep --strict --verbose=2 "$bundle"

submission_zip="$temporary_dir/ZonePin-notary-submission.zip"
ditto -c -k --keepParent "$bundle" "$submission_zip"
xcrun notarytool submit "$submission_zip" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$bundle"
xcrun stapler validate "$bundle"
spctl --assess --type execute --verbose=2 "$bundle"

release_zip="$project_root/dist/ZonePin-$version-macOS-universal.zip"
rm -f "$release_zip"
ditto -c -k --keepParent "$bundle" "$release_zip"
echo "Notarized app archive: $release_zip"
