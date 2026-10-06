import SwiftUI
import UIKit

/// The chosen background with its tint, or the night sky when none is chosen. Fills the whole screen.
struct Backdrop: View {
    let option: BackgroundOption?
    @State private var image: UIImage?

    static let night = Color(red: 0.04, green: 0.05, blue: 0.11)

    var body: some View {
        ZStack {
            Self.night
            if let option, let image {
                Color.clear.overlay { Image(uiImage: image).resizable().scaledToFill() }.clipped()   // fills without growing the layout
                Color.black.opacity(option.tint)
            }
        }
        .ignoresSafeArea()
        .task(id: option?.id) {
            guard let url = option?.image else { image = nil; return }
            image = await Task.detached(priority: .userInitiated) { UIImage(contentsOfFile: url.path)?.preparingForDisplay() }.value
        }
        .accessibilityHidden(true)
    }
}

/// Grid of thumbnails: the night sky first, then every bundled background. Tapping one selects it.
struct BackgroundPicker: View {
    let options: [BackgroundOption]
    @Binding var selectedID: String          // BackgroundLibrary.nightID or "" (never chose) mean the night sky
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    tile(id: BackgroundLibrary.nightID, label: "Night sky") {
                        Backdrop.night.overlay {
                            Text("Night sky").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    ForEach(options) { o in
                        tile(id: o.id, label: o.name) { Thumbnail(url: o.thumb) }
                    }
                }
                .padding(16)
            }
            .background(Backdrop.night.ignoresSafeArea())
            .navigationTitle("Backgrounds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func isSelected(_ id: String) -> Bool { id == selectedID || (id == BackgroundLibrary.nightID && selectedID.isEmpty) }

    private func tile<Content: View>(id: String, label: String, @ViewBuilder content: () -> Content) -> some View {
        Button { selectedID = id } label: {
            content()
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected(id) ? Color.cyan : Color.white.opacity(0.2), lineWidth: isSelected(id) ? 4 : 1))
                .overlay(alignment: .topTrailing) {
                    if isSelected(id) {
                        Image(systemName: "checkmark.circle.fill").font(.title2).foregroundStyle(.cyan, .white).padding(6)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected(id) ? .isSelected : [])
    }
}

private struct Thumbnail: View {
    let url: URL
    @State private var image: UIImage?
    var body: some View {
        ZStack {
            Backdrop.night
            if let image { Color.clear.overlay { Image(uiImage: image).resizable().scaledToFill() }.clipped() }
        }
        .task { image = await Task.detached { UIImage(contentsOfFile: url.path) }.value }
    }
}
