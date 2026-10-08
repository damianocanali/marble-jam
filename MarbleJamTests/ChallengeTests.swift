import XCTest
@testable import MarbleJam

final class ChallengeTests: XCTestCase {
    func testSongbookTunesAreAllOnTheBeat() {
        for r in Songbook.all {
            let run = Engine.simulate(r.course())
            XCTAssertEqual(run.hits.count, r.melody.count, r.name)
            XCTAssertTrue(run.hits.allSatisfy { Engine.isOnBeat($0.time) }, r.name)
        }
    }

    func testThirtyLevelsInFiveWorlds() {
        let all = Challenges.all
        XCTAssertEqual(all.count, 30)
        XCTAssertEqual(Set(all.map(\.id)).count, 30)
        for w in 1...5 { XCTAssertEqual(all.filter { $0.world == w }.map(\.number), Array(1...6), "world \(w)") }
    }

    func testEverySolutionEarnsThreeStarsAndNoStartDoes() {
        for c in Challenges.all {
            XCTAssertEqual(c.stars(for: c.solution, placed: c.par), 3, "\(c.id) \(c.title): solution")
            let start = c.stars(for: c.start, placed: 0)
            if case .fix = c.goal { XCTAssertLessThan(start, 3, "\(c.id): already fixed") } else { XCTAssertEqual(start, 0, "\(c.id): already solved") }
        }
    }

    func testLockedPiecesAndTrayMatchTheSolution() {
        for c in Challenges.all {
            let movable = c.start.pads.filter { !c.locked.contains($0.id) }.count
            if case .fix = c.goal { XCTAssertGreaterThan(movable, 0, "\(c.id): something to fix") } else { XCTAssertEqual(movable, 0, "\(c.id): given pieces are locked") }
            switch c.goal {
            case .melody: XCTAssertEqual(c.start.pads.count + c.tray.count, c.solution.pads.count, c.id)
            case .fix: XCTAssertTrue(c.tray.isEmpty, c.id)
            case .target: XCTAssertEqual(c.tray.count, c.par + 2, "\(c.id): two spare pieces")
            }
        }
    }

    func testTargetScoreDependsOnPiecesUsed() {
        let c = Challenges.all.first { if case .target = $0.goal { true } else { false } }!
        XCTAssertEqual(c.stars(for: c.solution, placed: c.par + 1), 2)
        XCTAssertEqual(c.stars(for: c.solution, placed: c.par + 2), 1)
    }
}

final class ChallengeProgressTests: XCTestCase {
    private func progress() -> ChallengeProgress {
        let n = "test.\(UUID())"; let d = UserDefaults(suiteName: n)!; d.removePersistentDomain(forName: n); return ChallengeProgress(defaults: d)
    }

    func testBestStarsAreKept() {
        let p = progress()
        p.record("w1-1", stars: 2); p.record("w1-1", stars: 1)
        XCTAssertEqual(p.stars("w1-1"), 2)
        p.record("w1-1", stars: 3)
        XCTAssertEqual(p.stars("w1-1"), 3)
    }

    func testLevelsOpenInOrderAndWorldsNeedStars() {
        let p = progress(), all = Challenges.all
        func open(_ id: String) -> Bool { p.isUnlocked(all.first { $0.id == id }!, in: all) }
        XCTAssertTrue(open("w1-1")); XCTAssertFalse(open("w1-2"))
        p.record("w1-1", stars: 1)
        XCTAssertTrue(open("w1-2"))
        for n in 2...6 { p.record("w1-\(n)", stars: 1) }                  // world 1 done with 6 stars: not enough for world 2 (needs 10)
        XCTAssertFalse(open("w2-1"))
        for n in 1...4 { p.record("w1-\(n)", stars: 2) }                  // now 10 stars
        XCTAssertTrue(open("w2-1"))
        XCTAssertEqual(p.totalStars(in: all.filter { $0.world == 1 }), 10)
    }
}
