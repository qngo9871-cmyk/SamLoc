import SwiftUI

struct GameView: View {
    @ObservedObject var game: GameModel
    @State private var selected: Set<UUID> = []
    @Environment(\.dismiss) private var dismiss

    private var human: Player { game.players[0] }
    private var selectedCards: [Card] { human.hand.filter { selected.contains($0.id) } }
    private var isMyTurn: Bool { game.currentTurnIndex == 0 && !game.roundOver && !game.matchOver }

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.22, blue: 0.11).ignoresSafeArea()

            VStack(spacing: 0) {
                header
                opponentRow(index: 2, label: L("home.player.across"))
                Spacer()
                tableArea
                Spacer()
                HStack {
                    opponentRow(index: 1, label: L("home.player.left")).frame(maxWidth: .infinity)
                    opponentRow(index: 3, label: L("home.player.right")).frame(maxWidth: .infinity)
                }
                handArea
            }

            if game.roundOver && !game.matchOver { roundOverOverlay }
            if game.matchOver { matchOverOverlay }
        }
        .navigationBarBackButtonHidden(game.roundOver == false)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            Text(String(format: L("game.round"), game.roundNumber))
                .font(.caption).foregroundStyle(.white.opacity(0.8))
            Spacer()
            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { i in
                    Text("\(game.matchScores[i])")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(i == 0 ? .yellow : .white.opacity(0.6))
                }
            }
        }
        .padding(.horizontal).padding(.top, 8)
    }

    private func opponentRow(index: Int, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(label).font(.caption2).foregroundStyle(.white.opacity(0.7))
                if game.currentTurnIndex == index && !game.roundOver { Circle().fill(.yellow).frame(width: 6, height: 6) }
                if game.players[index].declaredSam { Text("👑").font(.caption2) }
            }
            HStack(spacing: -18) {
                ForEach(game.players[index].hand.prefix(10)) { card in
                    CardView(card: card, faceDown: true, width: 30)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var tableArea: some View {
        VStack(spacing: 6) {
            if let last = game.lastPlayerToPlay {
                Text(String(format: L("game.lastPlayed"), game.players[last].name)).font(.caption2).foregroundStyle(.white.opacity(0.5))
            }
            if let combo = game.tableCombo {
                HStack(spacing: -8) {
                    ForEach(combo.cards) { CardView(card: $0, width: 50) }
                }
            } else {
                Text(L("game.freeLead")).font(.caption).foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(minHeight: 90)
    }

    private var handArea: some View {
        VStack(spacing: 10) {
            if isMyTurn {
                Text(L("game.yourTurn")).font(.caption.bold()).foregroundStyle(.yellow)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -14) {
                    ForEach(human.hand) { card in
                        CardView(card: card, selected: selected.contains(card.id))
                            .onTapGesture { toggle(card) }
                    }
                }
                .padding(.horizontal)
            }
            HStack(spacing: 14) {
                if game.canDeclareSam(0) {
                    Button(L("game.declareSam")) { game.declareSam(0) }
                        .buttonStyle(.bordered).tint(.purple)
                }
                Button(L("game.pass")) {
                    game.pass(playerIndex: 0)
                    selected.removeAll()
                }
                .buttonStyle(.bordered).tint(.gray)
                .disabled(!isMyTurn || game.tableCombo == nil)

                Button(L("game.play")) {
                    if game.play(playerIndex: 0, cards: selectedCards) { selected.removeAll() }
                }
                .buttonStyle(.borderedProminent).tint(.green)
                .disabled(!isMyTurn || selectedCards.isEmpty)
            }
            .padding(.bottom, 10)
        }
        .padding(.top, 6)
        .background(Color.black.opacity(0.25))
    }

    private func toggle(_ card: Card) {
        if selected.contains(card.id) { selected.remove(card.id) } else { selected.insert(card.id) }
    }

    private var roundOverOverlay: some View {
        VStack(spacing: 16) {
            if let win = game.instantWin {
                Text("⚡️ " + L(win.kind.titleKey)).font(.title2.bold()).foregroundStyle(.yellow)
                Text(String(format: L("log.instantWin"), game.players[win.playerIndex].name, L(win.kind.titleKey)))
                    .multilineTextAlignment(.center)
            } else if let last = game.roundLog.last {
                Text(last).font(.title3.bold()).multilineTextAlignment(.center)
            }
            Button(L("game.nextRound")) { game.startRound() }
                .buttonStyle(.borderedProminent).tint(.green)
        }
        .foregroundStyle(.white)
        .padding(28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(40)
    }

    private var matchOverOverlay: some View {
        VStack(spacing: 16) {
            Text(L("game.matchOver")).font(.title.bold()).foregroundStyle(.yellow)
            ForEach(0..<4, id: \.self) { i in
                Text("\(L(game.names[i])): \(game.matchScores[i])")
                    .foregroundStyle(i == 0 ? .yellow : .white)
            }
            Button(L("game.done")) { dismiss() }
                .buttonStyle(.borderedProminent).tint(.green)
        }
        .padding(28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(40)
    }
}

#Preview {
    let g = GameModel()
    g.startMatch(difficulty: .easy)
    return NavigationStack { GameView(game: g) }.preferredColorScheme(.dark)
}
