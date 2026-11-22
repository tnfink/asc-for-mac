// MainMenu.swift - The menu bar of asc-for-mac, built with AppKit.

import AppKit

@MainActor
enum MainMenu {
    /// Creates the menu bar with the app menu (About, Licenses, Quit with Cmd+Q) and the View
    /// menu (Enter/Exit Full Screen with Ctrl+Cmd+F).
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
        mainMenu.addItem(makeViewMenuItem())
        return mainMenu
    }

    /// The title of the View menu.
    static let viewMenuTitle = "View"

    /// The View menu with the standard full-screen item. Its action goes to the key window (the
    /// game window), which AppKit switches between full screen and a window; AppKit also
    /// changes the title to "Exit Full Screen" while the window is in full screen (TASK-0028).
    private static func makeViewMenuItem() -> NSMenuItem {
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: viewMenuTitle)
        let fullScreenItem = NSMenuItem(
            title: "Enter Full Screen",
            action: #selector(NSWindow.toggleFullScreen(_:)),
            keyEquivalent: "f"
        )
        fullScreenItem.keyEquivalentModifierMask = [.control, .command]
        viewMenu.addItem(fullScreenItem)
        viewMenuItem.submenu = viewMenu
        return viewMenuItem
    }
}
