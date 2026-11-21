// MainMenu.swift - The menu bar of asc-for-mac, built with AppKit.

import AppKit

@MainActor
enum MainMenu {
    /// Creates the menu bar with the app menu (About, Licenses, Quit with Cmd+Q).
    static func make(appDelegate: AppDelegate) -> NSMenu {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: AppInfo.name)

        let aboutItem = NSMenuItem(
            title: "About \(AppInfo.name)",
            action: #selector(AppDelegate.showAboutWindow(_:)),
            keyEquivalent: ""
        )
        aboutItem.target = appDelegate
        appMenu.addItem(aboutItem)
        let licensesItem = NSMenuItem(
            title: "Licenses…",
            action: #selector(AppDelegate.showLicensesWindow(_:)),
            keyEquivalent: ""
        )
        licensesItem.target = appDelegate
        appMenu.addItem(licensesItem)
        appMenu.addItem(.separator())
        appMenu.addItem(
            NSMenuItem(
                title: "Quit \(AppInfo.name)",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        return mainMenu
    }
}
