import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct RoundCommentary {
    @Guide(description: "Exactly one short sentence (max 18 words), in the requested language only, describing how the round ended using only the given facts. No emoji, no quotation marks.")
    var text: String

    @Guide(description: "True only if the sentence states whether the winner's Báo Sâm declaration succeeded or failed.")
    var claimsBaoSamOutcome: Bool

    @Guide(description: "True if the sentence mentions any scoring penalty, point deduction, or the win being detected, disputed, voided, or invalidated in any way.")
    var claimsPenaltyOrInvalidation: Bool
}
#endif

/// On-device commentary for a just-finished round, generated live via Apple's
/// Foundation Models framework so it needs no server, no API cost, and no
/// hand-translated string for every possible outcome. Purely additive: when the
/// model isn't available (pre-iOS 26, non-Apple-Intelligence hardware, the device
/// hasn't finished downloading the model, or the response fails validation below),
/// `text` just stays nil and the existing static round-log line is all that shows.
///
/// This commentary is scoped to ONE thing — the round winner and how they won — and
/// is never given any penalty/scoring facts, so `claimsPenaltyOrInvalidation` should
/// always come back false; a true here means the model free-associated an event that
/// was never in its facts (caught this happening for real in on-device testing: it
/// invented a "declaration detected and voided" penalty out of nothing), so it's
/// treated as ungrounded and discarded rather than shown. `claimsBaoSamOutcome` is
/// cross-checked against the actual `viaBaoSam` fact for the same reason.
@MainActor
final class AICommentaryProvider: ObservableObject {
    @Published private(set) var text: String?

    static var isSupported: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.availability == .available
        }
        #endif
        return false
    }

    func generate(
        winnerName: String,
        winnerIsHuman: Bool,
        viaBaoSam: Bool,
        instantWinTitle: String?,
        difficulty: AIDifficulty,
        language: AppLanguage
    ) {
        text = nil
        guard Self.isSupported else { return }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            Task {
                let languageName = language == .vi ? "Vietnamese" : "English"
                let session = LanguageModelSession(instructions: """
                    You are a friendly, concise commentator for Sâm Lốc, a Vietnamese \
                    shedding card game. Reply in \(languageName) only, in exactly one \
                    short sentence (max 18 words). Comment ONLY on the round winner and \
                    how they won, using only the facts given below — never mention a \
                    penalty, score deduction, or the win being disputed/voided/detected/ \
                    invalidated, since none of that happened here. When the winner is the \
                    human player, address them directly as "you" in the second person \
                    ("You won...", not "The human player won...").
                    """)
                let facts = """
                    Winner: \(winnerIsHuman ? "the human player — refer to them as \"you\"" : "an AI opponent named \(winnerName)").
                    Won via Báo Sâm declaration (called it early, doubled stakes): \(viaBaoSam).
                    Won via an instant win at the deal (\(instantWinTitle ?? "none")).
                    AI difficulty this match: \(difficulty.rawValue).
                    """
                do {
                    let response = try await session.respond(to: facts, generating: RoundCommentary.self)
                    let claims = response.content
                    guard !claims.claimsPenaltyOrInvalidation else { self.text = nil; return }
                    guard claims.claimsBaoSamOutcome == viaBaoSam else { self.text = nil; return }
                    let wordCount = claims.text.split(whereSeparator: { $0 == " " || $0 == "\u{a0}" }).count
                    guard wordCount <= 22 else { self.text = nil; return }
                    self.text = claims.text
                } catch {
                    self.text = nil
                }
            }
        }
        #endif
    }
}
