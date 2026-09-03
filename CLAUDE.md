**2026-09-04 — re-checked after user asked "is it still giving away free play?"**
Verified live: `asc_app_status.py` shows v1.0.4 is now `READY_FOR_SALE` (approved since
the 2026-08-30 note below was written). Read the current `PurchaseManager.swift` +
`HomeView.swift` on disk and confirmed the trial-then-lock gate matches what's live —
Hard AI is always locked, Easy/Normal lock once the 7-day trial expires, no bare `#if
DEBUG isPro = true` leak, `Sam Loc Pro` IAP is `APPROVED`/purchasable. Git log shows the
trial-lock commit (`6bfa351`) hasn't been reverted or weakened since. **So: no, it is not
giving away free play like the pre-2026-08-18 build did — that specific bug is fixed and
confirmed live.**

Sales Aug 1 – Sep 3: 558 downloads (509 VN), still **0 IAP units**. Split roughly
301 downloads before the trial-lock fix went live (~Aug 19) and 257 after — the
"after" cohort includes installs from Aug 19–26, which are now well past their 7-day
trial window with no purchases either. IAP being `APPROVED` and the code being correct
rules out a repeat of the old silent-failure bug; this looks like a demand-side/pricing
problem (price resistance, or users just uninstalling at the paywall) rather than a
code bug — but there's no purchase-attempt telemetry to confirm nobody is hitting a
silent StoreKit failure on-device. Worth a real-device TestFlight purchase-flow test
before concluding it's purely pricing (see `feedback_simulator_storekit_failures_test_on_real_device`).

**2026-08-30 — v1.0.4 (build 6), language-switch bug fix, SUBMITTED, WAITING_FOR_REVIEW.**
Investigated a "no purchases despite hundreds of downloads" report: the trial-then-lock
paywall itself was verified working correctly (confirmed on-device with a temporarily
shortened trial window), but the language Picker in `HomeView` bound directly to
`$loc.language`, bypassing `LocalizationManager.setLanguage(_:)` — so the string-lookup
`bundle` never updated when the selection changed. Switching to Vietnamese only *appeared*
to work because the test device's system language was already Vietnamese; switching back
to English silently had no effect. Fixed by making `bundle` computed from `language`
instead of separately tracked. Same bug found+fixed portfolio-wide in 16 other apps same
day; see memory `feedback_localization_picker_direct_binding_bug`. Archived/uploaded
(build 6, VALID), attached to a fresh appStoreVersion, `whatsNew` set (en+vi), review
notes appended explaining the fix. **Verified: WAITING_FOR_REVIEW as v1.0.4.**

# Sâm Lốc — Vietnamese Card Game

Native SwiftUI iOS app for Sâm Lốc, the traditional Vietnamese shedding card game. Bundle
`com.quyenngo.samloc`, app id `6792263774`. Built end-to-end 2026-07-18 following the
scout in Claude's memory (`project_vietnamese_card_games_scout` / `project_samloc`) —
read those first for the full history (why this game, why not Tiến Lên/Binh Xập Xám/Xì
Dách, the incumbent teardown, naming research).

**2026-08-24/25 — v1.0.3 (build 5), fixed a real picker-truncation bug, SUBMITTED.**
Found via a portfolio-wide code-level sweep for 3 known bug signatures (see
`reference_compliance_gate_tool` memory). `Views/HomeView.swift`'s difficulty picker
falls back to `!purchases.trialActive` once the trial expires (all 3 tiers can lock
at once), and `maxWidth` was under the safe 340pt threshold — widened to 340. v1.0.2
was already `READY_FOR_SALE` (live), so nothing to cancel — shipped as a normal
new-version update: created appStoreVersion `ffff6f9f-79f4-4e42-ac74-f47ab9bafd35`
(versionString 1.0.3, localizations copied forward), archived/exported/uploaded
(Delivery UUID `4601599b-3a02-4a63-ac74-f66b6ba8c3d6`, processed `VALID`), attached
the build, set `whatsNew` (both locales), created reviewSubmission
`0ff92eae-2614-4449-a4a4-c80082caaf3c` and submitted. **Verified: WAITING_FOR_REVIEW
as v1.0.3.**

**Status: 🟢 LIVE since 2026-07-18 (v1.0.1). v1.0.2 SUBMITTED, WAITING_FOR_REVIEW
(2026-08-18) — 7-day-trial-then-full-paywall, build 4, reviewSubmission
`570cacb3-085b-43f4-9de1-d7529f864a53`, version `cedc4bba-e6b8-45ab-8815-5ed3346c0cfc`.
Archived/exported via `-authenticationKey*` flags (see `feedback_asc_release_and_signing`
memory), uploaded via altool, version+build+whatsNew (en+vi) created via
`~/asc-tools/new_version.py` + one-off API calls, submitted via a fresh reviewSubmission
(no orphaned draft existed to reuse).

Sales Jun 1 – Aug 18: 174 downloads (159 from Vietnam, rest scattered
KR/GB/IN/DE/JP/MX/SG/TW/US), **0 IAP units, $0 proceeds** — despite the IAP being
genuinely `APPROVED`/purchasable this whole window. Root cause: the free tier (Easy +
Normal AI, full rules, no ads) was the complete game for casual players; only Hard AI +
card backs were ever gated. Same pattern and same fix as ChineseChess's v1.0.6 pilot
(see `~/Projects/ChineseChess/CLAUDE.md` and memory
`project_chinesechess_trial_paywall_pilot`).

**2026-08-18 — 7-day trial, then everything locks (no permanent free tier).** Standing
rule now: no app in this portfolio should offer free play at any difficulty/mode forever,
only a capped trial (see memory `feedback_no_permanent_free_tier_trials_only`).
`PurchaseManager.swift` gained `trialActive`/`trialDaysRemaining` backed by a
`firstLaunchDate` UserDefaults key (7-day `trialDuration`, identical mechanism to
ChineseChess). `HomeView.isLocked(_:)` now gates **all three difficulties** (Easy/Normal/
Hard) once the trial expires and the user isn't Pro — previously only Hard was ever
gated. Existing installs with no stored `firstLaunchDate` get the clock started by this
update rather than being locked out immediately. `UpgradeView` subtitle and the Home
footnote button switch to "trial ended" copy once expired. Also fixed a latent bug found
while in this file: `updateEntitlementStatus()`'s `#if DEBUG isPro = true` was a bare
override with no `SL_CAPTURE` exemption — double-gated it (matching the
`SapXam`/`Chan` reference pattern) so the `SL_CAPTURE=upgrade` screenshot mode shows the
real locked/buy-button state instead of "already purchased." Verified via a real
Simulator build: trial-active state (Easy/Normal unlocked, Hard locked, "Free trial — 7
day(s) left"), trial-expired state (all three locked, "Trial ended" footnote), and the
Upgrade screen's trial-ended copy all render correctly. **Not yet archived/submitted —
this is a real product change for existing live users, holding for explicit go-ahead
before shipping** (see the staggered-submission caution in
`feedback_new_app_build_checklist` item 7).

**Bug found and fixed 2026-08-02: the `Sam Loc Pro` IAP was never actually
purchasable.** It was configured in ASC ($2.99, non-consumable) but stuck at
`READY_TO_SUBMIT` — v1.0.0's two review submissions on launch day only
included the app-version item, never an IAP item, so Apple never reviewed/
approved the IAP. `PurchaseManager.swift`'s `guard let product else { ... }`
fallback made this invisible: tapping Buy just showed "Product not available"
instead of crashing, so nobody (including App Review) noticed. Apple also
blocks submitting a first non-consumable IAP standalone — it must ride along
with an app-version submission (`STATE_ERROR.FIRST_NON_CONSUMABLE_MUST_BE_SUBMITTED_ON_VERSION`).
Fix: bumped to v1.0.1 (build 3), attached the IAP to that version's review
submission, submitted together — now `WAITING_FOR_REVIEW`. Once Apple
approves, `Sam Loc Pro` becomes purchasable for the first time since launch.

**Other apps in this portfolio had the identical bug as of 2026-08-02** —
see `~/asc-tools/README.md` gotcha #7 and the audit findings in memory
(`[[feedback_iap_must_ride_with_first_version_submission]]`): Klotski,
Hanafuda Koi-Koi, Fanorona, Janggi, and Mythsmith were all live with their
IAP(s) stuck at `READY_TO_SUBMIT`, never purchasable. Not yet fixed for
those apps as of this note.

## On-device AI round commentary (prototype, 2026-08-24 — NOT recommended to ship as-is)

`Core/AICommentary.swift` + a small hook in `Views/GameView.swift` add an optional
one-line commentary under the round-over overlay, generated live on-device via Apple's
`FoundationModels` framework (iOS 26+, Apple Intelligence-eligible hardware only —
availability-gated, silently absent otherwise so it's purely additive). Built as a
scoped prototype exploring "on-device AI features" per the AI-use-cases brainstorm in
this session; see memory for the broader reasoning (why on-device fits this
low-revenue/trial-based portfolio, localization-maintenance angle, etc.).

**Conclusion after three rounds of real on-device testing (not simulated): don't ship
free-generated commentary text.** Each round fixed one concrete failure mode; testing
then found a *different* one. Not a one-off bug to patch — evidence the "free text +
validate the output" architecture is inherently leaky for this use case:

1. Round 1: 1/3 Vietnamese runs invented a fake "declaration detected and voided"
   penalty narrative never in its facts. Fixed by adding typed `@Generable` boolean
   claims (`claimsBaoSamOutcome`, `claimsPenaltyOrInvalidation`) cross-checked against
   real facts, discard-if-ungrounded, plus a ~22-word cap.
2. Round 2 (Báo Sâm path, previously untested — no capture scenario existed for it;
   added `SL_CAPTURE=baosam`): 3/3 runs ignored the requested language entirely and
   echoed the English facts text almost verbatim, because the facts were themselves
   near-complete sentences the model could lazily copy. Fixed by rewriting facts as
   terse `key: value` data instead of sentences, moving all explanation into the
   static instructions, and adding `looksLikeTargetLanguage` — a cheap script-based
   check (Vietnamese diacritic presence) since keyword-matching translated text
   doesn't generalize across languages.
3. Round 2 retest: 4/5 clean, but 1/5 fabricated a new, different claim — "you're
   guaranteed to win the next round" — which wasn't in any given fact and isn't a
   claim type either typed-claims check was watching for. This is the core problem:
   the model can invent a new *kind* of fabrication faster than specific validators
   can be added for each one already found.

**If AI commentary is revisited later, don't use free generation** — pick from a small
set of pre-written template sentences per outcome (optionally have the model choose
which template fits, not write prose), which closes off fabrication by construction
instead of chasing it reactively. Free-text + post-hoc validation is not safe enough
for user-facing copy on a live app, even on-device with no server cost.

**Also fixed independently, unconditionally good regardless of the above:** a static
string grammar bug in `en.lproj/Localizable.strings` — `"log.samSuccess"` read `"%@'s
Sâm declaration succeeded!"`, which produced "You's Sâm declaration succeeded!" when
`%@` = "You". This is the exact known trap already documented below (subject-verb
agreement breaking when `%@` = "You") that the earlier fix pass evidently missed for
this specific string. Now reads `"%@ successfully declared Báo Sâm!"`, which is
grammatically valid for both "You" and a third-person AI name.

**Status: code committed for documentation/learning value, feature not wired to ship.**
Not deleted — the typed-claims validator pattern and the Báo Sâm capture scenario are
reusable if this is revisited with a template-based design instead of free generation.

## What this is

- Standard 52-card deck, 4 players (you + 3 AI), 10 cards dealt each.
- Combo-beating shedding game: singles/pairs/triples/same-suit straights, tứ quý (four of
  a kind) bombs beat everything.
- "Tới trắng" instant-win detector on the dealt hand: Dragon Straight > Four 2s >
  Same-Color > Three Triples > Five Pairs (priority-ordered).
- "No winning on a lone 2" rule — a single 2 ("heo") can't be your finishing card.
- "Báo Sâm" mid-game declare — double points on success, double penalty on failure.
- 3-tier AI (Easy/Normal/Hard) — Hard uses card-usefulness heuristics, not just legal-move
  selection.
- StoreKit 2 non-consumable IAP `com.quyenngo.samloc.pro` ($2.99) — unlocks Hard AI +
  alternate card backs. Free tier: Easy + Normal AI, full rules, no ads ever, no gambling
  mechanics anywhere (deliberate differentiator from every other Sâm Lốc app on the
  store, which are all multi-game gambling-style portals).
- **True bilingual in-app UI** — not just store metadata. `Core/Localization.swift` is a
  manual bundle-swap `LocalizationManager` that loads `en.lproj`/`vi.lproj`
  `Localizable.strings` at runtime, with a live segmented-control language switch on the
  Home screen (no relaunch needed). Both locales hand-written, not machine-translated.

## Structure

- `SamLoc/Core/` — `Card.swift`, `Combo.swift`, `InstantWin.swift`, `Player.swift`,
  `AIPlayer.swift`, `GameModel.swift` (+ `GameModel+Capture.swift` for the screenshot
  hook), `PurchaseManager.swift`, `Localization.swift`.
- `SamLoc/Views/` — `HomeView`, `GameView`, `CardView`, `RulesView`, `UpgradeView`.
- `SamLoc/{en,vi}.lproj/Localizable.strings` — the bilingual UI strings.
- `capture_shots.py` — drives the simulator via `SL_CAPTURE`/`SL_LANG` DEBUG launch args
  to produce real in-app screenshots (not mockups, per App Review 2.3.3) into
  `screenshots/final/{en,vi}/`.
- `make_icon.py` — generates the PIL-based app icon (tilted "2♥" — the "heo," strongest
  card in the game — on a felt-green gradient).
- `project.yml` — XcodeGen. Regenerate the `.xcodeproj` with `xcodegen generate` after
  adding/removing files.

## Reasoning mode

Before changing game logic, check it against the actual Sâm Lốc ruleset (see the
build-gate notes in memory, or re-verify against Vietnamese-language sources — don't
assume Tiến Lên's rules apply, several mechanics genuinely differ: the 10-card deal
instead of 13, the tới trắng instant-win set, the lone-2 restriction, and Báo Sâm).

**Known trap, already fixed once — watch for regressions:** any English UI string using
`%@` for a player name must stay grammatically valid when `%@` = "You" (second person).
Third-person-only phrasing ("%@ wins", "%@ leads") silently reads as "You wins" / "You
leads" and shipped once before being caught by visually inspecting screenshots, not by a
successful build. Vietnamese has no verb conjugation so it's immune to this class of bug
— only audit the `en.lproj` file for it.

**Always visually inspect generated screenshots before uploading them anywhere public**
— two real bugs (a language-switch skip on the home-screen capture, a mislabeled/missing
4th AI seat, plus the grammar bug above) were caught this way and would NOT have been
caught by a green `xcodebuild` alone.

## Deploy / resubmit pattern

Sideload to Q's device (`F8EF55D6-E237-574F-8AB8-EF8EB0693D45`):
```
xcodebuild -project SamLoc.xcodeproj -scheme SamLoc -destination 'generic/platform=iOS' -configuration Debug build
xcrun devicectl device install app --device F8EF55D6-E237-574F-8AB8-EF8EB0693D45 <path-to-.app>
```

App Store archive/upload (already has a distribution profile now — the
`-authenticationKey*` flags were only needed for the very first export):
```
xcodebuild -project SamLoc.xcodeproj -scheme SamLoc -configuration Release -archivePath build/SamLoc.xcarchive -destination 'generic/platform=iOS' -allowProvisioningUpdates archive
xcodebuild -exportArchive -archivePath build/SamLoc.xcarchive -exportPath build/export -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates
xcrun altool --upload-app --type ios -f build/export/SamLoc.ipa --apiKey G85WXB4AF5 --apiIssuer 2e969722-fc4d-444c-af74-7e0233efd016
```

ASC metadata/IAP/pricing/review-info/screenshots are all scripted and idempotent —
re-run any of these after changing copy or adding a new version:
- `~/asc-tools/asc_push_samloc.py`
- `~/asc-tools/asc_push_samloc_review.py`
- `~/asc-tools/asc_push_samloc_screenshots.py`
- `~/asc-tools/asc_upload_samloc_iap_screenshot.py`

Bundle-ID registration script (already run, one-time): `~/asc-tools/asc_register_samloc.py`.
