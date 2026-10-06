import XCTest
@testable import MarbleJam

final class InstrumentTests: XCTestCase {
    func testEveryInstrumentSoundsWithoutClipping() {
        for inst in Instrument.allCases {
            for (midi, bar) in [(48, false), (60, false), (60, true), (72, true), (84, true)] {
                let s = inst.samples(midi: midi, bar: bar, sampleRate: 44100)
                XCTAssertFalse(s.isEmpty, "\(inst) \(midi)")
                XCTAssertFalse(s.contains { !$0.isFinite }, "\(inst) \(midi)")
                let peak = s.map(abs).max() ?? 0
                XCTAssertGreaterThan(peak, 0.05, "\(inst) \(midi) is silent")
                XCTAssertLessThanOrEqual(peak, 1.0, "\(inst) \(midi) clips")
            }
        }
    }

    func testDrumPiecesFollowTheNote() {
        XCTAssertEqual(Drum.piece(midi: 60, bar: true), .kick)
        XCTAssertEqual(Drum.piece(midi: 72, bar: true), .snare)
        XCTAssertEqual(Drum.piece(midi: 84, bar: true), .hat)
        XCTAssertEqual(Drum.piece(midi: 50, bar: false), .tom)
    }

    func testDrumLabelsReplaceNoteNames() {
        let kick = Pad(kind: .bar, x: 0, y: 0, note: 0), tom = Pad(kind: .bumper, x: 0, y: 0, note: 3)
        XCTAssertEqual(Notes.label(kick, instrument: .drums), "Kick")
        XCTAssertEqual(Notes.label(tom, instrument: .drums), "Tom")
        XCTAssertEqual(Notes.label(kick, instrument: .piano), Notes.name(kick))
    }

    func testNotesFadeOutInsteadOfClicking() {
        for inst in Instrument.allCases {
            for (midi, bar) in [(48, false), (84, true), (60, true)] {
                let s = inst.samples(midi: midi, bar: bar, sampleRate: 44100)
                let tail = s.suffix(220).map(abs).max() ?? 0                      // the last 5 ms
                XCTAssertLessThan(tail, 0.01, "\(inst) \(midi) ends with a click")
            }
        }
    }
}
