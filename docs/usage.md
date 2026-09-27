# ZonePin usage and distribution

ZonePin is a native macOS menu bar app showing one selected IANA time zone in the fixed English 24-hour format `Sun Sep 27 02:31`. It defaults to `Asia/Shanghai`, saves the selection locally, and never changes the Mac's system time zone. macOS 13+, Intel and Apple silicon are supported.

## Run and control

Install from GitHub with `npx --yes github:ALHDLIOX/zonepin` after installing Node.js 18+ and Xcode Command Line Tools. The command builds a universal app from the source in this repository, ad-hoc signs it, installs it to `~/Applications/ZonePin.app`, and opens it. It creates no `postinstall` hook and requires no administrator password. This is a local source build, not an Apple-notarized binary.

Click the menu bar time to search and choose a time zone. The choice is saved immediately. **Launch at Login** defaults to on; if the menu says **Approval Needed**, allow it in **System Settings → General → Login Items & Extensions**. Choose **Quit ZonePin** to close it. Reopen with `open ~/Applications/ZonePin.app`. Quit before running the installer again for an update.

If the time is hidden on a MacBook with a camera notch, free some menu bar space, then Command-drag ZonePin's time toward the right. Its status item position is saved. The system clock can be set to a small analog face using **System Settings → Menu Bar → Clock Options → Analog** on macOS 26; on other versions, search System Settings for **Clock Options**. To show Beijing time on the desktop, add Apple's **City Clock** widget and choose Beijing or Shanghai. The Lock Screen clock still uses the system time zone.

For people who previously tested **World Menu Clock**, quit that app and turn off its **Launch at Login** setting before starting ZonePin to avoid two menu bar clocks. ZonePin retains the same bundle identifier and saved preference keys so its time-zone choice and menu bar position can carry over.

## Build from source

From the repository root:

```sh
./scripts/test.sh
./scripts/build.sh
```

The app is written to `dist/ZonePin.app`. Move or copy it to a stable Applications location before relying on Launch at Login. Regenerate `app/Resources/AppIcon.icns` from the committed PNG source with `./scripts/generate-icon.sh` if the icon changes. Temporary build artifacts are created under `tmp/`; both `tmp/` and `dist/` are Git-ignored.

The formatter tests cover the fixed format, Beijing date rollover, Pacific daylight-saving transition, and invalid saved time-zone fallback. Local test builds and tests have run on macOS 26. Runtime behavior on macOS 13 should be checked on an actual macOS 13 Mac before claiming it is fully verified there; the build targets macOS 13.

## npm registry

The repository root is also an npm package with CLI `zonepin`. Once its owner authenticates to npm and publishes it, users can run `npx zonepin`. Until then, use the GitHub form `npx --yes github:ALHDLIOX/zonepin`. Inspect the package first with `npm pack --dry-run --json`; do not publish private files or credentials. The npm package contains the source and icon, and builds the app on each user's Mac.

## Optional signed binary release

If a maintainer later joins the Apple Developer Program, they can create a **Developer ID Application** certificate and a `notarytool` keychain profile. Then:

```sh
DEVELOPER_ID_APPLICATION='Developer ID Application: Your Name (TEAMID)' \
NOTARY_PROFILE='your-keychain-profile' \
./scripts/release.sh
```

The script signs the universal app with hardened runtime and secure timestamp, submits a ZIP to Apple for notarization, staples the ticket to the app, validates Gatekeeper assessment, and writes a ZIP in `dist/`. This optional release has not run because the signing identity is unavailable on the current Mac. Keep keys and passwords out of the repository.
