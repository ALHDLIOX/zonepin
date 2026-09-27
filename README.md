# ZonePin

<img src="app/Resources/ZonePinIcon.png" alt="ZonePin icon" width="96">

A small macOS menu bar clock that pins **one selected time zone** to your menu bar. It starts with `Asia/Shanghai`, shows time as `Sun Sep 27 02:31`, and never changes the Mac's system time zone. The selected time zone is saved locally. Supports Apple silicon and Intel Macs running macOS 13 or later.

ZonePin 是一个 macOS 菜单栏时钟：默认显示北京时间，可搜索切换时区，不修改系统时区。

## Install from GitHub with Node.js

Requires Node.js 18+ and Xcode Command Line Tools (`xcode-select --install`). ZonePin compiles on your own Mac and uses a local ad-hoc signature. No Apple Developer Program subscription is needed for this source-build path.

```sh
npx --yes github:ALHDLIOX/zonepin
```

The command installs `~/Applications/ZonePin.app` and opens it. To update, choose **Quit ZonePin** from its menu, then run the command again. This GitHub command works independently of an npm registry release; `npx zonepin` will work only after the package is published there. The app does not appear in the Dock.

If you previously installed **World Menu Clock**, turn off its **Launch at Login** option and quit it before opening ZonePin. ZonePin retains its saved time-zone selection.

## Build from a clone

```sh
git clone https://github.com/ALHDLIOX/zonepin.git
cd zonepin
./scripts/test.sh
./scripts/build.sh
mkdir -p ~/Applications
ditto dist/ZonePin.app ~/Applications/ZonePin.app
open ~/Applications/ZonePin.app
```

Click the menu bar time to choose a time zone, toggle **Launch at Login**, or quit. If the menu bar is full, especially around a MacBook camera notch, hide other menu bar items or Command-drag the clock toward the right. ZonePin cannot change the Lock Screen's time zone independently of the system time zone. [More usage details](docs/usage.md).

The native app is ad-hoc signed when built locally. An optional Developer ID signing and notarization script is included for a future prebuilt release; it requires an Apple Developer Program membership. The source-build installation above does not use that script.

## License

MIT © 2026 ALHDLIOX. See [LICENSE](LICENSE).
