// FacadeTests.swift - Tests of the facade between the Swift app and the ASC core.

import AscFacade
import Testing

struct FacadeTests {
    @Test func ascVersionComesFromTheAscCore() {
        let version = String(ascfacade.ascVersion())
        // The ASC core in thirdparty/asc/ has version 2.6.99.0 (see doc/thirdparty.md).
        #expect(version.hasPrefix("2."))
        #expect(version.split(separator: ".").count >= 3)
    }
}
