// AboutView.swift - The About window of asc-for-mac (SwiftUI).

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            // The app icon (app/ASCforMac/AppIcon.icon), taken from the running app.
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 128, height: 128)
                .accessibilityLabel("\(AppInfo.name) icon")
                .accessibilityIdentifier("appIcon")
            Text(AppInfo.name)
                .font(.title)
            Text("A macOS port of Advanced Strategic Command")
            Text(AppInfo.appVersionText)
                .accessibilityIdentifier("appVersion")
            Text("ASC core version \(AppInfo.ascVersion)")
                .accessibilityIdentifier("ascCoreVersion")
            Link("www.asc-hq.org", destination: URL(string: "https://www.asc-hq.org")!)
            Text("ASC is licensed under the GNU General Public License, version 2.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(minWidth: 380)
    }
}
