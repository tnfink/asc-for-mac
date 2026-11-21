// LicensesView.swift - The window "Licenses…" (SwiftUI): the components of the app on the
// left, the licence information of the selected component on the right.

import SwiftUI

struct LicensesView: View {
    /// The licence information, or the error why it could not be read.
    let info: Result<LicenseInfo, any Error>
    @State private var selection: LicenseInfo.Package.ID?

    init(info: Result<LicenseInfo, any Error> = Result { try LicenseInfo.load() }) {
        self.info = info
    }

    var body: some View {
        Group {
            switch info {
            case .success(let info):
                content(info)
            case .failure(let error):
                Text(error.localizedDescription)
                    .padding(24)
                    .accessibilityIdentifier("licenseError")
            }
        }
        .frame(minWidth: 760, minHeight: 480)
    }

    private func content(_ info: LicenseInfo) -> some View {
        HSplitView {
            List(info.packages, selection: $selection) { package in
                VStack(alignment: .leading, spacing: 2) {
                    Text(package.name)
                    Text(package.license)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(package.id)
            }
            .accessibilityIdentifier("licensePackages")
            .frame(minWidth: 220, idealWidth: 260, maxWidth: 360)

            ScrollView {
                if let package = info.packages.first(where: { $0.id == selection }) {
                    PackageDetail(package: package, texts: info.licenseTexts(of: package))
                } else {
                    Overview(info: info)
                }
            }
            .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Shown while no component is selected: the app's licence and the general notices.
private struct Overview: View {
    let info: LicenseInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(info.app.name) \(info.app.version)")
                .font(.title2)
            Text("Licence of the app as a whole: \(info.app.license)")
                .accessibilityIdentifier("appLicense")
            ForEach(info.notes, id: \.self) { note in
                Text(note)
            }
            Text("Select a component on the left to see its licence.")
                .foregroundStyle(.secondary)
        }
        .textSelection(.enabled)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The licence information of one component.
private struct PackageDetail: View {
    let package: LicenseInfo.Package
    let texts: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(package.name)
                .font(.title2)
                .accessibilityIdentifier("licensePackageName")
            Text("Version: \(package.version)")
            Text("Licence: \(package.license)")
                .accessibilityIdentifier("licensePackageLicense")
            Text(package.copyright)
            if let source = package.source {
                Text("Source code: \(source)")
            }
            if let note = package.note {
                Text(note)
            }
            ForEach(Array(texts.enumerated()), id: \.offset) { _, text in
                Divider()
                Text(verbatim: text)
                    .font(.system(.body, design: .monospaced))
            }
        }
        .textSelection(.enabled)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
