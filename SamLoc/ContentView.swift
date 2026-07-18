import SwiftUI

struct ContentView: View {
    var body: some View {
        #if DEBUG
        if let lang = ProcessInfo.processInfo.environment["SL_LANG"], let l = AppLanguage(rawValue: lang) {
            LocalizationManager.shared.setLanguage(l)
        }
        if let capture = ProcessInfo.processInfo.environment["SL_CAPTURE"], capture != "home" {
            if capture == "upgrade" {
                return AnyView(UpgradeView().preferredColorScheme(.dark))
            }
            if capture == "rules" {
                return AnyView(RulesView().preferredColorScheme(.dark))
            }
            let game = GameModel()
            game.captureSetup(capture)
            return AnyView(NavigationStack { GameView(game: game) }.preferredColorScheme(.dark))
        }
        #endif
        return AnyView(HomeView())
    }
}

#Preview { ContentView() }
