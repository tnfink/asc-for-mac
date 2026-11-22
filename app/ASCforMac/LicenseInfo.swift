// LicenseInfo.swift - The licence information of all components of the app, read from
// Licenses.json in the app bundle (created by scripts/create-licenses.sh, see
// doc/buildAndTest.md).

import Foundation

struct LicenseInfo: Decodable, Sendable {
    /// The name of the licence information file in the app bundle's resources.
    static let resourceName = "Licenses.json"

    /// The SPDX ID of the package of the app as a whole, whose licence text is the GPL.
    static let appPackageID = "SPDXRef-app"

    struct App: Decodable, Sendable {
        let name: String
        let version: String
        let license: String
    }

    /// A component of the app, as listed in the SBOM (doc/sbom.spdx.json).
    struct Package: Decodable, Sendable, Identifiable, Hashable {
        /// The SPDX ID of the package in the SBOM.
        let id: String
        let name: String
        let version: String
        /// The licence as SPDX licence expression.
        let license: String
        let copyright: String
        /// Where the source code can be obtained, if known.
        let source: String?
        /// A remark, e.g. which of several licences applies.
        let note: String?
        /// The keys of the package's licence texts in `texts`.
        let textIds: [String]
    }

    enum LoadError: Error, LocalizedError {
        case missingResource
        case missingText(package: String)

        var errorDescription: String? {
            switch self {
            case .missingResource:
                "The licence information (\(LicenseInfo.resourceName)) is missing in the app."
            case .missingText(let package):
                "The licence text of \(package) is missing in the licence information."
            }
        }
    }

    let app: App
    /// General notices shown above the components, e.g. the warranty disclaimer.
    let notes: [String]
    let packages: [Package]
    /// The licence texts, shared by packages with the same text.
    let texts: [String: String]

    /// The full licence texts of a package.
    func licenseTexts(of package: Package) -> [String] {
        package.textIds.compactMap { texts[$0] }
    }

    /// Decodes the licence information and checks that every licence text is present.
    static func decode(_ data: Data) throws -> LicenseInfo {
        let info = try JSONDecoder().decode(LicenseInfo.self, from: data)
        for package in info.packages
        where package.textIds.isEmpty || package.textIds.contains(where: { info.texts[$0] == nil }) {
            throw LoadError.missingText(package: package.name)
        }
        return info
    }

    /// Reads the licence information from the resources of a bundle.
    static func load(from bundle: Bundle = .main) throws -> LicenseInfo {
        guard let url = bundle.url(forResource: resourceName, withExtension: nil) else {
            throw LoadError.missingResource
        }
        return try decode(Data(contentsOf: url))
    }
}
