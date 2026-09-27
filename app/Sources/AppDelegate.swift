import AppKit
import ServiceManagement
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let selectedZoneKey = "selectedTimeZoneIdentifier"
    private let launchAtLoginKey = "launchAtLoginDesired"

    private var selectedIdentifier = ClockFormatter.defaultTimeZoneIdentifier
    private var statusItem: NSStatusItem!
    private var clockTimer: Timer?
    private var pickerWindow: NSWindow?
    private var selectedZoneMenuItem: NSMenuItem!
    private var launchAtLoginMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if let saved = UserDefaults.standard.string(forKey: selectedZoneKey),
           TimeZone(identifier: saved) != nil {
            selectedIdentifier = saved
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // Keep the user's menu bar placement stable across app restarts.
        statusItem.autosaveName = "WorldMenuClock.MainClock"
        statusItem.button?.font = NSFont.monospacedDigitSystemFont(
            ofSize: NSFont.systemFontSize,
            weight: .regular
        )
        configureMenu()
        updateClock()
        scheduleNextMinute()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(refreshAfterWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshAfterWake),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )

        if UserDefaults.standard.object(forKey: launchAtLoginKey) == nil {
            UserDefaults.standard.set(true, forKey: launchAtLoginKey)
        }
        if UserDefaults.standard.bool(forKey: launchAtLoginKey),
           SMAppService.mainApp.status != .enabled {
            do {
                try SMAppService.mainApp.register()
            } catch {
                NSLog("ZonePin: Could not enable launch at login: %@", error.localizedDescription)
            }
        }
        updateLoginMenuItem()

        if CommandLine.arguments.contains("--show-time-zone-picker") {
            DispatchQueue.main.async { [weak self] in
                self?.openPicker()
            }
        }


    }

    func applicationWillTerminate(_ notification: Notification) {
        clockTimer?.invalidate()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    private func configureMenu() {
        let menu = NSMenu()
        menu.delegate = self

        selectedZoneMenuItem = NSMenuItem(title: "Time Zone: \(selectedIdentifier)", action: nil, keyEquivalent: "")
        selectedZoneMenuItem.isEnabled = false
        menu.addItem(selectedZoneMenuItem)

        let chooseItem = NSMenuItem(title: "Choose Time Zone…", action: #selector(openPicker), keyEquivalent: "")
        chooseItem.target = self
        menu.addItem(chooseItem)
        menu.addItem(.separator())

        launchAtLoginMenuItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginMenuItem.target = self
        menu.addItem(launchAtLoginMenuItem)

        let guideItem = NSMenuItem(title: "Clock Setup Guide…", action: #selector(showSetupGuide), keyEquivalent: "")
        guideItem.target = self
        menu.addItem(guideItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit ZonePin", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        updateClock()
        updateLoginMenuItem()
    }

    private func updateClock() {
        statusItem.button?.title = ClockFormatter.string(for: Date(), timeZoneIdentifier: selectedIdentifier)
        statusItem.button?.toolTip = "ZonePin — \(selectedIdentifier)"
        selectedZoneMenuItem.title = "Time Zone: \(selectedIdentifier)"
    }

    private func scheduleNextMinute() {
        clockTimer?.invalidate()
        let now = Date().timeIntervalSince1970
        let secondsUntilNextMinute = 60 - now.truncatingRemainder(dividingBy: 60) + 0.05
        let timer = Timer(timeInterval: secondsUntilNextMinute, repeats: false) { [weak self] _ in
            self?.updateClock()
            self?.scheduleNextMinute()
        }
        clockTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    @objc private func refreshAfterWake() {
        updateClock()
        scheduleNextMinute()
    }

    @objc private func openPicker() {
        if let pickerWindow {
            pickerWindow.contentView = NSHostingView(rootView: makePickerView())
            pickerWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 480),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.title = "ZonePin — Choose Time Zone"
        window.contentView = NSHostingView(rootView: makePickerView())
        window.center()
        pickerWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makePickerView() -> TimeZonePickerView {
        TimeZonePickerView(selectedIdentifier: selectedIdentifier) { [weak self] identifier in
            guard let self else { return }
            self.selectedIdentifier = identifier
            UserDefaults.standard.set(identifier, forKey: self.selectedZoneKey)
            self.updateClock()
            self.pickerWindow?.close()
        }
    }

    private func updateLoginMenuItem() {
        guard launchAtLoginMenuItem != nil else { return }
        let status = SMAppService.mainApp.status
        launchAtLoginMenuItem.state = status == .enabled ? .on : .off
        launchAtLoginMenuItem.title = status == .requiresApproval
            ? "Launch at Login (Approval Needed)"
            : "Launch at Login"
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                UserDefaults.standard.set(false, forKey: launchAtLoginKey)
            } else {
                try SMAppService.mainApp.register()
                UserDefaults.standard.set(true, forKey: launchAtLoginKey)
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not change Launch at Login"
            alert.informativeText = "\(error.localizedDescription)\n\nCheck System Settings → General → Login Items & Extensions."
            alert.runModal()
        }
        updateLoginMenuItem()
    }

    @objc private func showSetupGuide() {
        let alert = NSAlert()
        alert.messageText = "Set up your Mac clocks"
        alert.informativeText = "To make the system clock less prominent, open System Settings → Menu Bar → Clock Options and choose Analog. To add a desktop clock, Control-click the wallpaper, choose Edit Widgets, add Apple's City Clock widget, then choose Beijing or Shanghai. Your Mac's system time zone is not changed by this app."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
