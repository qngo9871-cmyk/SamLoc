import Foundation

enum AIPlayer {
    /// Returns the combo the AI wants to play, or nil to pass.
    static func chooseMove(hand: [Card], mustBeat: Combo?, difficulty: AIDifficulty) -> Combo? {
        let options = legalPlays(hand: hand, mustBeat: mustBeat)
            .filter { !(hand.count == $0.cards.count && $0.isLoneTwo) } // can't finish on a lone 2
        guard !options.isEmpty else { return nil }

        switch difficulty {
        case .easy:
            // Plays the weakest legal option — easy to beat, rarely holds back bombs.
            return options.min { $0.topRank < $1.topRank || ($0.topRank == $1.topRank && $0.shape.sortKey < $1.shape.sortKey) }

        case .normal:
            // Prefers clearing small singles/pairs early, saves triples/straights/bombs for later.
            if mustBeat == nil {
                let nonBomb = options.filter { $0.shape != .fourOfAKind }
                return (nonBomb.isEmpty ? options : nonBomb).min { $0.topRank < $1.topRank }
            }
            return options.min { $0.topRank < $1.topRank }

        case .hard:
            return chooseHardMove(hand: hand, mustBeat: mustBeat, options: options)
        }
    }

    /// Hard AI reasons about hand shape: hangs onto bombs and the "heo" (2) as long as
    /// possible, prefers to burn off cards that don't combo with the rest of its hand,
    /// and leads with its longest straight when it has the table free (card-shape reading,
    /// not just picking the weakest legal move).
    private static func chooseHardMove(hand: [Card], mustBeat: Combo?, options: [Combo]) -> Combo? {
        if mustBeat == nil {
            // Leading: dump the biggest "dead" combo (cards that don't extend into anything else)
            // first, holding pairs/triples/straights and the 2 in reserve.
            let byUsefulness = options.sorted { comboUsefulness(hand: hand, $0) < comboUsefulness(hand: hand, $1) }
            return byUsefulness.first
        }

        // Following: play the smallest combo that still wins the trick, unless only a bomb
        // or the 2 can beat it — then weigh whether it's worth burning a premium card.
        let nonPremium = options.filter { $0.shape != .fourOfAKind && $0.topRank != .two }
        if let cheapest = nonPremium.min(by: { $0.topRank < $1.topRank }) {
            return cheapest
        }
        // Only bombs/2s can win — hold back roughly a third of the time to keep the "heo" in reserve.
        if hand.count > 3, Bool.random(probability: 0.35) { return nil }
        return options.min { $0.topRank < $1.topRank }
    }

    /// Lower score = less useful to keep (safer to discard early). Cards that are part of a
    /// pair/triple/straight elsewhere in the hand score higher (worth holding onto).
    private static func comboUsefulness(hand: [Card], _ combo: Combo) -> Int {
        var score = combo.topRank.rawValue
        if combo.topRank == .two { score += 50 }
        if combo.shape == .fourOfAKind { score += 100 }
        let rankCounts = Dictionary(grouping: hand, by: { $0.rank }).mapValues { $0.count }
        if combo.shape == .single, let count = rankCounts[combo.topRank], count > 1 {
            score += 10 // this card is part of a pair/triple elsewhere — prefer not to break it up
        }
        return score
    }

    static func legalPlays(hand: [Card], mustBeat: Combo?) -> [Combo] {
        var combos: [Combo] = []
        let byRank = Dictionary(grouping: hand, by: { $0.rank })

        // Singles
        combos.append(contentsOf: hand.map { Combo(cards: [$0], shape: .single, topRank: $0.rank) })

        // Pairs / triples / four-of-a-kind
        for (rank, cards) in byRank {
            if cards.count >= 2 { combos.append(Combo(cards: Array(cards.prefix(2)), shape: .pair, topRank: rank)) }
            if cards.count >= 3 { combos.append(Combo(cards: Array(cards.prefix(3)), shape: .triple, topRank: rank)) }
            if cards.count == 4 { combos.append(Combo(cards: cards, shape: .fourOfAKind, topRank: rank)) }
        }

        // Straights (same suit, consecutive, length 3+, no 2s)
        for suit in Suit.allCases {
            let suited = hand.filter { $0.suit == suit && $0.rank.isStraightEligible }.sorted { $0.rank < $1.rank }
            guard suited.count >= 3 else { continue }
            for start in 0..<suited.count {
                var run: [Card] = [suited[start]]
                for next in (start + 1)..<suited.count {
                    if suited[next].rank.rawValue == run.last!.rank.rawValue + 1 {
                        run.append(suited[next])
                        if run.count >= 3 {
                            combos.append(Combo(cards: run, shape: .straight(length: run.count), topRank: run.last!.rank))
                        }
                    } else {
                        break
                    }
                }
            }
        }

        guard let mustBeat else { return combos }
        return combos.filter { $0.beats(mustBeat) }
    }
}

private extension Bool {
    static func random(probability: Double) -> Bool { Double.random(in: 0...1) < probability }
}
