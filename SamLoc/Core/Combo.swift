import Foundation

enum ComboShape: Equatable {
    case single
    case pair
    case triple
    case straight(length: Int)
    case fourOfAKind // tứ quý — beats everything, including a lone 2

    var sortKey: Int {
        switch self {
        case .single: return 0
        case .pair: return 1
        case .triple: return 2
        case .straight(let n): return 100 + n
        case .fourOfAKind: return 999
        }
    }
}

struct Combo {
    let cards: [Card]
    let shape: ComboShape
    /// Highest-rank card in the combo, used to compare same-shape combos.
    let topRank: Rank

    /// A lone single "2" being played as the very last card of a hand is disallowed
    /// (the Sâm Lốc "no winning on a lone 2" rule) — this flags that specific case.
    var isLoneTwo: Bool { shape == .single && cards.first?.rank == .two }

    func beats(_ other: Combo) -> Bool {
        if shape == .fourOfAKind && other.shape != .fourOfAKind { return true }
        if other.shape == .fourOfAKind { return false }
        guard sameShapeFamily(other) else { return false }
        return topRank > other.topRank
    }

    private func sameShapeFamily(_ other: Combo) -> Bool {
        switch (shape, other.shape) {
        case (.single, .single), (.pair, .pair), (.triple, .triple): return true
        case (.straight(let a), .straight(let b)): return a == b
        default: return false
        }
    }

    /// Attempts to build the strongest valid combo shape from an exact set of selected cards.
    /// Returns nil if the selection isn't a legal shape.
    static func make(from cards: [Card]) -> Combo? {
        guard !cards.isEmpty else { return nil }
        let sorted = cards.sorted { $0.rank < $1.rank }
        let ranks = Set(sorted.map { $0.rank })

        if cards.count == 1 {
            return Combo(cards: sorted, shape: .single, topRank: sorted[0].rank)
        }
        if ranks.count == 1 {
            switch cards.count {
            case 2: return Combo(cards: sorted, shape: .pair, topRank: sorted[0].rank)
            case 3: return Combo(cards: sorted, shape: .triple, topRank: sorted[0].rank)
            case 4: return Combo(cards: sorted, shape: .fourOfAKind, topRank: sorted[0].rank)
            default: return nil
            }
        }
        // Straight: same suit, consecutive ranks, length >= 3, no 2s.
        if cards.count >= 3, Set(sorted.map { $0.suit }).count == 1,
           sorted.allSatisfy({ $0.rank.isStraightEligible }) {
            let rankValues = sorted.map { $0.rank.rawValue }
            let isConsecutive = zip(rankValues, rankValues.dropFirst()).allSatisfy { $1 == $0 + 1 }
            if isConsecutive {
                return Combo(cards: sorted, shape: .straight(length: cards.count), topRank: sorted.last!.rank)
            }
        }
        return nil
    }
}
