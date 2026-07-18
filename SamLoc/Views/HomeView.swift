import SwiftUI

struct HomeView: View {
    @EnvironmentObject var loc: LocalizationManager
    @StateObject private var purchases = PurchaseManager.shared
    @State private var showGame = false
    @State private var showRules = false
    @State private var showUpgrade = false
    @State private var selectedDifficulty: AIDifficulty = .easy
    @State private var game = GameModel()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red: 0.05, green: 0.25, blue: 0.12), .black],
                                startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer()

                    VStack(spacing: 6) {
                        Text("🃏").font(.system(size: 56))
                        Text(L("home.title")).font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text(L("home.subtitle")).font(.subheadline).foregroundStyle(.white.opacity(0.7))
                    }

                    VStack(spacing: 10) {
                        Text(L("home.difficulty")).font(.caption).foregroundStyle(.white.opacity(0.6))
                        Picker("", selection: $selectedDifficulty) {
                            ForEach(AIDifficulty.allCases) { d in
                                Text(L(d.titleKey) + (d == .hard && !purchases.isPro ? " 🔒" : "")).tag(d)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 320)
                    }

                    VStack(spacing: 14) {
                        Button {
                            if selectedDifficulty == .hard && !purchases.isPro {
                                showUpgrade = true
                            } else {
                                game = GameModel()
                                game.startMatch(difficulty: selectedDifficulty)
                                showGame = true
                            }
                        } label: {
                            Text(L("home.play")).font(.title3.bold()).frame(maxWidth: 280).padding()
                        }
                        .buttonStyle(.borderedProminent).tint(.green)

                        Button { showRules = true } label: {
                            Text(L("home.rules")).foregroundStyle(.white.opacity(0.85))
                        }

                        if !purchases.isPro {
                            Button { showUpgrade = true } label: {
                                Text(L("home.upgrade")).font(.footnote).foregroundStyle(.yellow)
                            }
                        }
                    }

                    Spacer()

                    Picker("", selection: $loc.language) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 220)
                    .padding(.bottom, 24)
                }
                .padding()
            }
            .navigationDestination(isPresented: $showGame) {
                GameView(game: game)
            }
            .sheet(isPresented: $showRules) { RulesView() }
            .sheet(isPresented: $showUpgrade) { UpgradeView() }
            .task { await purchases.loadProduct() }
        }
    }
}

#Preview { HomeView().environmentObject(LocalizationManager.shared) }
