import StoreKit
import SwiftUI

/// The store: your marbles (tap to use one), rewards still to earn, and the packs for sale behind a grown-up question.
struct StoreView: View {
    @ObservedObject var store: Store
    let progress: ChallengeProgress
    let background: BackgroundOption?
    @Binding var skinID: String
    let onBack: () -> Void

    @State private var asking: Product?                        // the pack waiting for the grown-up question
    @State private var gate = ParentalGate.question()
    @State private var answer = ""
    @State private var wrong = false
    @Environment(\.theme) private var theme
    private let ink = Color(red: 0.95, green: 0.96, blue: 1)
    private let muted = Color(red: 0.6, green: 0.65, blue: 0.78)
    private let grid = [GridItem(.adaptive(minimum: 76), spacing: 12)]

    @State private var stars = 0
    @State private var holidaysDone: Set<String> = []
    private func owned(_ s: Skin) -> Bool { Skins.isOwned(s, stars: stars, holidaysDone: holidaysDone, purchased: store.purchased) }

    private static var images: [String: UIImage] = [:]            // drawn once per skin
    private static func picture(_ s: Skin) -> UIImage {
        if let i = images[s.id] { return i }
        let i = Skins.image(s, size: 168); images[s.id] = i
        return i
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) { Image(systemName: "chevron.left").font(.system(size: 16, weight: .heavy)).frame(width: 40, height: 40) }
                    .buttonStyle(Chip()).accessibilityLabel("Menu")
                Spacer()
                Text("Store").font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(ink)
                Spacer()
                Button("Restore") { Task { await store.restore() } }.buttonStyle(Chip())
                    .accessibilityHint("Restores purchases made with this Apple ID")
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    section("Your marbles") {
                        LazyVGrid(columns: grid, spacing: 12) {
                            ForEach(Skins.all.filter(owned)) { s in
                                Button { skinID = s.id } label: { tile(s, caption: s.name, selected: s.id == skinID) }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("\(s.name)\(s.id == skinID ? ", in use" : "")")
                            }
                        }
                    }
                    let toEarn = Skins.all.filter { !owned($0) && !isPack($0) }
                    if !toEarn.isEmpty {
                        section("Earn more") {
                            LazyVGrid(columns: grid, spacing: 12) {
                                ForEach(toEarn) { s in tile(s, caption: requirement(s), selected: false).opacity(0.55).accessibilityLabel("\(s.name): \(requirement(s))") }
                            }
                        }
                    }
                    ForEach(Skins.packs) { pack in packCard(pack) }
                    if !store.canPay {
                        Text("Purchases are turned off on this device.").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(muted)
                    }
                    ForEach([store.failed, store.message].compactMap { $0 }, id: \.self) { line in
                        Text(line).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(muted)
                    }
                }
                .padding(16)
            }
        }
        .background { Backdrop(option: background) }
        .task {
            stars = progress.mainStars(); holidaysDone = progress.holidaysDone()
            await store.load()
        }
        .alert("Ask a grown-up", isPresented: Binding(get: { asking != nil }, set: { if !$0 { asking = nil } })) {
            TextField("Answer", text: $answer).keyboardType(.numberPad)
            Button("Continue") {
                if let p = asking, ParentalGate.check(answer, against: gate) { Task { await store.buy(p) } } else { wrong = true }
                asking = nil
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text(gate.text) }
        .alert("That's not right", isPresented: $wrong) { Button("OK", role: .cancel) {} } message: { Text("Purchases need a grown-up.") }
    }

    private func isPack(_ s: Skin) -> Bool { if case .pack = s.unlock { true } else { false } }

    private func requirement(_ s: Skin) -> String {
        switch s.unlock {
        case let .stars(n): "\(n) ★"
        case let .holiday(id): "\(Seasons.all.first { $0.id == id }?.emoji ?? "") world, in season"
        default: ""
        }
    }

    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(ink)
            content()
        }
    }

    private func tile(_ s: Skin, caption: String, selected: Bool) -> some View {
        VStack(spacing: 6) {
            Image(uiImage: Self.picture(s)).resizable().frame(width: 56, height: 56)
                .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
            Text(caption).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(muted).lineLimit(1)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(theme.chipFill.color.opacity(0.9), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? theme.accent.color : theme.chipStroke.color.opacity(theme.chipStrokeOpacity), lineWidth: selected ? 3 : 1))
    }

    private func packCard(_ pack: SkinPack) -> some View {
        let product = store.products.first { $0.id == pack.productID }, bought = store.purchased.contains(pack.productID)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(pack.name).font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(ink)
                Spacer()
                if bought {
                    Label("Owned", systemImage: "checkmark.circle.fill").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(theme.accent.color)
                } else if let product, store.canPay {
                    Button(product.displayPrice) { gate = ParentalGate.question(); answer = ""; asking = product }
                        .buttonStyle(Chip(primary: true)).accessibilityLabel("Buy \(pack.name) for \(product.displayPrice)")
                } else if store.loaded {
                    Text("Unavailable").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(muted)
                } else {
                    ProgressView().tint(ink)
                }
            }
            HStack(spacing: 10) {
                ForEach(Skins.all.filter { $0.unlock == .pack(pack.id) }) { s in
                    Image(uiImage: Self.picture(s)).resizable().frame(width: 52, height: 52).accessibilityLabel(s.name)
                }
            }
        }
        .padding(14)
        .background(theme.chipFill.color.opacity(0.92), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(theme.chipStroke.color.opacity(theme.chipStrokeOpacity)))
    }
}
