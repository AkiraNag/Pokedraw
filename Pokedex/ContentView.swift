import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DrawView()
                .tabItem {
                    Label("Sortear", systemImage: "shuffle")
                }

            GalleryView()
                .tabItem {
                    Label("Coleção", systemImage: "square.grid.3x3.fill")
                }

            AboutView()
                .tabItem {
                    Label("Sobre", systemImage: "person.circle")
                }
        }
        .tint(Color(red: 1.0, green: 0.86, blue: 0.0))
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environment(DrawingStore())
}
