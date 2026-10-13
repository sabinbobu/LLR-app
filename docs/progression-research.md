# Progression research (G9)

Research only: no code or schema is changed by this note. Researched 2026-10-13.

**Limits.** Publisher and PubMed pages were unreachable from the environment this was written in, so every source below is known from search-result abstracts and summaries only. Quotes are copied from those summaries and are UNVERIFIED against the full text. Treat each gap as a proposal to check, not a finding.

## What the app already does

From `LLR/Logic/Progression.swift` and `LLR/Logic/WeeklyVolume.swift`:

| Rule | Behaviour |
|---|---|
| Double | Climb a rep range at one weight; all working sets at the top adds a step and reps restart at the bottom |
| Linear | All working sets at target reps adds a step; a miss repeats the target |
| Greyskull LP | Only the last set (to failure) is judged; hitting it adds a step (two if reps doubled), missing backs off |
| Time | Holds gain 5 s a session |
| Deload | Linear and double back off 10% after 3 consecutive short sessions at the same weight |
| Weekly Volume | Hard sets per muscle per week (secondary counts half) against a 10–20 set zone |
| Effort | `SetEntry.rir` is stored and only used to filter "hard" sets in Weekly Volume |

## Sources

1. **Helms ER, Cronin J, Storey A, Zourdos MC. "Application of the Repetitions in Reserve-based Rating of Perceived Exertion Scale for Resistance Training." Strength & Conditioning Journal 38(4):42–49, 2016.** Abstract-level summary: RPE is a valid way to estimate resistance-training intensity, but is usually rated after a session; a scale based on repetitions remaining at the end of a set "may be a more precise tool". (UNVERIFIED wording; the full practical recommendations were not read.)
2. **Zourdos MC et al. "Novel resistance training-specific rating of perceived exertion scale measuring repetitions in reserve." J Strength Cond Res, 2016.** Introduced the RIR-based scale; reported an inverse relationship between average bar velocity and RPE/RIR in 29 squatters (via summary).
3. **Bell L, Nolan D, Immonen V, et al. Deloading consensus study, Sports Medicine – Open, 2023.** A Delphi consensus (34 coaches in round 1, 21 in round 3), not a systematic review. Summary quote: deloading is "a ubiquitous yet under-researched strategy" in strength and physique training. A survey cited alongside reports typical deloads of about 6–7 days roughly every 5–6 weeks (secondary summary).
4. **Coleman M et al. PeerJ, 2024.** Randomised trial, 39 participants, one week off in the middle of a nine-week programme vs continuous training. Outcomes were not visible in the search results, so no finding is claimed here.
5. **Schoenfeld BJ, Ogborn D, Krieger JW. "Dose-response relationship between weekly resistance training volume and increases in muscle mass: a systematic review and meta-analysis." J Sports Sci 35(11), 2017.** Graded dose-response up to about 10+ weekly sets per muscle; insufficient data well above that; only two included studies used resistance-trained participants (via the author's summary). Already the basis of the 10-set line in `WeeklyVolume.swift`.

## Gaps (proposals only)

Each is "rule X lacks Y; source Z does Y".

1. **Double/linear ignore effort.** The rules judge reps and load only; a set at 0 RIR and one at 4 RIR look identical. Sources 1–2 define RIR as a repetitions-remaining rating per set. *Proposal:* when `rir` is logged, treat a top-of-range set at ≥3 RIR as eligible for a larger step, and a missed set at ≤0 RIR as a genuine miss rather than a hold. *Migration:* none (`rir` already stored). *Open:* the thresholds are a design choice; no source read here gives them.
2. **Deload triggers only on stalls.** The app deloads after 3 short sessions at one weight; the coach consensus (3) describes planned deloads on a calendar rhythm. Source 4's outcome is unknown, so the benefit of a planned deload is unproven here. *Proposal:* an optional, off-by-default "suggest a lighter week every N weeks" prompt; no automatic load change. *Migration:* one new setting key, no model change.
3. **No weekly set progression.** `WeeklyVolume` reports the zone but nothing steps sets up or down across weeks. Source 5 supports volume mattering up to about 10+ sets and cannot say how fast to add them. *Proposal:* keep the report read-only; do not build a set-adding rule without a source that gives a ramp.
4. **Untrained-sample caveat.** Source 5's evidence is mostly untrained participants, while the app's users are not. Any volume target is therefore a starting point.

## Not recommended

Adding an auto-regulation engine on the strength of this note. The sources here were read at abstract level and give no numeric thresholds for the app to adopt.
