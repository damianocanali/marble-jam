import XCTest
@testable import MarbleJam

final class SongStoreTests: XCTestCase {
    private func store() -> SongStore { SongStore(folder: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)) }
    private func defaults() -> UserDefaults { let n = "test.\(UUID())"; let d = UserDefaults(suiteName: n)!; d.removePersistentDomain(forName: n); return d }

    func testNewSongsAreNumbered() {
        let s = store()
        XCTAssertEqual(s.newSong().name, "Untitled 1")
        XCTAssertEqual(s.newSong().name, "Untitled 2")
        let third = s.newSong(); s.delete(s.all().first { $0.name == "Untitled 1" }!.id)
        XCTAssertEqual(third.name, "Untitled 3")
        XCTAssertEqual(s.newSong().name, "Untitled 4")                         // one more than the highest in use
    }

    func testSaveAndLoadKeepEverything() throws {
        let s = store()
        var song = Song(name: "Mine", course: Engine.demo(), instrument: .guitar)
        song = try s.save(song)
        XCTAssertEqual(s.song(song.id), song)
    }

    func testOldFileWithoutInstrumentLoadsAsBells() throws {
        let s = store(), id = UUID()
        let json = #"{"id":"\#(id.uuidString)","name":"Old","created":0,"modified":0,"course":{"pads":[],"dropX":200,"dropY":60}}"#
        try Data(json.utf8).write(to: s.folder.appendingPathComponent("\(id.uuidString).json"))
        XCTAssertEqual(s.song(id)?.instrument, .bells)
    }

    func testRenameTrimsAndRefusesEmpty() {
        let s = store(), a = s.newSong()
        XCTAssertTrue(s.rename(a.id, to: "  Groove  "))
        XCTAssertEqual(s.song(a.id)?.name, "Groove")
        XCTAssertFalse(s.rename(a.id, to: "   "))
        XCTAssertEqual(s.song(a.id)?.name, "Groove")
    }

    func testDuplicateNamesCopies() throws {
        let s = store(); var a = s.newSong(); a.name = "Beat"; a = try s.save(a)
        XCTAssertEqual(s.duplicate(a.id)?.name, "Beat copy")
        XCTAssertEqual(s.duplicate(a.id)?.name, "Beat copy 2")
        XCTAssertEqual(s.all().count, 3)
    }

    func testDeleteRemovesTheSong() {
        let s = store(), a = s.newSong()
        s.delete(a.id)
        XCTAssertNil(s.song(a.id)); XCTAssertTrue(s.all().isEmpty)
    }

    func testAllIsNewestFirst() throws {
        let s = store(), a = s.newSong(), b = s.newSong()
        XCTAssertEqual(s.all().map(\.id), [b.id, a.id])
        _ = try s.save(a)                                                     // touching a makes it newest
        XCTAssertEqual(s.all().map(\.id), [a.id, b.id])
    }

    func testCorruptFileIsSkipped() throws {
        let s = store(), a = s.newSong()
        try Data("{ not json".utf8).write(to: s.folder.appendingPathComponent("\(UUID().uuidString).json"))
        XCTAssertEqual(s.all().map(\.id), [a.id])
    }

    func testMigrationMovesTheOldCourseAndAddsTheDemoOnce() throws {
        let s = store(), d = defaults()
        var old = Course(); old.pads = [Pad(kind: .bar, x: 300, y: 300, note: 7)]
        d.set(try JSONEncoder().encode(old), forKey: "course.v1")
        s.migrateIfNeeded(defaults: d)
        XCTAssertEqual(Set(s.all().map(\.name)), ["My First Song", "Twinkle Twinkle"])
        XCTAssertEqual(s.all().first { $0.name == "My First Song" }?.course, old)
        s.migrateIfNeeded(defaults: d)
        XCTAssertEqual(s.all().count, 2)                                       // only once
    }

    func testMigrationWithoutAnOldCourseAddsOnlyTheDemo() {
        let s = store()
        s.migrateIfNeeded(defaults: defaults())
        XCTAssertEqual(s.all().map(\.name), ["Twinkle Twinkle"])
    }

    func testResetDemoReplacesAChangedTwinkle() throws {
        let s = store()
        var t = s.resetDemo(); t.course.pads.removeAll(); t = try s.save(t)
        let fresh = s.resetDemo()
        XCTAssertEqual(s.all().filter { $0.name == "Twinkle Twinkle" }.count, 1)
        let demo = Engine.demo()                                               // pads get new ids each time: compare what matters
        XCTAssertEqual(fresh.course.pads.map { [$0.x, $0.y, $0.angle, Double($0.note)] }, demo.pads.map { [$0.x, $0.y, $0.angle, Double($0.note)] })
    }

    func testResetDemoNeverTouchesTheUsersOwnSongWithTheSameName() throws {
        let s = store()
        s.resetDemo()
        var mine = s.newSong(); mine.name = "Twinkle Twinkle"; mine.course.pads = [Pad(kind: .bar, x: 300, y: 300, note: 3)]
        mine = try s.save(mine)
        s.resetDemo()
        XCTAssertEqual(s.song(mine.id)?.course.pads.count, 1, "the player's song survives")
        XCTAssertEqual(s.all().filter { $0.isDemo }.count, 1, "exactly one demo")
    }

    func testTakingAShelfSongMakesAnOrdinarySong() {
        let s = store(), r = Seasons.all[2].songs[0]
        let template = Song(name: r.name, course: r.course(), instrument: r.instrument)
        let mine = s.addCopy(of: template)
        XCTAssertEqual(mine.name, "Jingle Bells")
        XCTAssertEqual(mine.instrument, .bells)
        XCTAssertFalse(mine.isDemo)
        XCTAssertEqual(s.song(mine.id)?.course.pads.count, r.melody.count)
    }

    func testTakingAShelfSongTwiceMakesACopy() {
        let s = store(), t = Song(name: "Silent Night", course: Course(), instrument: .bells)
        let first = s.addCopy(of: t), second = s.addCopy(of: t), third = s.addCopy(of: t)
        XCTAssertEqual([first.name, second.name, third.name], ["Silent Night", "Silent Night copy", "Silent Night copy 2"])
        XCTAssertEqual(Set([first.id, second.id, third.id]).count, 3)
    }
}
