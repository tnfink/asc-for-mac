// LicenseInfoTests.swift - Tests of the licence information in the app bundle (created by
// scripts/create-licenses.sh) and of the window "Licenses…".

import AppKit
import Foundation
import SwiftUI
import Testing

@testable import ASCforMac

@MainActor
struct LicenseInfoTests {
    /// The repository root, derived from the location of this source file.
    private static let repositoryRoot = URL(filePath: #filePath)
        .deletingLastPathComponent()  // ASCforMacTests
        .deletingLastPathComponent()  // app
        .deletingLastPathComponent()  // repository root

    private struct SBOM: Decodable {
        let packages: [SBOMPackage]
    }

    @Test func theAppBundleContainsTheLicenceInformationOfEveryPackageOfTheSBOM() throws {
        let info = try LicenseInfo.load()
        let sbomData = try Data(contentsOf: Self.repositoryRoot.appending(path: "doc/sbom.spdx.json"))
        let sbom = try JSONDecoder().decode(SBOM.self, from: sbomData)

        // The same packages, in any order (the licence information lists ASC before the libraries).
        let listed = info.packages.map { [$0.id, $0.name, $0.version, $0.license] }
        let expected = sbom.packages.map { [$0.spdxID, $0.name, $0.versionInfo, $0.licenseDeclared] }
        #expect(listed.count == expected.count)
        #expect(Set(listed) == Set(expected))
    }

    @Test func everyPackageHasCopyrightLicenceTextAndForGplASourceLocation() throws {
        let info = try LicenseInfo.load()
        #expect(info.app.license == "GPL-2.0-or-later")
        for package in info.packages {
            #expect(!package.copyright.isEmpty, "\(package.name)")
            let texts = info.licenseTexts(of: package)
            #expect(!texts.isEmpty && texts.allSatisfy { !$0.isEmpty }, "\(package.name)")
            if package.license.contains("GPL") {
                #expect(package.source?.isEmpty == false, "\(package.name)")
            }
        }
        let asc = try #require(info.packages.first { $0.id == "SPDXRef-asc" })
        #expect(info.licenseTexts(of: asc).first?.contains("GNU GENERAL PUBLIC LICENSE") == true)
    }

    @Test func decodingDetectsAMissingLicenceText() {
        let json = """
            {"app": {"name": "A", "version": "1", "license": "MIT"}, "notes": [],
             "packages": [{"id": "SPDXRef-x", "name": "x", "version": "1", "license": "MIT",
                           "copyright": "c", "textIds": ["missing"]}],
             "texts": {}}
            """
        #expect(throws: LicenseInfo.LoadError.self) {
            try LicenseInfo.decode(Data(json.utf8))
        }
    }

    @Test func loadingFromABundleWithoutLicenceInformationFails() {
        let bundle = Bundle(for: BundleMarker.self)
        #expect(throws: LicenseInfo.LoadError.self) {
            try LicenseInfo.load(from: bundle)
        }
        #expect(LicenseInfo.LoadError.missingResource.errorDescription?.contains("Licenses.json") == true)
    }

    @Test func theAppMenuOpensTheLicencesWindow() throws {
        let delegate = AppDelegate()
        let appMenu = try #require(MainMenu.make(appDelegate: delegate).items.first?.submenu)
        let item = try #require(appMenu.items.first { $0.title == "Licenses…" })
        #expect(item.action == #selector(AppDelegate.showLicensesWindow(_:)))
        #expect(item.target === delegate)

        delegate.showLicensesWindow(nil)
        let window = try #require(NSApplication.shared.windows.first { $0.title == "Licenses" && $0.isVisible })
        window.close()
    }

    @Test func theLicencesViewShowsAnErrorWithoutLicenceInformation() {
        let view = LicensesView(info: .failure(LicenseInfo.LoadError.missingResource))
        let controller = NSHostingController(rootView: view)
        #expect(controller.view.fittingSize.width > 0)
    }
}

/// A package of the SBOM (doc/sbom.spdx.json), with the fields the tests compare.
private struct SBOMPackage: Decodable {
    let spdxID: String
    let name: String
    let versionInfo: String
    let licenseDeclared: String

    enum CodingKeys: String, CodingKey {
        case spdxID = "SPDXID"
        case name, versionInfo, licenseDeclared
    }
}

/// A class of the test bundle, whose resources contain no licence information.
private final class BundleMarker {}
