import StoreKitTest
import XCTest
@testable import MarbleJam

final class SkinTests: XCTestCase {
    func testCatalogue() {
        XCTAssertEqual(Set(Skins.all.map(\.id)).count, Skins.all.count, "unique ids")
        XCTAssertEqual(Skins.all.first?.id, Skins.classic.id, "the free classic marble comes first")
        XCTAssertEqual(Skins.packs.map(\.id), ["glass", "space", "sports"])
        for pack in Skins.packs { XCTAssertEqual(Skins.all.filter { $0.unlock == .pack(pack.id) }.count, 4, pack.id) }
        for season in Seasons.all { XCTAssertEqual(Skins.all.filter { $0.unlock == .holiday(season.id) }.count, 1, season.id) }
    }

    func testEverySkinDraws() {
        for skin in Skins.all {
            let img = Skins.image(skin, size: 64)
            XCTAssertEqual(img.size.width, 64, skin.id)
            XCTAssertNotNil(img.cgImage, skin.id)
        }
    }

    func testWhoOwnsWhat() {
        let sunny = Skins.all.first { $0.unlock == .stars(10) }!, pumpkin = Skins.all.first { $0.unlock == .holiday("halloween") }!
        let earth = Skins.all.first { $0.id == "earth" }!
        XCTAssertTrue(Skins.isOwned(Skins.classic, stars: 0, holidaysDone: [], purchased: []))
        XCTAssertFalse(Skins.isOwned(sunny, stars: 9, holidaysDone: [], purchased: []))
        XCTAssertTrue(Skins.isOwned(sunny, stars: 10, holidaysDone: [], purchased: []))
        XCTAssertFalse(Skins.isOwned(pumpkin, stars: 90, holidaysDone: ["christmas"], purchased: []))
        XCTAssertTrue(Skins.isOwned(pumpkin, stars: 0, holidaysDone: ["halloween"], purchased: []))
        XCTAssertFalse(Skins.isOwned(earth, stars: 90, holidaysDone: [], purchased: []))
        XCTAssertTrue(Skins.isOwned(earth, stars: 0, holidaysDone: [], purchased: [Skins.packs[1].productID]))
    }

    func testAHolidayCountsAsDoneWhenEveryLevelHasAStar() {
        let n = "test.\(UUID())"; let d = UserDefaults(suiteName: n)!; d.removePersistentDomain(forName: n)
        let p = ChallengeProgress(defaults: d)
        let xmas = Challenges.holiday.filter { $0.season == "christmas" }
        for c in xmas.dropLast() { p.record(c.id, stars: 1) }
        XCTAssertFalse(p.holidaysDone().contains("christmas"))
        p.record(xmas.last!.id, stars: 2)
        XCTAssertEqual(p.holidaysDone(), ["christmas"])
    }
}

final class ParentalGateTests: XCTestCase {
    func testQuestionsAreWrittenInWordsAndChecked() {
        for seed in 0..<50 {
            let q = ParentalGate.question(seed: seed)
            XCTAssertFalse(q.text.contains { $0.isNumber }, "numbers are written out, so a young child can't just read them: \(q.text)")
            XCTAssertTrue(ParentalGate.check(" \(q.answer) ", against: q))
            XCTAssertFalse(ParentalGate.check("\(q.answer + 1)", against: q))
            XCTAssertFalse(ParentalGate.check("", against: q))
            XCTAssertGreaterThanOrEqual(q.answer, 36)
        }
    }
}

@MainActor
final class StorePurchaseTests: XCTestCase {
    func testTheTestCatalogueSellsEveryPack() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "Products", withExtension: "storekit"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let products = try XCTUnwrap(json["products"] as? [[String: Any]])
        XCTAssertEqual(Set(products.compactMap { $0["productID"] as? String }), Set(Skins.packs.map(\.productID)))
        XCTAssertTrue(products.allSatisfy { $0["type"] as? String == "NonConsumable" }, "packs are bought once and kept")
    }

    func testBuyingAPackUnlocksItAndRestoreKeepsIt() async throws {
        let session = try SKTestSession(configurationFileNamed: "Products")
        session.disableDialogs = true
        session.clearTransactions()
        let store = Store()
        await store.load()
        try XCTSkipIf(store.products.isEmpty, "Apple's StoreKit test service couldn't load Products.storekit on this simulator (SKTestSession error); the catalogue itself is checked by testTheTestCatalogueSellsEveryPack")
        XCTAssertEqual(Set(store.products.map(\.id)), Set(Skins.packs.map(\.productID)), "every pack is on sale")
        let glass = try XCTUnwrap(store.products.first { $0.id == Skins.packs[0].productID })
        XCTAssertFalse(store.purchased.contains(glass.id))
        await store.buy(glass)
        XCTAssertTrue(store.purchased.contains(glass.id))
        let again = Store()
        await again.refreshPurchases()
        XCTAssertTrue(again.purchased.contains(glass.id), "a purchase is still owned after the app restarts")
    }
}
