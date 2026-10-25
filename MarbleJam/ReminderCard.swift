import SwiftUI

/// Asked once, after the first challenge win: only "Yes please" brings up Apple's prompt, so "Not now" keeps it for later.
struct ReminderCard: View {
    let onYes: () -> Void
    let onNo: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("🔔").font(.system(size: 44))
                Text("Want a heads-up when holiday songs arrive?")
                    .font(.system(size: 20, weight: .heavy, design: .rounded)).multilineTextAlignment(.center)
                Text("A few friendly reminders a month, never at night.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                HStack(spacing: 10) {
                    Button("Not now", action: onNo).buttonStyle(Chip())
                    Button("Yes please", action: onYes).buttonStyle(Chip(primary: true))
                }
            }
            .padding(22)
            .frame(maxWidth: 340)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color(red: 0.09, green: 0.1, blue: 0.16)))
            .padding(24)
        }
    }
}
