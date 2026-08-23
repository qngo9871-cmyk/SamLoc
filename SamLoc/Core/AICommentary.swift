import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct RoundCommentary {
    @Guide(description: "Exactly one short original sentence (max 18 words), in the requested language only, describing how the round ended. Paraphrase in your own words — never copy the raw data fields verbatim.")
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
///
/// The input facts are deliberately terse key: value data, not ready-made sentences —
/// an earlier version wrote the facts as near-complete sentences (e.g. "Won via Báo
/// Sâm declaration (called it early, doubled stakes): true"), and on-device testing
/// showed the model would sometimes just copy that sentence back almost verbatim *in
/// English*, ignoring the requested output language entirely (reproduced 3/3 on the
/// Báo Sâm win path). `looksLikeTargetLanguage` below is a defense-in-depth check for
/// exactly that failure mode, since the typed claims above don't catch it.
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
                    shedding card game. You'll be given terse data, not a sentence — write \
                    your own original one-sentence reaction to it (max 18 words), entirely \
                    in \(languageName), never copying the data's wording verbatim. Comment \
                    ONLY on the round winner and how they won, using only the facts given — \
                    never mention a penalty, score deduction, or the win being disputed, \
                    voided, detected, or invalidated, since none of that happened here. Báo \
                    Sâm is a mid-round declaration that you'll finish uncontested, doubling \
                    the stakes on success or failure. When the winner is the human player, \
                    address them directly as "you" in the second person ("You won...", not \
                    "The human player won...").
                    """)
                let facts = """
                    winner: \(winnerIsHuman ? "you" : winnerName)
                    won_via_bao_sam: \(viaBaoSam)
                    won_via_instant_win: \(instantWinTitle ?? "false")
                    ai_difficulty: \(difficulty.rawValue)
                    """
                do {
                    let response = try await session.respond(to: facts, generating: RoundCommentary.self)
                    let claims = response.content
                    guard !claims.claimsPenaltyOrInvalidation else { self.text = nil; return }
                    guard claims.claimsBaoSamOutcome == viaBaoSam else { self.text = nil; return }
                    let wordCount = claims.text.split(whereSeparator: { $0 == " " || $0 == "\u{a0}" }).count
                    guard wordCount <= 22 else { self.text = nil; return }
                    guard Self.looksLikeTargetLanguage(claims.text, language: language) else { self.text = nil; return }
                    self.text = claims.text
                } catch {
                    self.text = nil
                }
            }
        }
        #endif
    }

    /// Cheap script-based sanity check, not a real language detector: Vietnamese text
    /// in this app is always written with diacritics (đ, ă, â, ê, ô, ơ, ư and their
    /// accented forms), so a "Vietnamese" response with none of those characters is
    /// almost certainly plain English that ignored the language instruction.
    private static func looksLikeTargetLanguage(_ text: String, language: AppLanguage) -> Bool {
        guard language == .vi else { return true }
        let vietnameseMarkers = Set("đĐăĂâÂêÊôÔơƠưƯ")
        if text.unicodeScalars.contains(where: { $0.value > 0x300 }) { return true } // any combining diacritic
        return text.contains(where: { vietnameseMarkers.contains($0) })
    }
}
