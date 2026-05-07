import SwiftUI
import PhotosUI

// MARK: - Gallery Filter

enum GalleryFilter: CaseIterable {
    case all, drawn
    var icon: String {
        switch self {
        case .all:   return "square.grid.3x3"
        case .drawn: return "pencil"
        }
    }
    var label: LocalizedStringKey {
        switch self {
        case .all:   return "Todos"
        case .drawn: return "Desenhados"
        }
    }
}

// MARK: - GalleryView

struct GalleryView: View {
    @Environment(DrawingStore.self) var store

    @State private var filter: GalleryFilter = .all
    @State private var showShiny = false

    private let columns = [GridItem(.adaptive(minimum: 88, maximum: 108), spacing: 8)]

    private var pokemon: [PokemonEntry] {
        switch filter {
        case .all:   return PokemonData.all
        case .drawn: return PokemonData.all.filter { store.hasImage(pokemonId: $0.id, isShiny: showShiny) }
        }
    }

    private var completedCount: Int {
        showShiny ? store.completedShinyCount : store.completedNormalCount
    }

    var body: some View {
        ZStack {
            PokeBackground()
            VStack(spacing: 0) {
                headerArea
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 14)
                filterBar
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
                ScrollView {
                    if pokemon.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(pokemon) { entry in
                                GalleryCell(pokemon: entry, isShinyGallery: showShiny)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerArea: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Coleção")
                            .font(.system(size: 26, weight: .black))
                            .foregroundStyle(.white)
                        if showShiny {
                            Text("✨ Shiny")
                                .font(.caption.bold())
                                .foregroundStyle(PokeTheme.yellow)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(PokeTheme.yellow.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    Text("\(completedCount) de \(PokemonData.all.count) desenhados")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.4))
                }
                Spacer()
                Text(String(format: "%.1f%%",
                     Double(completedCount) / Double(PokemonData.all.count) * 100))
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundStyle(PokeTheme.yellow)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.07)).frame(height: 6)
                    Capsule()
                        .fill(showShiny ? PokeTheme.yellow : PokeTheme.blue)
                        .frame(width: max(0, geo.size.width * CGFloat(completedCount) / CGFloat(PokemonData.all.count)), height: 6)
                        .animation(.easeOut, value: completedCount)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 10) {
            // Normal / Shiny toggle
            HStack(spacing: 0) {
                ForEach([false, true], id: \.self) { shiny in
                    Button { withAnimation(.easeInOut(duration: 0.2)) { showShiny = shiny } } label: {
                        HStack(spacing: 4) {
                            if shiny { Text("✨").font(.caption) }
                            if shiny {
                                Text("Shiny").fontWeight(.semibold).font(.subheadline)
                            } else {
                                Text("Normal").fontWeight(.semibold).font(.subheadline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(showShiny == shiny ? (shiny ? PokeTheme.yellow : PokeTheme.blue) : Color.clear)
                        .foregroundStyle(showShiny == shiny ? (shiny ? Color.black : Color.white) : Color.white.opacity(0.5))
                    }
                }
            }
            .background(PokeTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(PokeTheme.border, lineWidth: 1))

            // All / Drawn icon filter
            HStack(spacing: 0) {
                ForEach(GalleryFilter.allCases, id: \.icon) { f in
                    Button { withAnimation(.easeInOut(duration: 0.2)) { filter = f } } label: {
                        Image(systemName: f.icon)
                            .font(.body.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(filter == f ? PokeTheme.blue : Color.clear)
                            .foregroundStyle(filter == f ? .white : Color.white.opacity(0.45))
                    }
                    .accessibilityLabel(f.label)
                }
            }
            .background(PokeTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(PokeTheme.border, lineWidth: 1))
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundStyle(PokeTheme.blue.opacity(0.4))
            Text("Nenhum desenho ainda")
                .font(.headline).foregroundStyle(Color.white.opacity(0.4))
            Text("Sorteie e salve seu primeiro Pokémon!")
                .font(.caption).foregroundStyle(Color.white.opacity(0.25))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

// MARK: - Gallery Cell

struct GalleryCell: View {
    let pokemon: PokemonEntry
    let isShinyGallery: Bool

    @Environment(DrawingStore.self) var store
    @State private var image: UIImage? = nil
    @State private var showSheet = false
    @State private var showDeleteConfirm = false

    private var hasImg: Bool { store.hasImage(pokemonId: pokemon.id, isShiny: isShinyGallery) }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(hasImg ? PokeTheme.cardBg : Color(hex: "#080F17"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            hasImg
                                ? (isShinyGallery ? PokeTheme.yellow.opacity(0.6) : PokeTheme.blue.opacity(0.6))
                                : PokeTheme.border.opacity(0.4),
                            lineWidth: 1
                        )
                )

            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .padding(6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .bottomLeading) {
                        Text("#\(formatId(pokemon.id))")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(.black.opacity(0.65))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                            .padding(4)
                    }
            } else {
                VStack(spacing: 4) {
                    Image(systemName: hasImg ? (isShinyGallery ? "sparkles" : "checkmark.circle.fill") : "circle.dashed")
                        .font(.title3)
                        .foregroundStyle(
                            hasImg
                                ? (isShinyGallery ? PokeTheme.yellow.opacity(0.8) : Color.green.opacity(0.7))
                                : Color.white.opacity(0.08)
                        )
                    Text("#\(formatId(pokemon.id))")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(hasImg ? PokeTheme.yellow.opacity(0.8) : Color.white.opacity(0.18))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onTapGesture { showSheet = true }
        .contextMenu {
            if hasImg {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Apagar desenho", systemImage: "trash")
                }
            }
        }
        .confirmationDialog("Apagar o desenho de \(pokemon.name)?",
                            isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Apagar", role: .destructive) {
                store.deleteEntry(pokemonId: pokemon.id, isShiny: isShinyGallery)
                image = nil
            }
        }
        .sheet(isPresented: $showSheet) {
            CellActionSheet(pokemon: pokemon, isShiny: isShinyGallery, initialImage: image)
        }
        .task(id: "\(pokemon.id)-\(isShinyGallery)") {
            image = store.image(for: pokemon.id, isShiny: isShinyGallery)
        }
        .onChange(of: hasImg) {
            image = hasImg ? store.image(for: pokemon.id, isShiny: isShinyGallery) : nil
        }
    }
}

// MARK: - Cell Action Sheet

struct CellActionSheet: View {
    let pokemon: PokemonEntry
    let isShiny: Bool
    let initialImage: UIImage?

    @Environment(DrawingStore.self) var store
    @Environment(\.dismiss) var dismiss

    @State private var displayImage: UIImage?
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var showDeleteConfirm = false
    @State private var isLoading = false

    private var hasImg: Bool { store.hasImage(pokemonId: pokemon.id, isShiny: isShiny) }

    init(pokemon: PokemonEntry, isShiny: Bool, initialImage: UIImage?) {
        self.pokemon = pokemon
        self.isShiny = isShiny
        self.initialImage = initialImage
        _displayImage = State(initialValue: initialImage)
    }

    var body: some View {
        ZStack {
            PokeTheme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                sheetHeader
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 20)

                if let img = displayImage {
                    imageContent(img)
                } else {
                    pickerContent
                }

                Spacer()
            }
        }
        .onChange(of: selectedPhoto) { loadAndSave() }
        .confirmationDialog("Apagar o desenho de \(pokemon.name)?",
                            isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Apagar", role: .destructive) {
                store.deleteEntry(pokemonId: pokemon.id, isShiny: isShiny)
                displayImage = nil
                dismiss()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var sheetHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("#\(formatId(pokemon.id))")
                        .font(.system(size: 26, weight: .black, design: .monospaced))
                        .foregroundStyle(PokeTheme.yellow)
                    if isShiny {
                        Label("Shiny", systemImage: "sparkles")
                            .font(.caption.bold())
                            .foregroundStyle(PokeTheme.yellow)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(PokeTheme.yellow.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                Text(pokemon.name)
                    .font(.headline).foregroundStyle(.white)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2).foregroundStyle(Color.white.opacity(0.35))
            }
        }
    }

    @ViewBuilder
    private func imageContent(_ img: UIImage) -> some View {
        Image(uiImage: img)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .background(PokeTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 20)

        VStack(spacing: 12) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.badge.plus")
                    Text("Alterar foto").fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(PokeTheme.cardBg)
                .foregroundStyle(PokeTheme.yellow)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(PokeTheme.yellow.opacity(0.35), lineWidth: 1))
            }
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                    Text("Apagar desenho").fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red.opacity(0.12))
                .foregroundStyle(.red)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.3), lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    @ViewBuilder
    private var pickerContent: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(PokeTheme.cardBg)
                    .frame(height: 180)
                if isLoading {
                    ProgressView().tint(PokeTheme.yellow)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundStyle(PokeTheme.blue.opacity(0.5))
                        Text("Sem foto ainda")
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.3))
                    }
                }
            }
            .padding(.horizontal, 20)

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                HStack(spacing: 8) {
                    Image(systemName: "photo.badge.plus").font(.body.bold())
                    Text("Adicionar foto").fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(PokeTheme.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20)
        }
    }

    private func loadAndSave() {
        Task {
            isLoading = true
            guard let item = selectedPhoto,
                  let data = try? await item.loadTransferable(type: Data.self),
                  let img  = UIImage(data: data)
            else { isLoading = false; return }
            let jpeg = img.jpegData(compressionQuality: 0.85)
            await MainActor.run {
                store.save(pokemonId: pokemon.id, isShiny: isShiny, imageData: jpeg)
                displayImage = img
                isLoading = false
                dismiss()
            }
        }
    }
}

#Preview {
    GalleryView().environment(DrawingStore())
}
