// main.swift - Starts the asc-for-mac app with AppKit (see doc/architecture.md, "UI technology").

import AppKit

let application = NSApplication.shared
let appDelegate = AppDelegate()
application.delegate = appDelegate
application.setActivationPolicy(.regular)
application.run()
