import XCTest
@testable import MarbleJam

final class RampTests: XCTestCase {
    /// A course with one ramp under the drop point: the marble falls onto its left part.
    private func course(angle: Double, bend: Double = 0, length: Double = 360) -> Course {
        var c = Course(); c.dropX = 200; c.dropY = 60
        c.pads = [Pad(kind: .ramp, x: 330, y: 300, angle: angle, note: 7, length: length, bend: bend)]
        return c
    }

    func testTheMarbleLandsOnceRollsAndLeavesAtTheEnd() {
        let c = course(angle: 0.35), run = Engine.simulate(c)
        XCTAssertEqual(run.hits.count, 1, "landing is one note; rolling makes no more")
        XCTAssertEqual(run.hits.first?.pad, 0)
        let end = c.pads[0].rampPoints().last!
        // after the run the marble has passed the far end of the ramp and dropped below it
        let last = run.position(at: run.duration)
        XCTAssertGreaterThan(last.x, end.x - 5)
        XCTAssertGreaterThan(last.y, end.y + 100)
    }

    func testASteeperRampIsFaster() {
        func timeToLeave(_ a: Double) -> Double {
            let c = course(angle: a), end = c.pads[0].rampPoints().last!, run = Engine.simulate(c)
            var t = 0.0
            while t < run.duration && run.position(at: t).x < end.x { t += 1.0 / 120 }
            return t
        }
        XCTAssertLessThan(timeToLeave(0.6), timeToLeave(0.25))
    }

    func testBendCurvesTheTrack() {
        let flat = Pad(kind: .ramp, x: 300, y: 300, angle: 0, note: 7, length: 300, bend: 0).rampPoints()
        let dip = Pad(kind: .ramp, x: 300, y: 300, angle: 0, note: 7, length: 300, bend: 0.6).rampPoints()
        XCTAssertEqual(flat[flat.count / 2].y, 300, accuracy: 0.5)
        XCTAssertGreaterThan(dip[dip.count / 2].y, 340, "a positive bend sags downward (y grows down)")
        XCTAssertEqual(dip.first!.x, 150, accuracy: 0.5); XCTAssertEqual(dip.last!.x, 450, accuracy: 0.5)
    }

    func testRampShapeIsSavedAndOldSongsStillLoad() throws {
        let ramp = Pad(kind: .ramp, x: 1, y: 2, angle: 0.3, note: 5, length: 280, bend: -0.4)
        XCTAssertEqual(try JSONDecoder().decode(Pad.self, from: JSONEncoder().encode(ramp)), ramp)
        let old = #"{"id":"\#(UUID().uuidString)","kind":"bar","x":10,"y":20,"angle":0,"note":3}"#
        let bar = try JSONDecoder().decode(Pad.self, from: Data(old.utf8))
        XCTAssertEqual(bar.kind, .bar)
    }

    func testRampsPlayInTheBarsOctave() {
        let ramp = Pad(kind: .ramp, x: 0, y: 0, note: 7), bar = Pad(kind: .bar, x: 0, y: 0, note: 7)
        XCTAssertEqual(Notes.midi(ramp), Notes.midi(bar))
        XCTAssertEqual(Notes.name(ramp), Notes.name(bar))
    }

    func testDroppingStraightDownOntoAFlatRampDoesNotThrowTheMarbleSideways() {
        for dx in stride(from: -120.0, through: 120, by: 7) {
            var c = Course(); c.dropX = 360 + dx; c.dropY = 60
            c.pads = [Pad(kind: .ramp, x: 360, y: 700, angle: 0, note: 7, length: 360, bend: 0)]
            let run = Engine.simulate(c)
            guard let land = run.hits.first else { return XCTFail("no landing at \(dx)") }
            let a = run.position(at: land.time + 0.1), b = run.position(at: land.time + 0.2)
            XCTAssertLessThan(abs(b.x - a.x) / 0.1, 5, "sideways speed after landing at x offset \(dx)")
            XCTAssertEqual(run.hits.count, 1, "one note at x offset \(dx)")
        }
    }

    func testAMarbleInADipStopsInsteadOfRockingForever() {
        var c = Course(); c.dropX = 370; c.dropY = 60
        c.pads = [Pad(kind: .ramp, x: 360, y: 300, angle: 0, note: 7, length: 360, bend: 0.5)]
        XCTAssertLessThan(Engine.simulate(c).duration, 20)
    }

    func testRampDrumLabelMatchesTheDrumThatPlays() {
        let ramp = Pad(kind: .ramp, x: 0, y: 0, note: 0)
        XCTAssertEqual(Notes.label(ramp, instrument: .drums), Drum.piece(midi: Notes.midi(ramp), bar: true).label)
    }
}
