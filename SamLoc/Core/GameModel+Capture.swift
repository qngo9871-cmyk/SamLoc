import Foundation

#if DEBUG
extension GameModel {
    /// Deterministic states for App Store screenshot capture, keyed by SL_CAPTURE value.
    func captureSetup(_ scenario: String) {
        difficulty = .normal
        matchScores = [42, -18, -12, -12]
        roundsWon = [1, 0, 0, 0]
        roundNumber = 2

        let deck = [Card].freshDeck()
        func hand(_ ranks: [Rank], _ suits: [Suit]) -> [Card] {
            zip(ranks, suits).map { Card(rank: $0, suit: $1) }
        }

        switch scenario {
        case "instantwin":
            players = [
                Player(id: 0, name: L(names[0]),
                       hand: hand([.three,.four,.five,.six,.seven,.eight,.nine,.ten,.jack,.queen],
                                  Array(repeating: .hearts, count: 10)),
                       isHuman: true),
                Player(id: 1, name: L(names[1]), hand: Array(deck.shuffled().prefix(6)), isHuman: false),
                Player(id: 2, name: L(names[2]), hand: Array(deck.shuffled().prefix(8)), isHuman: false),
                Player(id: 3, name: L(names[3]), hand: Array(deck.shuffled().prefix(9)), isHuman: false),
            ]
            instantWin = (0, .dragonStraight)
            roundOver = true
            roundLog = [String(format: L("log.instantWin"), players[0].name, L(InstantWinKind.dragonStraight.titleKey))]

        default: // "midgame"
            players = [
                Player(id: 0, name: L(names[0]),
                       hand: hand([.six,.seven,.nine,.jack,.jack,.king,.ace,.two],
                                  [.spades,.clubs,.hearts,.diamonds,.spades,.clubs,.hearts,.spades]),
                       isHuman: true),
                Player(id: 1, name: L(names[1]), hand: Array(deck.shuffled().prefix(6)), isHuman: false),
                Player(id: 2, name: L(names[2]), hand: Array(deck.shuffled().prefix(8)), isHuman: false),
                Player(id: 3, name: L(names[3]), hand: Array(deck.shuffled().prefix(5)), isHuman: false),
            ]
            tableCombo = Combo(cards: [Card(rank: .nine, suit: .diamonds)], shape: .single, topRank: .nine)
            lastPlayerToPlay = 1
            currentTurnIndex = 0
            roundLog = [String(format: L("log.played"), players[1].name, "9♦")]
        }
    }
}
#endif
