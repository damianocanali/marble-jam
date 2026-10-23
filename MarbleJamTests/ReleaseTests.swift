import XCTest
@testable import MarbleJam

/// What App Store upload and review check before anyone plays the game.
final class ReleaseTests: XCTestCase {
    private func info(_ key: String) -> Any? { Bundle.main.object(forInfoDictionaryKey: key) }

    func testInfoPlistIsReadyForTheAppStore() {
        XCTAssertEqual(info("UIRequiresFullScreen") as? Bool, true, "portrait-only on iPad needs full screen, or the upload is refused (ITMS-90474)")
        XCTAssertEqual(info("ITSAppUsesNonExemptEncryption") as? Bool, false, "no encryption beyond iOS's own")
        XCTAssertEqual(info("CFBundleShortVersionString") as? String, "1.0")
    }

    func testPrivacyManifestDeclaresWhatTheAppUses() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"), "PrivacyInfo.xcprivacy ships in the app")
        let plist = try XCTUnwrap(PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: Any])
        XCTAssertEqual(plist["NSPrivacyTracking"] as? Bool, false)
        XCTAssertEqual((plist["NSPrivacyTrackingDomains"] as? [String])?.count, 0)
        XCTAssertEqual((plist["NSPrivacyCollectedDataTypes"] as? [Any])?.count, 0, "the developer collects no data")
        let apis = try XCTUnwrap(plist["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        let defaults = apis.first { $0["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults" }
        XCTAssertEqual(defaults?["NSPrivacyAccessedAPITypeReasons"] as? [String], ["CA92.1"], "settings the app reads and writes for itself")
    }

    func testTheTestStoreCatalogueDoesNotShip() {
        XCTAssertNil(Bundle.main.url(forResource: "Products", withExtension: "storekit"), "only the tests and the Run scheme use it")
    }

    func testPacksFitAppStoreConnectLimits() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "Products", withExtension: "storekit"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let products = try XCTUnwrap(json["products"] as? [[String: Any]])
        XCTAssertEqual(products.count, Skins.packs.count)
        for p in products {
            for l in (p["localizations"] as? [[String: Any]]) ?? [] {
                let name = l["displayName"] as? String ?? "", text = l["description"] as? String ?? ""
                XCTAssertLessThanOrEqual(name.count, 30, name)
                XCTAssertLessThanOrEqual(text.count, 45, "\(name): \(text)")
                XCTAssertFalse(text.isEmpty, name)
            }
        }
    }

    func testThePrivacyPolicyIsReadableInTheApp() {
        let text = PrivacyPolicy.text
        for phrase in ["does not collect", "iCloud", "Game Center", "purchases", "children"] {
            XCTAssertTrue(text.localizedCaseInsensitiveContains(phrase), phrase)
        }
        XCTAssertEqual(AppLinks.support.host, "damianocanali.github.io")
        XCTAssertEqual(AppLinks.privacy.host, "damianocanali.github.io")
    }
}
