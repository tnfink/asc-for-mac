// LicenseAgreement.swift - The agreement shown at the first start (TASK-0026): the player
// accepts the app as it is under the GPL before the game starts. The text was approved by the
// user; see doc/architecture.md ("Licence agreement at the first start").

import Foundation

@MainActor
enum LicenseAgreement {
    static let title = "Before you play \(AppInfo.name)"

    static let text = """
        \(AppInfo.name) is free software under the GNU General Public License, version 2 or \
        later (GPL). It is provided "as is", without any warranty and without liability, as \
        stated in sections 11 and 12 of the GPL.

        By clicking "Accept", you accept \(AppInfo.name) as it is under these terms.
        """

    /// The `UserDefaults` key that records the acceptance.
    static let acceptedKey = "LicenseAgreementAccepted"

    /// The launch argument that shows the agreement regardless of the stored acceptance and
    /// does not store an acceptance, for the UI test (together with `Game.noGameArgument`).
    static let showAgreementArgument = "--show-agreement"

    /// What the app does after launching.
    enum StartAction: Equatable {
        /// Show the agreement; the game starts only after "Accept".
        case showAgreement
        /// Start the game right away.
        case startGame
        /// Neither (tests, `--no-game`).
        case nothing
    }

    static func isAccepted(in defaults: UserDefaults) -> Bool {
        defaults.bool(forKey: acceptedKey)
    }

    /// The action after launching: the agreement is shown before the game until it was
    /// accepted once, and always with `showAgreementArgument`.
    static func startAction(
        shouldStartGame: Bool,
        defaults: UserDefaults,
        arguments: [String] = CommandLine.arguments
    ) -> StartAction {
        if arguments.contains(showAgreementArgument) {
            return .showAgreement
        }
        guard shouldStartGame else { return .nothing }
        return isAccepted(in: defaults) ? .startGame : .showAgreement
    }

    /// Records the acceptance (not with `showAgreementArgument`) and returns whether the game
    /// is to be started now.
    static func accept(
        shouldStartGame: Bool,
        defaults: UserDefaults,
        arguments: [String] = CommandLine.arguments
    ) -> Bool {
        if !arguments.contains(showAgreementArgument) {
            defaults.set(true, forKey: acceptedKey)
        }
        return shouldStartGame
    }
}
