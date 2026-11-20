// AppDelegate.swift - App lifecycle, menu bar and windows of asc-for-mac.

import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var aboutWindow: NSWindow?
    /// Whether a quit request is waiting for ASC to end the game.
    private var isQuitPending = false
    /// Set when the player confirmed to quit although ASC did not end the game.
    private var isForcedQuit = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The menu bar is set before SDL starts, so SDL uses it instead of creating its own.
        NSApplication.shared.mainMenu = MainMenu.make(appDelegate: self)
        NSApplication.shared.activate()
        guard Game.shouldStart() else { return }
        // Start the game after launching has finished; it runs until the player quits. A run
        // loop timer is used instead of the main dispatch queue: while the game runs inside a
        // main queue block, no other main queue block could run, but run loop timers still fire
        // while SDL processes the events.
        perform(#selector(runGame), with: nil, afterDelay: 0)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard Game.isRunning, !isForcedQuit else { return .terminateNow }
        // Quit (Cmd+Q) while the game runs: let ASC end the game through its quit handling;
        // the app terminates when the game has ended (see runGame()).
        if !isQuitPending {
            isQuitPending = true
            Game.requestQuit()
            perform(#selector(confirmQuitIfGameStillRuns), with: nil, afterDelay: 1)
        }
        return .terminateCancel
    }

    /// ASC ignores the quit request while one of its dialogs (e.g. the start menu) is open.
    /// Then the player decides whether to quit anyway (user decision in TASK-0013).
    @objc private func confirmQuitIfGameStillRuns() {
        defer { isQuitPending = false }
        guard Game.isRunning else { return }
        let alert = NSAlert()
        alert.messageText = "Quit \(AppInfo.name) anyway?"
        alert.informativeText =
            "ASC did not end the game because one of its dialogs is open. Unsaved progress is lost."
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            isForcedQuit = true
            NSApplication.shared.terminate(nil)
        }
    }

    @objc func showAboutWindow(_ sender: Any?) {
        if aboutWindow == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: AboutView()))
            window.title = "About \(AppInfo.name)"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            aboutWindow = window
        }
        aboutWindow?.makeKeyAndOrderFront(sender)
    }

    @objc private func runGame() {
        do {
            let exitCode = try Game.run()
            if exitCode != 0 {
                NSLog("ASC ended with exit code %d", exitCode)
            }
        } catch {
            let alert = NSAlert(error: error)
            alert.messageText = "ASC could not be started"
            alert.runModal()
        }
        NSApplication.shared.terminate(nil)
    }
}
