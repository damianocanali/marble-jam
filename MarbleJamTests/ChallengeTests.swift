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
        for c in Challenges.everything {
            XCTAssertEqual(c.stars(for: c.solution, placed: c.par), 3, "\(c.id) \(c.title): solution")
            let start = c.stars(for: c.start, placed: 0)
            XCTAssertEqual(start, 0, "\(c.id): no free stars at the start")
        }
    }

    func testLockedPiecesAndTrayMatchTheSolution() {
        for c in Challenges.everything {
            let movable = c.start.pads.filter { !c.locked.contains($0.id) }.count
            if case .fix = c.goal { XCTAssertGreaterThan(movable, 0, "\(c.id): something to fix") } else { XCTAssertEqual(movable, 0, "\(c.id): given pieces are locked") }
            switch c.goal {
            case .melody: XCTAssertEqual(c.start.pads.count + c.tray.count, c.solution.pads.count, c.id)
            case .fix: XCTAssertTrue(c.tray.isEmpty, c.id)
            case .target: XCTAssertEqual(c.tray.count, c.par + 2, "\(c.id): two spare pieces")
            }
        }
    }

    func testTrayPiecesLeftAtTheirHintSpotsNeverWin() {
        for c in Challenges.everything {
            guard case .target = c.goal else { continue }
            for mask in 1..<(1 << c.tray.count) {
                var course = c.start
                for (k, p) in c.tray.enumerated() where mask & (1 << k) != 0 { course.pads.append(p) }
                XCTAssertEqual(c.stars(for: course, placed: mask.nonzeroBitCount), 0, "\(c.id): tapping tray pieces \(mask) wins")
            }
        }
    }

    func testCupsAreWellInsideTheScreen() {
        for c in Challenges.everything {
            guard case let .target(x, _) = c.goal else { continue }
            XCTAssertTrue((70...650).contains(x), "\(c.id): cup at x \(Int(x))")
        }
    }

    func testEachHolidayHasASixLevelWorld() {
        for season in Seasons.all {
            let levels = Challenges.holiday.filter { $0.season == season.id }
            XCTAssertEqual(levels.map(\.number), Array(1...6), season.id)
            XCTAssertEqual(Set(levels.map(\.world)).count, 1, season.id)
            XCTAssertTrue(levels.allSatisfy { $0.world > 5 }, "holiday worlds come after the main five")
        }
        XCTAssertEqual(Challenges.all.count, 30, "the main worlds are unchanged")
        XCTAssertEqual(Set(Challenges.everything.map(\.id)).count, 48)
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

    func testAHolidayWorldOpensWithoutMainWorldStars() {
        let p = progress(), all = Challenges.everything
        let first = Challenges.holiday.first { $0.season == "christmas" && $0.number == 1 }!
        let second = Challenges.holiday.first { $0.season == "christmas" && $0.number == 2 }!
        XCTAssertTrue(p.isUnlocked(first, in: all))
        XCTAssertFalse(p.isUnlocked(second, in: all))
        p.record(first.id, stars: 1)
        XCTAssertTrue(p.isUnlocked(second, in: all))
    }
}

@MainActor
final class ChallengeModelTests: XCTestCase {
    private func progress() -> ChallengeProgress {
        let n = "test.\(UUID())"; let d = UserDefaults(suiteName: n)!; d.removePersistentDomain(forName: n); return ChallengeProgress(defaults: d)
    }
    private func level(_ id: String) -> Challenge { Challenges.all.first { $0.id == id }! }

    func testLockedPiecesRefuseEdits() {
        let m = GameModel(), c = level("w2-1")
        m.open(challenge: c, progress: progress())
        let locked = c.start.pads.first { c.locked.contains($0.id) }!
        m.selected = locked.id
        let before = m.course
        m.rotate(by: 0.3); m.stepNote(1); m.deleteSelected()
        XCTAssertEqual(m.course, before)
        XCTAssertTrue(m.isLocked(locked.id))
    }

    func testTrayPiecesArePlacedAndGoBack() {
        let m = GameModel(), c = level("w1-2")
        m.open(challenge: c, progress: progress())
        XCTAssertEqual(m.trayLeft.count, 2)
        m.placeFromTray(0)
        XCTAssertEqual(m.trayLeft.count, 1)
        XCTAssertEqual(m.course.pads.count, c.start.pads.count + 1)
        XCTAssertFalse(m.isLocked(m.selected!))
        m.deleteSelected()
        XCTAssertEqual(m.trayLeft.count, 2, "a deleted tray piece goes back to the tray")
        m.placeFromTray(0); m.placeFromTray(0)
        m.resetChallenge()
        XCTAssertEqual(m.course, c.start); XCTAssertEqual(m.trayLeft.count, 2)
    }

    func testFinishingScoresAndSavesTheLevel() {
        let m = GameModel(), c = level("w1-1"), p = progress()
        m.open(challenge: c, progress: p)
        let startIDs = Set(c.start.pads.map(\.id))
        for spot in c.solution.pads where !startIDs.contains(spot.id) {      // place each missing note where it belongs, like a player
            m.placeFromTray(0)
            m.updateSelected { $0.x = spot.x; $0.y = spot.y; $0.angle = spot.angle }
        }
        m.start(); m.finish()
        XCTAssertEqual(m.celebration?.stars, 3)
        XCTAssertEqual(p.stars(c.id), 3)
        XCTAssertNotNil(m.nextChallenge, "level 2 opens")
    }

    func testTheCupIsWithinScrollReach() {
        let m = GameModel(), c = Challenges.all.first { if case .target = $0.goal { true } else { false } }!
        m.open(challenge: c, progress: progress())
        guard case let .target(_, y) = c.goal else { return XCTFail() }
        XCTAssertGreaterThan(m.maxY, y)
    }

    func testTheHopperCantBeMovedInAChallenge() {
        let m = GameModel(), c = level("w3-2")
        m.open(challenge: c, progress: progress())
        m.setDrop(x: c.start.dropX + 150)
        XCTAssertEqual(m.course.dropX, c.start.dropX)
    }

    func testFixPadsCantBeDeleted() {
        let m = GameModel(), c = level("w2-1")
        m.open(challenge: c, progress: progress())
        let loose = c.start.pads.first { !c.locked.contains($0.id) }!
        m.selected = loose.id
        m.deleteSelected()
        XCTAssertTrue(m.course.pads.contains { $0.id == loose.id })
    }

    func testNotesCantChangeInMelodyOrFixLevels() {
        let m = GameModel(), c = level("w1-2")
        m.open(challenge: c, progress: progress())
        m.placeFromTray(0)
        let note = m.selectedPad!.note
        m.stepNote(1)
        XCTAssertEqual(m.selectedPad!.note, note)
        XCTAssertFalse(m.canChangeNote)
    }

    func testLockedPadsLeaveNoEmptyUndoSteps() {
        let m = GameModel(), c = level("w1-2")
        m.open(challenge: c, progress: progress())
        m.placeFromTray(0)                                                   // one real step
        m.selected = c.start.pads[0].id
        m.stepNote(1); m.stepNote(1)                                         // refused: no steps
        m.undo()
        XCTAssertEqual(m.trayLeft.count, c.tray.count, "undo took back the placement, not an empty step")
    }

    func testFinishingUnsolvedGivesAHintNotASticker() {
        let m = GameModel(), c = level("w1-1"), p = progress()
        m.open(challenge: c, progress: p)
        m.start(); m.finish()
        XCTAssertNil(m.celebration)
        XCTAssertNotNil(m.toast)
        XCTAssertEqual(p.stars(c.id), 0)
    }
}
