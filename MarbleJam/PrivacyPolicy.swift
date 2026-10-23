import Foundation

/// The game's public web pages (GitHub Pages of the repo), also entered in App Store Connect.
enum AppLinks {
    static let support = URL(string: "https://damianocanali.github.io/marble-jam/support/")!
    static let privacy = URL(string: "https://damianocanali.github.io/marble-jam/privacy/")!
}

/// The privacy policy, shown inside the app (Account screen) so it can be read offline. The web page says the same.
enum PrivacyPolicy {
    static let updated = "October 23, 2026"

    static let text = """
    Marble Beats does not collect any personal information. There are no accounts, ads, analytics, tracking or servers \
    of our own, and nothing you make or do in the game is sent to us.

    Your songs, stars and chosen marble
    These stay on your device. If you're signed in to iCloud, they're also kept in your own iCloud account so they appear \
    on your other devices. That data belongs to your Apple account; we can't see it. You can delete it by deleting your \
    songs in the game, or in Settings › [your name] › iCloud.

    Game Center
    If you choose to sign in to Game Center on the Account screen, your total stars and the worlds you finish are sent to \
    Apple's Game Center for the leaderboard and achievements, under your Game Center name. Game Center is Apple's service \
    and follows Apple's privacy policy. Nothing is sent if you don't sign in.

    Purchases
    Marble packs are optional in-app purchases handled by Apple. We never see your payment details; Apple only tells the \
    app which packs you own.

    Children
    Marble Beats is made for the whole family. Because we don't collect personal information from anyone, we don't \
    collect it from children either. Purchases are behind a grown-up question, and Apple's Ask to Buy works as usual.

    Changes
    If this policy ever changes, the new version will be in the app and on our website before the change takes effect.

    Questions
    Visit \(AppLinks.support.absoluteString)
    """
}
