import Foundation

struct Player: Identifiable {
    let id: Int
    var name: String
    var hand: [Card] = []
    let isHuman: Bool
    var finishedRank: Int? = nil     // 1st, 2nd, 3rd, 4th to empty their hand
    var declaredSam: Bool = false    // báo sâm — declared they'll clear the rest uncontested
    var samFailed: Bool = false

    var isFinished: Bool { finishedRank != nil }
}

enum AIDifficulty: String, CaseIterable, Identifiable {
    case easy, normal, hard
    var id: String { rawValue }
    var titleKey: String {
        switch self {
        case .easy: return "difficulty.easy"
        case .normal: return "difficulty.normal"
        case .hard: return "difficulty.hard"
        }
    }
}
