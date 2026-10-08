# openGym audit → feature list for LLR

## Context
openGym (`external/openGym`, AGPL-3.0, React/Capacitor, self-hosted) was audited in full by three read-only passes: screens/features, exercise data/media/licensing, stats/progression. This list is what is worth rebuilding natively in LLR (SwiftUI/SwiftData, local-first). openGym is AGPL-3.0. Owner decision (2026-10-08): its code may be reused, because the repo belongs to a friend of the owner; keep that author's written okay on file. This does not cover the exercise media, which belongs to third parties (see below). Paths in `[brackets]` are openGym files to read.

## Fatal flaw first: the demo photos/GIFs cannot be imported as-is
- The 1,324 exercises' media (`img`/`gif` per record in `frontend/src/lib/exercises-data.js`) is **not licensed to anyone**. `NOTICE.md`: "treat the media as third-party content licensed to neither openGym nor to you." It originates from ExerciseDB v1 (AscendAPI), which forbids redistributing the media as a content package; the middle dataset (hasaneyldrm) attributes it to "Gym visual", "not transferable".
- openGym's App-Store exception in `NOTICE.md` covers only openGym's own app, not LLR.
- Bundling it in an App Store build is a takedown risk. Hotlinking it at runtime (what openGym's mobile build does via jsDelivr) is the same problem plus a dead-link risk.
- The English text (`n`, `st` steps) is MIT via the dataset, but its chain of title back to ExerciseDB is disputed. Non-English packs are AGPL or LLM-translated: not usable.
- **Recommendation: do not import openGym's media.** Replacement path, in order:
  1. `yuhonas/free-exercise-db` — page badge says **Unlicense** (public domain), ~800+ exercises, 2 JPGs each (`0.jpg`, `1.jpg`), fields id/name/force/level/mechanic/equipment/primaryMuscles/secondaryMuscles/instructions/category/images. I could not read its `LICENSE` file directly (404 on the raw path) and its image provenance is unstated, so **verify the licence file and ask the maintainer about image origin before shipping**.
  2. Commission or generate original illustrations for the ~100 exercises users log most (LLR already has 451; match by `LLR/Logic/ExerciseMatcher.swift`).
  3. Written permission/licence from AscendAPI (ExerciseDB) — the only route to the animated GIFs.
- Strategy that survives any of the above: ship text-only by default, add images as an optional downloadable pack (on-demand, cached in Application Support like `ExerciseMediaStore`), so a licence problem is a server-side removal, not an app update. Animated demos = short looping MP4/HEVC, not GIF (size).

## Already in LLR (no work)
Warm-up/drop/failure set kinds (`LLR/Logic/SetKind.swift`), hold sets, plate calculator + barbell diagram, rest timer + background notification (`RestNotifier.swift`), edit past workouts (`WorkoutEditorView.swift`), muscle recovery body map, weekly volume zone, calendar + week streak, muscle-split radar, PR banner, e1RM (Epley), measurements + progress photos, 16 routines + builder, equipment filter, double progression, Hevy/Strong CSV import, kg/lb, accent colour, Live Activity, widget.

## Feature list — build (ranked by value ÷ effort)

### A. Exercise media & library (the user's ask #1)
1. **Exercise demo images / looping clips** in `ExerciseInfoSheet`, picker rows, workout card; Full / Small / Hidden setting [`components/WorkoutMedia.jsx`]. Licence-gated, see above. New: optional `Exercise.demoImageNames` or a name→asset index file (JSON, no schema change).
2. **Favourites**, sorted first in picker/library [`lib/favourites.js`]. New defaulted `Exercise.isFavourite` (additive).
3. **Muscle explorer**: tap a muscle on the existing body map → exercises for it, honouring equipment [`components/MuscleExplorer.jsx`]. Reuses `body_map.json`, `MuscleTaxonomy.swift`.
4. **Equipment profiles** (Home / Gym) filtering library, picker, routines; flag routine exercises needing unowned gear [`lib/equipment.js`]. Extends `Equipment.swift`.
5. Larger library (1,324 vs 451): only via the licensed dataset above; otherwise grow by importing free-exercise-db metadata.

### B. Stats (the user's ask #2) — all pure-logic structs + XCTest, per `CLAUDE.md`
6. **Activity heatmap**, 12 months, time/volume toggle, quartile shading [`components/Heatmap.jsx`]. (Their title says 12 months but renders 53 weeks.)
7. **Effort stats card**: avg RIR, % hard sets, weekly line, RIR histogram [`views/Stats.jsx` EffortCard]. Needs #12.
8. **"Hard sets only" toggle** on Weekly Volume (RIR ≤ 3) — extends `WeeklyVolume.swift`.
9. **Muscle balance by window** (Week/30d/90d/All) with completed-vs-planned sets per muscle [`lib/muscles.js`]; secondary = 0.4 (LLR uses 0.5 — keep LLR's, cited).
10. **Fatigue model**: stimulus = load×reps×(load/1RM)^1.5, EWMA-normalised, 36 h half-life [`lib/recovery.js`]. Compare with LLR's existing `MuscleRecovery.swift` before replacing; add only if it beats it.
11. **Strength retention / "detrained" list**: 14-day grace then 28-day half-life, floor 50% [`lib/recovery.js`]. New view on the body map.
12. **RIR/RPE per set** (optional column, colour-coded, plain-language line per level) [`lib/effort.js`]. New defaulted `SetEntry.effortRaw`/`effortScale` (additive; fixture test already exists for migration).
13. **Structural Balance**: strength ratios vs anchors, Poliquin / Thibaudeau / ATG templates, Balanced/Borderline/Weak [`lib/structuralBalance*.js`]. Pure logic, high wow, needs bodyweight (LLR has it). Cite the standards in-app.
14. **Exercise progress modes**: top set / e1RM / effort / max reps, last-5-sessions drilldown, assisted machines inverted [`views/Stats.jsx`]. Extends `ExerciseProgressView.swift`.
15. **Top speed / longest hold / week-streak tiles**; **bodyweight 30-day delta tile** and goal line with "N to lose/gain" [`Home.jsx`]. LLR has `WeightTrend.swift`; add goal line if missing.
16. Per-workout **insights**: volume vs same-named previous workout, per-lift e1RM delta [`lib/coach-insights.js` sessionInsights] — deterministic, no AI.
17. e1RM formula choice (Epley/Brzycki/Lombardi) as a setting; 1RM capped >12 reps — copy the cap.

### C. Training features
18. **Supersets** (pair/unpair, uneven rounds) [`lib/supersetFlow.js`]. Largest model change: `WorkoutExercise.supersetGroup: Int?` (additive).
19. **Progression rules** beyond double: linear (step 2.5/5 kg), Greyskull LP, add-time for holds, **deload after N stalls (×0.9)**, "why this target" text, assisted-machine reversal [`lib/progression.js`]. `Progression.swift` exists; this is the biggest logic delta.
20. **Per-exercise "don't count for progression"** + whole-session toggle (injury days).
21. **Standing notes per exercise** ("seat 4, pin 7") shown in the workout card [`useStore exNotes`]. Defaulted `Exercise.standingNote`.
22. **Per-side reps/holds** with switch-sides pause (verify LLR's partial support first) [`Workout.jsx`].
23. **Pyramid sets** with per-set reps/rest and "max" sets [`lib/pyramid.js`].
24. **Cardio logging** (time + speed) — LLR has 5 cardio hits; confirm completeness.
25. **Swap exercise mid-session** (this session / whole routine), move/remove with Undo.
26. **Rest per exercise + wheel up to 15:00**, rest-pause burst timer (15 s).
27. **Bar weight per exercise / "no bar"**, plate inventory per unit [`lib/bar.js`, `lib/plates.js`].
28. **Rotation (A,B,C loop)** beside weekly plan; "next unlogged routine is up next" [`lib/rotation.js`]. Fits the Routines feature.
29. **Planned deloads** and week-start Monday/Sunday setting.
30. **Repeat a past workout** from History, **save workout as routine**, **copy workout as text** [`lib/workout-text.js`]. Cheap wins.
31. **Swipe a set: left delete w/ Undo, right copy.**

### D. Data, settings, polish
32. **FitNotes CSV + Apple Health weight export import** (`lib/import-csv.js`); LLR already has Hevy/Strong. Hevy-ID map is built with their API key and unlicensed: skip, use `ExerciseMatcher`.
33. **Full JSON export/import** incl. media zip; auto-backup to Files.
34. **Share a plan as a file**, **print plan as PDF** (`UIPrintInteractionController`).
35. **Workout-day reminders** (local notifications); optional missed-day nudge with tone (friendly/drill sergeant), quiet after 3 misses [`lib/nudge.js`].
36. **Timer alerts**: chime/beeps, vibrate, flash screen; keep screen awake during workout.
37. **Localization** (17 languages in openGym). Their translation packs are AGPL/LLM-made: do not copy; plan String Catalog + your own translations later.
38. **Gym check-in card** (store membership QR/barcode, full-screen) — small, self-contained.
39. **Body-weight goal + weigh-in before workout** option.

## Rejected (and why)
Passkeys, accounts, server sync, admin dashboard, Docker/K8s, web push, MCP server — violate LLR non-goals or are server-only. **AI Coach** — explicit non-goal (`CLAUDE.md`). Body-measurements — openGym has none; LLR is ahead. Android rest-alert service — platform-specific. openGym's body-diagram paths — LLR already has its own `body_map.json` with licence.

## Needs your decision before building (scope rule: "flag, don't build")
- Which media route (licence free-exercise-db / commission art / ask AscendAPI)? This gates #1 and #5.
- Items outside current `CLAUDE.md` v1/approved lists: essentially all of the above. Approve by tier: **Tier 1** = 2, 3, 6, 8, 12, 7, 30 (small, additive, high payoff); **Tier 2** = 13, 14, 19, 21, 18 (logic-heavy); **Tier 3** = rest.
- Schema impact: additive only (`isFavourite`, `effortRaw`, `supersetGroup`, `standingNote`) → lightweight migration; extend `LLRTests/Fixtures/legacy-pre-fuel.store` approach with a new fixture before any non-additive change.

## Verification (when implementation starts, per tier)
- One item at a time: `xcodegen generate`, `xcodebuild -scheme LLR -destination 'platform=iOS Simulator,name=iPhone 17' test` green (currently 241 tests), new pure logic ships with XCTest, migration test passes against the legacy fixture.
- For media: confirm licence file text and keep attribution in `LLR/Profile/AcknowledgementsView.swift` before any asset is added to the repo.
- For stats: reproduce openGym's documented formulas on a hand-computed fixture, not by reading its code.
