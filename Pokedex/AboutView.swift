import SwiftUI

// MARK: - AboutView

struct AboutView: View {
    var body: some View {
        ZStack {
            PokeBackground()
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    linksSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "pencil.and.scribble")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(PokeTheme.yellow)
            Text("DexDraw")
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(.white)
            Text("by Akira Jensen")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    // MARK: - Links

    private var linksSection: some View {
        VStack(spacing: 12) {
            LinkRow(
                icon: "square.stack.3d.up.fill",
                label: "Meus apps",
                url: "https://apps.apple.com/br/developer/akira-jensen/id1810781469"
            )
            // Instagram
            // LinkRow(
            //     icon: "camera.fill",
            //     label: "@username",
            //     url: "https://instagram.com/username"
            // )
        }
    }
}

// MARK: - LinkRow

private struct LinkRow: View {
    let icon: String
    let label: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body.bold())
                    .foregroundStyle(PokeTheme.yellow)
                    .frame(width: 28)
                Text(label)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.bold())
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(PokeTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(PokeTheme.border, lineWidth: 1))
        }
    }
}

#Preview {
    AboutView()
}
