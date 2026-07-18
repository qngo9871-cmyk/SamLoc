import SwiftUI

@main
struct SamLocApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(LocalizationManager.shared)
        }
    }
}
