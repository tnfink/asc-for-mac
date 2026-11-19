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
}
