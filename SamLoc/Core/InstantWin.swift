import Foundation

enum InstantWinKind: String {
    case dragonStraight   // sảnh rồng — all 10 cards one consecutive same-suit run
    case fourTwos         // four 2s in the dealt hand
    case sameColor        // all 10 cards the same color
    case threeTriples     // three separate triples among the 10 cards
    case fivePairs        // five pairs among the 10 cards

    var titleKey: String {
        switch self {
        case .dragonStraight: return "win.dragonStraight"
        case .fourTwos: return "win.fourTwos"
        case .sameColor: return "win.sameColor"
        case .threeTriples: return "win.threeTriples"
        case .fivePairs: return "win.fivePairs"
        }
    }

    /// Payout multiplier applied to the base stake for an instant "tới trắng" win.
    var payoutMultiplier: Int {
        switch self {
        case .dragonStraight: return 20
        case .fourTwos: return 16
        case .sameColor: return 10
        case .threeTriples: return 8
        case .fivePairs: return 6
        }
    }
}

enum InstantWinDetector {
    /// Checks a freshly-dealt 10-card hand for a "tới trắng" instant win, in priority order:
    /// Dragon Straight > Four 2s > Same-Color > Three Triples > Five Pairs.
    static func detect(hand: [Card]) -> InstantWinKind? {
        guard hand.count == 10 else { return nil }
        if isDragonStraight(hand) { return .dragonStraight }
        if hand.filter({ $0.rank == .two }).count == 4 { return .fourTwos }
        if isSameColor(hand) { return .sameColor }
        if countOfKind(hand, n: 3) >= 3 { return .threeTriples }
        if countOfKind(hand, n: 2) >= 5 { return .fivePairs }
        return nil
    }

    private static func isDragonStraight(_ hand: [Card]) -> Bool {
        guard Set(hand.map { $0.suit }).count == 1 else { return false }
        let ranks = hand.map { $0.rank.rawValue }.sorted()
        guard ranks.allSatisfy({ $0 != Rank.two.rawValue }) else { return false }
        return zip(ranks, ranks.dropFirst()).allSatisfy { $1 == $0 + 1 }
    }

    private static func isSameColor(_ hand: [Card]) -> Bool {
        let reds = hand.filter { $0.suit.isRed }.count
        return reds == 0 || reds == hand.count
    }

    /// Greedy count of disjoint groups of exactly `n` matching ranks (used for triples/pairs).
    private static func countOfKind(_ hand: [Card], n: Int) -> Int {
        var counts: [Rank: Int] = [:]
        for c in hand { counts[c.rank, default: 0] += 1 }
        var groups = 0
        var remaining = counts
        for (rank, count) in remaining {
            let usable = count / n
            groups += usable
            remaining[rank] = count - usable * n
        }
        return groups
    }
}
