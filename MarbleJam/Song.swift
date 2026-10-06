import Foundation

/// One of the player's beats: a course, the instrument it plays with, and its name.
struct Song: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var created = Date()
    var modified = Date()
    var instrument: Instrument = .bells
    var course: Course

    init(name: String, course: Course, instrument: Instrument = .bells) {
        self.name = name; self.course = course; self.instrument = instrument
    }

    private enum CodingKeys: String, CodingKey { case id, name, created, modified, instrument, course }

    /// Older files have no instrument: they play with bells.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        created = try c.decode(Date.self, forKey: .created)
        modified = try c.decode(Date.self, forKey: .modified)
        instrument = try c.decodeIfPresent(Instrument.self, forKey: .instrument) ?? .bells
        course = try c.decode(Course.self, forKey: .course)
    }
}
