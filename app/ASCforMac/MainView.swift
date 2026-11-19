// MainView.swift - Placeholder content of the main window. The game itself runs here from
// TASK-0013 on.

import SwiftUI

struct MainView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text(AppInfo.name)
                .font(.largeTitle)
            Text("ASC core version \(AppInfo.ascVersion)")
            Text("The game will start here in a later version.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
