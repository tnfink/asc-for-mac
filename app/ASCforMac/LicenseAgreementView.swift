// LicenseAgreementView.swift - The window with the agreement shown at the first start
// (SwiftUI, TASK-0026).

import SwiftUI

struct LicenseAgreementView: View {
    let onShowLicence: () -> Void
    let onDecline: () -> Void
    let onAccept: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LicenseAgreement.title)
                .font(.title2)
            Text(LicenseAgreement.text)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("agreementText")
            HStack {
                Button("Show Licence", action: onShowLicence)
                Spacer()
                Button("Decline", action: onDecline)
                    .keyboardShortcut(.cancelAction)
                Button("Accept", action: onAccept)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460)
    }
}
