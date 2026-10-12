import XCTest
@testable import MarbleJam

/// Stands in for iCloud's key-value store.
final class FakeCloud: KeyValueSync {
    var values: [String: Any] = [:]
    func dictionary(forKey key: String) -> [String: Any]? { values[key] as? [String: Any] }
    func string(forKey key: String) -> String? { values[key] as? String }
    func set(_ value: Any?, forKey key: String) { values[key] = value }
}

final class ProgressSyncTests: XCTestCase {
    private func defaults() -> UserDefaults {
        let d = UserDefaults(suiteName: "sync-\(UUID())")!
        return d
    }

    func testBestStarsFromEitherDeviceWin() {
        let cloud = FakeCloud(), d = defaults()
        cloud.values["challenges.v1"] = ["w1-1": 2, "w1-3": 1]
        let p = ChallengeProgress(defaults: d, cloud: nil)
        p.record("w1-1", stars: 1); p.record("w1-2", stars: 3)
        let synced = ChallengeProgress(defaults: d, cloud: cloud)
        synced.pullFromCloud()
        XCTAssertEqual(synced.stars("w1-1"), 2)
        XCTAssertEqual(synced.stars("w1-2"), 3)
        XCTAssertEqual(synced.stars("w1-3"), 1)
        XCTAssertEqual(cloud.dictionary(forKey: "challenges.v1") as? [String: Int], ["w1-1": 2, "w1-2": 3, "w1-3": 1], "the merged best goes back up")
    }

    func testNewStarsGoToTheCloud() {
        let cloud = FakeCloud(), p = ChallengeProgress(defaults: defaults(), cloud: cloud)
        p.record("w2-1", stars: 2)
        XCTAssertEqual(cloud.dictionary(forKey: "challenges.v1") as? [String: Int], ["w2-1": 2])
        p.record("w2-1", stars: 1)
        XCTAssertEqual(cloud.dictionary(forKey: "challenges.v1") as? [String: Int], ["w2-1": 2], "fewer stars never replace more")
    }

    func testGarbageInTheCloudIsIgnored() {
        let cloud = FakeCloud(), p = ChallengeProgress(defaults: defaults(), cloud: cloud)
        cloud.values["challenges.v1"] = ["w1-1": "lots", "w1-2": 9, "w1-3": -1, "w1-4": 2]
        p.pullFromCloud()
        XCTAssertEqual(p.stars("w1-1"), 0); XCTAssertEqual(p.stars("w1-2"), 3, "capped at three"); XCTAssertEqual(p.stars("w1-3"), 0)
        XCTAssertEqual(p.stars("w1-4"), 2)
    }
}

final class SongSyncTests: XCTestCase {
    private var root: URL!
    override func setUp() { root = FileManager.default.temporaryDirectory.appendingPathComponent("songsync-\(UUID())") }
    override func tearDown() { try? FileManager.default.removeItem(at: root) }

    private func store(_ name: String, mirror: String?) -> SongStore {
        let s = SongStore(folder: root.appendingPathComponent(name))
        if let mirror { s.mirror = root.appendingPathComponent(mirror) }
        return s
    }

    func testSavesReachTheCloudAndOtherDevices() throws {
        let phone = store("phone", mirror: "cloud"), pad = store("pad", mirror: "cloud")
        let song = try phone.save(Song(name: "Rain", course: Course()))
        pad.syncWithMirror()
        XCTAssertEqual(pad.song(song.id)?.name, "Rain")
    }

    func testOlderSongsAlreadyOnThePhoneGoUpOnFirstSync() throws {
        let phone = store("phone", mirror: nil)
        let song = try phone.save(Song(name: "Old", course: Course()))
        phone.mirror = root.appendingPathComponent("cloud")
        phone.syncWithMirror()
        let pad = store("pad", mirror: "cloud"); pad.syncWithMirror()
        XCTAssertEqual(pad.song(song.id)?.name, "Old")
    }

    func testTheNewerCopyWins() throws {
        let phone = store("phone", mirror: "cloud"), pad = store("pad", mirror: "cloud")
        let song = try phone.save(Song(name: "First", course: Course()))
        pad.syncWithMirror()
        XCTAssertTrue(pad.rename(song.id, to: "Second"))
        phone.syncWithMirror()
        XCTAssertEqual(phone.song(song.id)?.name, "Second")
    }

    func testDeletedSongsStayDeleted() throws {
        let phone = store("phone", mirror: "cloud"), pad = store("pad", mirror: "cloud")
        let song = try phone.save(Song(name: "Gone", course: Course()))
        pad.syncWithMirror()
        phone.delete(song.id)
        pad.syncWithMirror()
        XCTAssertNil(pad.song(song.id), "the other device drops it too")
        phone.syncWithMirror()
        XCTAssertNil(phone.song(song.id), "and it doesn't come back")
    }

    func testSongsStillDownloadingAreSkipped() throws {
        let cloud = root.appendingPathComponent("cloud")
        try FileManager.default.createDirectory(at: cloud, withIntermediateDirectories: true)
        try Data().write(to: cloud.appendingPathComponent(".\(UUID().uuidString).json.icloud"))
        let pad = store("pad", mirror: "cloud"); pad.syncWithMirror()
        XCTAssertTrue(pad.all().isEmpty)
    }
}

final class GameCenterTests: XCTestCase {
    func testAchievementsForFinishedWorldsAndScoreForAllStars() {
        let p = ChallengeProgress(defaults: UserDefaults(suiteName: "gc-\(UUID())")!, cloud: nil)
        for n in 1...6 { p.record("w1-\(n)", stars: 2) }
        p.record("w2-1", stars: 3)
        for id in Challenges.holidayIDs("halloween") { p.record(id, stars: 1) }
        XCTAssertEqual(GameCenter.finishedWorlds(p), [1, 6])
        XCTAssertEqual(GameCenter.score(p), 12 + 3 + 6)
        XCTAssertEqual(GameCenter.achievementID(world: 3), "marblejam.world3")
    }

    func testRealProductIDs() {
        XCTAssertEqual(Store.productPrefix, "com.marblejam.app")
        XCTAssertTrue(Skins.packs.allSatisfy { $0.productID.hasPrefix("com.marblejam.app.pack.") })
    }
}
