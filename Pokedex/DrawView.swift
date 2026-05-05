import SwiftUI
import PhotosUI

// MARK: - Theme

enum PokeTheme {
    static let blue   = Color(hex: "#2D69A6")
    static let yellow = Color(hex: "#FAC90E")
    static let bg     = Color(hex: "#060D14")
    static let cardBg = Color(hex: "#0D1A26")
    static let border = Color(hex: "#1A3550")
}

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        var v: UInt64 = 0; Scanner(string: h).scanHexInt64(&v)
        self.init(red: Double((v >> 16) & 0xFF) / 255,
                  green: Double((v >> 8)  & 0xFF) / 255,
                  blue:  Double( v        & 0xFF) / 255)
    }
}

// MARK: - Domain

struct DrawnResult: Identifiable {
    let id = UUID()
    let drawNumber: Int   // 1-based: first draw = 1
    let pokemon: PokemonEntry
    let isShiny: Bool
}

private enum DrawPhase {
    case idle, drawing, choosing, uploading, saved
}

// MARK: - DrawView

struct DrawView: View {
    @Environment(DrawingStore.self) var store

    @State private var history: [DrawnResult] = []
    @State private var isChoosingPhase = false
    @State private var chosenIndex: Int? = nil
    @State private var isConfirmed = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var uploadedImage: UIImage? = nil
    @State private var isSaved = false
    @State private var rollScale: CGFloat = 1.0

    private let maxDraws = 4  // 1 first + 3 re-sorts

    private var phase: DrawPhase {
        if isSaved                        { return .saved }
        if isConfirmed                    { return .uploading }
        if isChoosingPhase                { return .choosing }
        if !history.isEmpty               { return .drawing }
        return .idle
    }

    private var canDraw: Bool { history.count < maxDraws }

    private var confirmedResult: DrawnResult? {
        guard let i = chosenIndex, history.indices.contains(i) else { return nil }
        return history[i]
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            PokeBackground()
            ScrollView {
                VStack(spacing: 28) {
                    header
                    phaseContent
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .onAppear { restorePendingIfNeeded() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            Text("Sorteador")
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(.white)
            Text(headerSubtitle)
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.35))
                .animation(.easeInOut, value: phase)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    private var headerSubtitle: String {
        switch phase {
        case .idle:      return "\(PokemonData.all.count) Pokémon disponíveis"
        case .drawing:   return "\(history.count) de \(maxDraws) sorteios realizados"
        case .choosing:  return "Escolha qual você vai desenhar"
        case .uploading: return "Adicione seu desenho"
        case .saved:     return "Salvo! Continue desenhando"
        }
    }

    // MARK: - Phase routing

    @ViewBuilder
    private var phaseContent: some View {
        switch phase {
        case .idle:
            idleCard
            drawSlotIndicator
            sortButton(label: "Sortear", icon: "shuffle")

        case .drawing:
            currentDrawCard
            drawSlotIndicator
            drawingButtons

        case .choosing:
            choiceSection

        case .uploading:
            if let r = confirmedResult {
                confirmedBadge(r)
                uploadSection
            }

        case .saved:
            savedConfirmation
        }
    }

    // MARK: - Idle Card

    private var idleCard: some View {
        ZStack {
            cardBackground(highlighted: false)
            VStack(spacing: 12) {
                Image(systemName: "questionmark")
                    .font(.system(size: 56, weight: .black))
                    .foregroundStyle(PokeTheme.blue.opacity(0.4))
                Text("Pressione Sortear")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            .padding(.vertical, 44)
        }
    }

    // MARK: - Current Draw Card

    private var currentDrawCard: some View {
        guard let latest = history.last else { return AnyView(EmptyView()) }
        return AnyView(
            ZStack {
                cardBackground(highlighted: false)
                VStack(spacing: 10) {
                    if latest.isShiny {
                        shinyBadge
                    }
                    Text("#\(formatId(latest.pokemon.id))")
                        .font(.system(size: 54, weight: .black, design: .monospaced))
                        .foregroundStyle(PokeTheme.yellow)
                        .scaleEffect(rollScale)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: rollScale)
                    Text(latest.pokemon.name)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text(canDraw ? "Toque Re-sortear para tentar de novo" : "Último sorteio usado")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.3))
                        .padding(.top, 2)
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
            }
        )
    }

    // MARK: - Draw Slot Indicator (4 dots)

    private var drawSlotIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<maxDraws, id: \.self) { i in
                Capsule()
                    .frame(width: 36, height: 6)
                    .foregroundStyle(
                        i < history.count ? PokeTheme.yellow : PokeTheme.border
                    )
                    .animation(.easeInOut, value: history.count)
            }
        }
    }

    // MARK: - Drawing Buttons

    private var drawingButtons: some View {
        VStack(spacing: 14) {
            if canDraw {
                sortButton(label: "Re-sortear", icon: "arrow.clockwise")
            }

            // Always present: choose the current draw immediately
            Button(action: chooseCurrent) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill").font(.body.bold())
                    Text("Escolher este").fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(PokeTheme.yellow.opacity(0.12))
                .foregroundStyle(PokeTheme.yellow)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(PokeTheme.yellow.opacity(0.4), lineWidth: 1))
            }

            // Only shown when there are previous draws to compare
            if history.count > 1 {
                Button(action: { withAnimation { isChoosingPhase = true } }) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath").font(.caption.bold())
                        Text("Ver sorteios anteriores (\(history.count - 1))")
                            .font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(Color.white.opacity(0.4))
                }
            }
        }
    }

    private func sortButton(label: String, icon: String) -> some View {
        Button(action: draw) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.body.bold())
                Text(label).fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(PokeTheme.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    // MARK: - Choice Section

    private var choiceSection: some View {
        VStack(spacing: 16) {
            Text("Qual você vai desenhar?")
                .font(.title3.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(history.indices, id: \.self) { i in
                HistoryCard(result: history[i], isSelected: chosenIndex == i)
                    .onTapGesture { withAnimation(.spring(response: 0.25)) { chosenIndex = i } }
            }

            if let i = chosenIndex {
                Button(action: { confirmResult(at: i) }) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill").font(.body.bold())
                        Text("Confirmar este Pokémon").fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(PokeTheme.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if canDraw {
                Button("← Sortear mais") {
                    withAnimation { isChoosingPhase = false }
                }
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.3))
            } else {
                Button("Recomeçar sorteio") { reset() }
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.25))
            }
        }
    }

    // MARK: - Confirmed Badge

    private func confirmedBadge(_ r: DrawnResult) -> some View {
        ZStack {
            cardBackground(highlighted: true)
            VStack(spacing: 8) {
                if r.isShiny { shinyBadge }
                Text("#\(formatId(r.pokemon.id))")
                    .font(.system(size: 48, weight: .black, design: .monospaced))
                    .foregroundStyle(PokeTheme.yellow)
                Text(r.pokemon.name)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Label("Confirmado!", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
                    .padding(.top, 4)
            }
            .padding(.vertical, 36)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Upload Section

    private var uploadSection: some View {
        VStack(spacing: 16) {
            Divider().overlay(PokeTheme.border)

            if let image = uploadedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 280)
                    .background(PokeTheme.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(PokeTheme.yellow.opacity(0.3), lineWidth: 1))

                Button(action: saveEntry) {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.down.fill")
                        Text("Salvar Desenho").fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.green.opacity(0.75))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            } else {
                if let r = confirmedResult {
                    Text("Adicione o desenho\(r.isShiny ? " ✨ shiny" : "") de \(r.pokemon.name)")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                }

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.badge.plus").font(.body.bold())
                        Text("Escolher Foto").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(PokeTheme.cardBg)
                    .foregroundStyle(PokeTheme.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(PokeTheme.yellow.opacity(0.35), lineWidth: 1))
                }
                .onChange(of: selectedPhoto) { loadPhoto() }

                Button("Salvar sem foto") { saveEntry() }
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.25))
            }
        }
    }

    // MARK: - Saved

    private var savedConfirmation: some View {
        VStack(spacing: 16) {
            Image(systemName: confirmedResult?.isShiny == true ? "sparkles" : "checkmark.seal.fill")
                .font(.system(size: 52))
                .foregroundStyle(confirmedResult?.isShiny == true ? PokeTheme.yellow : .green)
            if let r = confirmedResult {
                Text("\(r.isShiny ? "✨ Shiny " : "")#\(formatId(r.pokemon.id)) salvo!")
                    .font(.headline).foregroundStyle(.white)
            }
            Text("Continue desenhando!")
                .font(.subheadline).foregroundStyle(Color.white.opacity(0.4))
            Button(action: reset) {
                Text("Novo Sorteio")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(PokeTheme.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Shared UI

    private var shinyBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
            Text("SHINY!")
        }
        .font(.caption.bold())
        .foregroundStyle(PokeTheme.yellow)
        .padding(.horizontal, 12).padding(.vertical, 4)
        .background(PokeTheme.yellow.opacity(0.15))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(PokeTheme.yellow.opacity(0.5), lineWidth: 1))
    }

    private func cardBackground(highlighted: Bool) -> some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(PokeTheme.cardBg)
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(highlighted ? Color.green.opacity(0.6) : PokeTheme.border, lineWidth: 1.5)
            )
            .shadow(color: PokeTheme.blue.opacity(0.15), radius: 20)
    }

    // MARK: - Logic

    private func chooseCurrent() {
        confirmResult(at: history.count - 1)
    }

    private func confirmResult(at index: Int) {
        guard history.indices.contains(index) else { return }
        chosenIndex = index
        store.savePending(PendingDraw(pokemonId: history[index].pokemon.id,
                                     isShiny: history[index].isShiny))
        withAnimation { isConfirmed = true }
    }

    private func restorePendingIfNeeded() {
        guard !isConfirmed, !isSaved,
              let pending = store.pendingDraw,
              let pokemon = PokemonData.byId[pending.pokemonId]
        else { return }
        history     = [DrawnResult(drawNumber: 1, pokemon: pokemon, isShiny: pending.isShiny)]
        chosenIndex = 0
        isConfirmed = true
    }

    private func draw() {
        rollScale = 1.2
        let pokemon = PokemonData.all.randomElement()!
        let shiny   = Int.random(in: 0..<8) == 0
        history.append(DrawnResult(drawNumber: history.count + 1, pokemon: pokemon, isShiny: shiny))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { rollScale = 1.0 }
    }

    private func loadPhoto() {
        Task {
            guard let item = selectedPhoto,
                  let data = try? await item.loadTransferable(type: Data.self),
                  let img  = UIImage(data: data) else { return }
            await MainActor.run { uploadedImage = img }
        }
    }

    private func saveEntry() {
        guard let r = confirmedResult else { return }
        let data = uploadedImage.flatMap { $0.jpegData(compressionQuality: 0.85) }
        store.save(pokemonId: r.pokemon.id, isShiny: r.isShiny, imageData: data)
        store.clearPending()
        withAnimation { isSaved = true }
    }

    private func reset() {
        store.clearPending()
        history         = []
        isChoosingPhase = false
        chosenIndex     = nil
        isConfirmed     = false
        selectedPhoto   = nil
        uploadedImage   = nil
        isSaved         = false
    }
}

// MARK: - History Card

struct HistoryCard: View {
    let result: DrawnResult
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text("#\(formatId(result.pokemon.id))")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundStyle(PokeTheme.yellow)
                    if result.isShiny {
                        Label("Shiny", systemImage: "sparkles")
                            .font(.caption.bold())
                            .foregroundStyle(PokeTheme.yellow)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(PokeTheme.yellow.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                Text(result.pokemon.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
            Spacer()
            Text("Sorteio \(result.drawNumber)")
                .font(.caption2)
                .foregroundStyle(Color.white.opacity(0.3))
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(PokeTheme.yellow)
            }
        }
        .padding(16)
        .background(isSelected ? PokeTheme.blue.opacity(0.18) : PokeTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? PokeTheme.yellow : PokeTheme.border,
                        lineWidth: isSelected ? 2 : 1)
        )
    }
}

// MARK: - Shared Background

struct PokeBackground: View {
    var body: some View { PokeTheme.bg.ignoresSafeArea() }
}

// MARK: - Helpers

func formatId(_ id: String) -> String {
    let parts = id.split(separator: ".", maxSplits: 1)
    guard let base = Int(parts[0]) else { return id }
    let s = String(format: "%04d", base)
    return parts.count == 2 ? "\(s).\(parts[1])" : s
}

#Preview {
    DrawView().environment(DrawingStore())
}
