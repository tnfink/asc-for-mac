// AppInfo.swift - Information about the app and the ASC core, shown in the user interface.

import AscFacade
import Foundation

enum AppInfo {
    /// The name of the app shown in the menu bar and window titles.
    static let name = "ASC for Mac"

    /// The version of the ASC core, obtained through the facade.
    static var ascVersion: String {
        String(ascfacade.ascVersion())
    }

    /// The version of the app from its Info.plist.
    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    /// The build number of the app from its Info.plist: the counter of the Mac port's releases
    /// for the same ASC version (release 2.6.99.0-mac1 has version 2.6.99.0 and build number 1,
    /// see doc/buildAndTest.md).
    static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    }

    /// The app version as shown in About, e.g. "App version 2.6.99.0 (build 1)".
    static var appVersionText: String {
        "App version \(appVersion) (build \(buildNumber))"
    }
}
