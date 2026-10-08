import SwiftUI

/// "My Songs": the player's beats as cards. Tap to open; long-press to rename, duplicate or delete.
struct LibraryView: View {
    let store: SongStore
    let background: BackgroundOption?
    let season: Season?
    let onOpen: (Song) -> Void
    let onBack: () -> Void

    @State private var songs: [Song] = []
    @State private var renaming: Song?
    @State private var newName = ""
    @State private var deleting: Song?
    @State private var confirmingReset = false
    @State private var shelf: [Song] = []                      // the live holiday's ready-made songs (templates, not saved)

    private let ink = Color(red: 0.95, green: 0.96, blue: 1)
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) { Image(systemName: "chevron.left").font(.system(size: 16, weight: .heavy)).frame(width: 40, height: 40) }
                    .buttonStyle(Chip()).accessibilityLabel("Menu")
                Spacer()
                Text("My Songs").font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(ink)
                Spacer()
                Button("+ New") { onOpen(store.newSong()) }.buttonStyle(Chip(primary: true))
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            if songs.isEmpty && season == nil {
                Spacer()
                VStack(spacing: 14) {
                    Text("No songs yet").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(ink)
                    Button("+ New Song") { onOpen(store.newSong()) }.buttonStyle(Chip(primary: true))
                }
                Spacer()
            } else {
                ScrollView {
                    if let season {
                        sectionTitle("\(season.emoji) \(season.title)")
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(shelf) { t in
                                SongCard(song: t).onTapGesture { onOpen(store.addCopy(of: t)) }
                                    .accessibilityAddTraits(.isButton).accessibilityHint("Adds your own copy")
                            }
                        }
                        .padding(.horizontal, 16)
                        if shelf.isEmpty { ProgressView().padding() }
                        sectionTitle("Your songs")
                    }
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(songs) { s in
                            SongCard(song: s)
                                .onTapGesture { onOpen(s) }
                                .contextMenu {
                                    Button { newName = s.name; renaming = s } label: { Label("Rename", systemImage: "pencil") }
                                    Button { _ = store.duplicate(s.id); reload() } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                                    Button(role: .destructive) { deleting = s } label: { Label("Delete", systemImage: "trash") }
                                }
                                .accessibilityAddTraits(.isButton)
                        }
                    }
                    .padding(16)
                    Button("Reset Twinkle Twinkle") { confirmingReset = true }
                        .font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(ink.opacity(0.6))
                        .padding(.bottom, 24)
                }
            }
        }
        .background { Backdrop(option: background) }
        .onAppear(perform: reload)
        .task(id: season?.id) {
            guard let season else { shelf = []; return }
            shelf = await Task.detached(priority: .userInitiated) { Seasons.shelf(for: season) }.value
        }
        .alert("Rename song", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("Name", text: $newName)
            Button("Save") { if let r = renaming { store.rename(r.id, to: newName) }; reload() }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete “\(deleting?.name ?? "")”?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            Button("Delete", role: .destructive) { if let d = deleting { store.delete(d.id) }; reload() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This can't be undone.") }
        .alert("Reset Twinkle Twinkle?", isPresented: $confirmingReset) {
            Button("Reset", role: .destructive) { store.resetDemo(); reload() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Your changes to it will be lost.") }
    }

    private func reload() { songs = store.all() }

    private func sectionTitle(_ t: String) -> some View {
        Text(t).font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(ink)
            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 16).padding(.top, 12)
    }
}

/// A song as a card: a little drawing of the course, its name, notes and stars.
struct SongCard: View {
    let song: Song
    private let notes: Int, onBeat: Int

    init(song: Song) {
        self.song = song
        let run = Engine.simulate(song.course)
        notes = run.hits.count
        onBeat = run.hits.filter { Engine.isOnBeat($0.time) }.count
    }

    private let ink = Color(red: 0.95, green: 0.96, blue: 1)
    private let muted = Color(red: 0.6, green: 0.65, blue: 0.78)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CoursePreview(course: song.course)
                .frame(height: 150).frame(maxWidth: .infinity)
                .background(Color(red: 0.04, green: 0.05, blue: 0.11))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            HStack {
                Text(song.name).font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(ink).lineLimit(1)
                Spacer()
                Image(systemName: song.instrument.symbol).foregroundStyle(muted).accessibilityLabel(song.instrument.title)
            }
            HStack {
                Text("\(notes) notes").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(muted)
                Spacer()
                if notes > 0 {
                    let stars = Celebration.stars(onBeat: onBeat, total: notes)
                    HStack(spacing: 1) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < stars ? "star.fill" : "star").font(.system(size: 10)).foregroundStyle(i < stars ? Color.yellow : muted)
                        }
                    }
                    .accessibilityLabel("\(stars) of 3 stars")
                }
            }
        }
        .padding(10)
        .background(Color(red: 0.055, green: 0.07, blue: 0.15).opacity(0.92), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15)))
    }
}

/// The course drawn small: pads as coloured strokes, the hopper as a dot.
struct CoursePreview: View {
    let course: Course
    var body: some View {
        Canvas { ctx, size in
            let bottom = (course.pads.map(\.y).max() ?? course.dropY) + 80
            let fit = CourseFit(top: course.dropY - 40, bottom: max(bottom, course.dropY + 400), size: size, margin: 10)
            func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: fit.screenX(x), y: fit.screenY(y)) }
            for p in course.pads {
                let color = Color(hue: Notes.hue(p), saturation: 0.82, brightness: 1)
                if p.kind != .bumper {
                    var path = Path()
                    if p.kind == .bar { let e = p.ends; path.move(to: pt(e.0, e.1)); path.addLine(to: pt(e.2, e.3)) } else {
                        let pts = p.rampPoints(); path.move(to: pt(pts[0].x, pts[0].y)); for q in pts.dropFirst() { path.addLine(to: pt(q.x, q.y)) }
                    }
                    ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: max(2, Rules.thickness * fit.scale), lineCap: .round, lineJoin: .round))
                } else {
                    let r = Notes.bumperRadius(p.note) * fit.scale, c = pt(p.x, p.y)
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .color(color))
                }
            }
            let h = pt(course.dropX, course.dropY)
            ctx.fill(Path(ellipseIn: CGRect(x: h.x - 3, y: h.y - 3, width: 6, height: 6)), with: .color(.white))
        }
        .accessibilityHidden(true)
    }
}
