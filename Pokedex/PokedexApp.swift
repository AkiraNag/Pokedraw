import SwiftUI

@main
struct PokedexApp: App {
    @State private var store = DrawingStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
