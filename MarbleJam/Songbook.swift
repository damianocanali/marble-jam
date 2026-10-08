import Foundation

/// Short public-domain tunes for the challenges, transcribed from the Wikipedia scores, transposed to C and played at half
/// speed so their eighth notes stay on the beat grid. Notes are bar note indexes (0...14 = C4...C6).
enum Songbook {
    static let odeToJoy = SongRecipe(name: "Ode to Joy", instrument: .piano, melody: [
        (1, 9), (2, 9), (2, 10), (2, 11), (2, 11), (2, 10), (2, 9), (2, 8), (2, 7), (2, 7), (2, 8), (2, 9), (2, 9), (3, 8), (1, 8), (3, 9), (2, 9), (2, 10), (2, 11), (2, 11), (2, 10), (2, 9), (2, 8), (2, 7), (2, 7), (2, 8), (2, 9), (2, 8), (3, 7), (1, 7), (3, 8), (2, 8), (2, 9), (2, 7), (2, 8), (2, 9), (1, 10), (1, 9), (2, 7), (2, 8), (2, 9), (1, 10), (1, 9), (2, 8), (2, 7), (2, 8), (2, 4), (2, 9), (2, 9), (2, 9), (2, 10), (2, 11), (2, 11), (2, 10), (2, 9), (2, 8), (2, 7), (2, 7), (2, 8), (2, 9), (2, 8), (3, 7), (1, 7)])
    static let rowYourBoat = SongRecipe(name: "Row, Row, Row Your Boat", instrument: .marimba, melody: [
        (1, 7), (3, 7), (3, 7), (2, 8), (1, 9), (3, 9), (2, 8), (0.5, 9), (2, 10), (1, 11), (3, 14), (1.5, 14), (1, 14), (1, 11), (1, 11), (1, 11), (1, 9), (1, 9), (1, 9), (1, 7), (1, 7), (1, 7), (1, 11), (2, 10), (1, 9), (2, 8), (1, 7)])
    static let baaBaa = SongRecipe(name: "Baa, Baa, Black Sheep", instrument: .guitar, melody: [
        (1, 7), (2, 7), (2, 11), (2, 11), (2, 12), (1, 13), (1, 14), (1, 12), (1, 11), (3, 10), (2, 10), (2, 9), (2, 9), (2, 8), (2, 8), (2, 7), (3, 11), (2, 11), (1, 11), (1, 10), (2, 10), (1, 10), (1, 9), (2, 9), (1, 9), (1, 8), (3, 8), (1, 11), (2, 11), (1, 11), (1, 10), (1, 11), (1, 12), (1, 10), (1, 9), (2, 8), (1, 8), (1, 7)])
    static let popGoesTheWeasel = SongRecipe(name: "Pop Goes the Weasel", instrument: .chip, melody: [
        (1, 7), (2, 7), (1, 8), (2, 8), (1, 9), (1, 11), (1, 9), (1, 7), (3, 7), (2, 7), (1, 8), (2, 8), (1, 9), (3, 7), (3, 7), (2, 7), (1.5, 8), (2, 8), (1, 9), (1, 11), (1, 9), (1, 7), (3, 12), (3, 8), (2, 10), (1, 9), (3, 7)])
    static let hickoryDickory = SongRecipe(name: "Hickory Dickory Dock", instrument: .marimba, melody: [
        (1, 9), (1, 10), (1, 11), (1, 11), (1, 12), (1, 13), (1, 14), (3, 11), (1, 9), (1.5, 10), (1.5, 11), (1, 11), (1, 12), (1, 13), (1, 14), (3, 11), (1, 14), (2, 14), (1, 13), (2, 13), (1.5, 12), (2, 12), (1, 11), (3, 11), (1, 12), (1, 11), (1, 10), (1, 9), (1, 8), (1, 7)])
    static let happyBirthday = SongRecipe(name: "Happy Birthday", instrument: .bells, melody: [
        (1, 4), (1.5, 4), (1, 5), (2, 4), (2, 7), (2, 6), (3, 4), (1.5, 4), (0.5, 5), (2, 4), (2, 8), (2, 7), (3, 4), (1.5, 4), (0.5, 11), (2, 9), (2, 7), (2, 6), (2, 5), (3, 10), (1.5, 10), (0.5, 9), (2, 7), (2, 8), (2, 7)])
    static let twinkle = SongRecipe(name: "Twinkle Twinkle", instrument: .bells, melody: Engine.twinkle)

    static let all = [twinkle, odeToJoy, rowYourBoat, baaBaa, popGoesTheWeasel, hickoryDickory, happyBirthday]
}

extension SongRecipe {
    /// The first `n` notes as a recipe of their own.
    func prefix(_ n: Int) -> SongRecipe { SongRecipe(name: name, instrument: instrument, melody: Array(melody.prefix(n))) }
}
