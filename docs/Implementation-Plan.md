# LLR Implementation Plan

What was planned, what shipped, what is still open, and what is next. Nothing implemented is removed from this document: shipped items keep their decisions and code pointers, in condensed form. Code references are `path` only; line numbers drift.

## Status at a glance

| # | Item | Status | PR |
|---|------|--------|----|
| G1 | Reorder exercises mid-workout (Move Up / Down) | Shipped | #32 |
| G2 | Replace an exercise from the library | Shipped; picker opens filtered to the muscle | #32, #48 |
| G3 | Pre-fill last session's weights | Shipped | earlier |
| G4 | Edit button for routines | Shipped | #34 |
| G5 | Minimised workout bar on every tab | Shipped | #35, #44 |
| G6 | Warm-up measured by time | Shipped | #39 |
| G7 | Colour-coded sessions: push / pull / legs / yoga | Shipped (calendar colours and header chip included) | #40, #44 |
| G8 | Stretch cool-down after push / pull / legs | Shipped | #41 |
| G9 | Research: weekly exercise loading | Delivered (`docs/progression-research.md`) | #42 |
| G10 | Repeat or delete a recorded workout from the lists | Shipped | #36 |
| F1 | Fuel: accuracy harness | Shipped; baselines not yet recorded | #37, #47 |
| F2 | Fuel: ingredients from photo, user corrects, then analysis | Shipped; acceptance 6 not yet measured | #38 |
| R1 | Run tracking: stopwatch, time-only stats | Shipped; the stopwatch is replaced by R2 | #49 |
| S1 | Rest-timer end sound | Shipped | #50 |
| R2 | Add Run: distance and time, body and muscle exhaustion | **In review** (spec below) | #52, #53 |
| K1 | Kineto (back care): fix freezes, make the catalog reachable | **Queued** for a future session (spec below) | — |

**Verification.** The full XCTest suite runs on a macOS runner (`.github/workflows/tests.yml`) on every PR and push to `main`; it was green at the last merge. Logic is covered by tests; screens have not been checked on a device.

## Open items (need something outside the repo)

- **F1 baselines / F2 acceptance 6.** Add the repository secret `OPENROUTER_KEY`, run Actions → *Fuel accuracy*, and record the `MEAN` lines in `docs/fuel-accuracy.md`. F2 passes if its mean kcal error on the vague-portion fixtures is below the F1 baseline; if not, say so.
- **G5 force-quit persistence.** Tick sets, force-quit, relaunch, reopen the bar. `toggle(_:)` saves explicitly, so it should hold; unverified on a device.
- **On-screen checks.** Mini bar, long-press menus, correction screen, category chips, run screens, and the rest sound have not been looked at (or listened to) on a device.
- **G8 / G9 sources.** Quotes come from search summaries; the publisher pages were unreachable. Verify before citing anywhere user-facing.
- **Verify the MET table** used for R2 (see spec) against the 2011 Compendium.

## Shipped — what exists and where

### G1. Reorder exercises
`ActiveWorkoutModel+Reorder.swift` (`canMove`, `move`), menu in `ExerciseLogCard.swift`. Move Up / Move Down swap `order` with the neighbour; the Lock Screen resyncs. Gap: one step per tap. Optional follow-up: drag handles in a reorder mode (as `InstructionStepsEditor` does for steps).

### G2. Replace exercise
`ActiveWorkoutModel+Reorder.swift` (`swap`); button in `ExerciseLogCard.swift`, hidden for Kineto picks. Ticked sets stay on the old exercise; unticked sets move to the new one, pre-filled from its history (`ExerciseSwapMoveTests`). Follow-up shipped: the picker opens filtered to the replaced exercise's muscle with a **Show all** button (`SwapFilter`, `ExercisePickerView(initialMuscle:)`); Full Body, Other and Cardio open unfiltered.

### G3. Remember last weights
`ActiveWorkoutModel.swift` mirrors last session's set count; `Exercise.progressionPrefill` feeds `Progression.prefill`. History is per exercise and per section, not per workout name, so bench on a "Push A" day pre-fills "Push B". **Decision:** keep per-exercise history; per-routine history would fragment progression.

### G4. Edit button for routines
Ellipsis menu with **Edit** on each "My Routines" row (`WorkoutTabView`), reusing the existing `RoutineBuilderView` sheet. Edit stays enabled mid-workout; editing never touches finished workouts. Test: `RoutineFactoryTests`.

### G5. Minimised workout bar
`MiniWorkoutBar` above the tab bar on every tab while a workout is open and minimised; shows title, elapsed time, rest countdown. Presentation of the active workout moved to `MainTabView` through `ActiveWorkoutPresenter`, so any tab (and G10) can open it. `toggle(_:)` saves explicitly so a ticked set survives a force-quit.

### G6. Warm-up measured by time
**Interpretation:** a warm-up *exercise* logged by duration, not timed warm-up sets of a lift. `TimedWarmup`: Cardio-group exercises, Stretching, "Dynamic Mobility Warm-up" and anything named "… Stretch" default to a timed set (1 × 300 s, or the last duration used). First in a workout → set kind `.warmup`, so volume, PRs and Weekly Volume skip it; ticking a timed warm-up starts no rest. Weight × reps cardio history is respected (no format flip). Two original library entries added.

### G7. Session categories
`SessionCategory` (none / push / pull / legs / yoga) with a colour chip and picker. `categoryRaw` on `Workout` and `Routine` (additive, default empty). Set in the routine builder, the active-workout header, and the workout detail menu; inherited on start-from-routine, Repeat and Save-as-Routine; library days get one only when the day name has exactly one of push / pull / leg(s) / yoga. Shown on routine rows, history cards, and calendar days. **Label only:** never affects history scoping, prefill, PRs, Weekly Volume or CSV. Approved in `CLAUDE.md`.

### G8. Stretch cool-down
`StretchRoutines`: 4–5 timed 30 s holds (one set per side) for push, pull and legs; 13 original-text library entries. A gym workout categorised push / pull / legs offers **Add <Category> Cooldown** on the summary sheet, which starts a *separate* workout (appending would rewrite a finished workout's duration). Sets are `.warmup` kind: no volume, PR, Weekly Volume or rest. A cool-down never offers another cool-down. Research note: `docs/stretch-routine-research.md` (sources unverified). **Decision:** kept out of `routine_library.json`, whose schema has no durations.

### G9. Progression research
`docs/progression-research.md`: what the four rules, the stall deload and Weekly Volume do today; five sources; four gaps as proposals only (RIR-aware progression, planned deloads, weekly set ramps, untrained-sample caveat). Sources known from abstracts only.

### G10. Repeat or delete a recorded workout
Long-press a workout card in Home or Profile: **Repeat Workout** (gym only; disabled with a reason while another workout is open) and **Delete Workout** (confirmation; mentions the pain log when one exists). Shared `WorkoutActions`; delete also saves and re-syncs the widget. **Interpretation:** "restart" means start a new workout from a past one, not reopen a finished one. **Decision:** no undo for workout delete (the snapshot would need extending and a toast host in two list screens, for an action that already confirms).

### F1. Fuel accuracy harness
`LLRTests/FoodAccuracyTests.swift` + `LLRTests/Fixtures/fuel-meals.json`: 20 meals, ground truth = grams × USDA per-100 g values (entered from memory; spot-check). Offline tests always run; the live per-meal and `MEAN` report runs when `OPENROUTER_KEY` is set, in two passes (stated grams, vague portions). Manual workflow: `.github/workflows/fuel-accuracy.yml`. Results: `docs/fuel-accuracy.md`.

### F2. Ingredient correction before analysis
Photo → vision call returns `{name, grams}` only → `IngredientCorrectionView` (rename, edit grams, delete, add; Analyse disabled unless every row has a name and grams > 0) → text-only macro request with quantities stated as exact (no image in the body) → existing `FoodReviewView`. Text-only input keeps its direct path. Nothing saves before the review screen. **Decision:** the AI still does the macro arithmetic. Rejected alternative: a bundled USDA table with the model only identifying foods and grams: more accurate and free to run, but needs a curated table and name matching; revisit only if F1 shows arithmetic is a large error source. `CLAUDE.md` network line updated (two requests per photo estimate).

### R1. Run tracking
A run is a `Workout` with `sectionRaw == "run"` and no exercises, so it flows through Home and Profile history, the calendar, the streak and the widget with no new entity. `RunStats` (count, total, average, usual start hour). `removeEmptyHistory` keeps finished runs. History queries use `sectionRaw != "kineto"` (an OR of two sections timed out the type checker). Not in the Strong CSV export. The stopwatch flow is replaced by R2.

### S1. Rest-timer end sound
Original two-note tick (`LLR/Resources/rest-tick.wav`, 0.75 s, mono 16-bit PCM). The scheduled "Rest over" notification plays it in the background; `RestSound` plays it in-app when the app is active (iOS suppresses the notification in the foreground), with the `.ambient` audio category so it mixes with music and follows the silent switch. Not auditioned.

## Next: R2. Add Run — distance, time, exhaustion

**Request.** Replace **Start Run** with **Add Run**. The user adds a run as a sport activity with kilometres and time. The app calculates its effect on overall body exhaustion and muscle exhaustion.

**Migration impact (stated before building).** One optional field: `distanceKm: Double?` on `Workout`. Additive and optional, so lightweight migration applies; `PersistenceRecoveryTests` should pass unchanged and no new fixture is needed. Existing runs (time only) keep `distanceKm == nil`.

**Flow**
1. Workout tab row **Add Run** opens a sheet: distance (km), time (h : mm : ss), and *Finished* (date and time, default now). `startedAt = finished − time`.
2. A live preview shows pace (min/km), speed (km/h), overall exhaustion, and the muscles affected before saving.
3. **Save** stores a finished run (`endedAt` set). Invalid input (distance ≤ 0, time ≤ 0, speed outside 3–25 km/h) disables Save with a message.
4. The stopwatch (`RunActiveView`, `startRun`, `finishRun`) is removed. Unfinished runs left over from R1 are discarded at launch.
5. Runs show km, time and pace on history cards and detail, plus the exhaustion breakdown. The Workout-tab run summary adds total distance.

**Exhaustion model (a heuristic, like the existing muscle recovery, not physiology)**
- Speed → MET by interpolation over the 2011 Compendium running values (Ainsworth et al., *Med Sci Sports Exerc* 43(8):1575–81): 4 mph 6.0, 5 mph 8.3, 5.2 mph 9.0, 6 mph 9.8, 6.7 mph 10.5, 7 mph 11.0, 7.5 mph 11.5, 8 mph 11.8, 8.6 mph 12.3, 9 mph 12.8, 10 mph 14.5, 11 mph 16.0. **UNVERIFIED:** from memory; check against the table.
- `load = MET × hours` (MET-hours).
- **Overall body exhaustion** = `min(100, 100 × load / 24)`, then decays linearly to zero over 72 h. Rough scale: 5 km ≈ 20%, 10 km ≈ 40%, half marathon ≈ 85%.
- **Muscle exhaustion** reuses `MuscleRecovery`: fatigue points = `0.8 × weight × load`, with weights quadriceps 1.0, calves 1.0, hamstrings 0.8, glutes 0.8, abdominals 0.3, lower back 0.3, and the existing windows and "10 points reads 0%" scale. A run therefore appears on the Muscle Recovery screen with every other session. Runs do not count as hard sets in Weekly Volume.
- The weights, divisor and 0.8 factor are design choices, not findings; they are constants in one file so they are easy to retune.

**Files.** `Workout.distanceKm`; new `RunLoad` (pure logic); `MuscleRecovery.Entry` gains `load` and `isCardio`; `WeeklyVolume` skips cardio entries; `Workout.recoveryEntries` includes runs; new `AddRunSheet`; run card, detail, summary and `MuscleRecoveryView` updated; stopwatch removed.

**Acceptance**
1. Add Run saves a finished run with distance and time; it appears in Home, Profile, the calendar and the streak.
2. Pace and speed are right (10 km in 50:00 → 5:00 /km, 12.0 km/h); invalid inputs cannot be saved.
3. A longer or faster run never shows less exhaustion than a shorter or slower one at the same speed.
4. The run's muscle effect shows on Muscle Recovery for legs first, core and lower back less, upper body untouched; it clears after the muscle windows.
5. Runs never change Weekly Volume sets, PRs, lift history or prefill.
6. Old time-only runs still display; `PersistenceRecoveryTests` passes.

**Tests.** `RunLoadTests` (MET interpolation and clamps, load, exhaustion monotonicity and cap, validation, muscle weights, decay), recovery-entry integration, Weekly Volume exclusion, add-run factory and unfinished-run cleanup.

## Queued for a future session

### K1. Kineto (back care) stability and catalog access

**Reported by the owner.** The Kineto hub (Workout tab → Kineto) randomly freezes when its buttons are pressed, and the catalog is not accessible. Investigate the whole module (`LLR/Kineto/`, `LLR/Models/KinetoCatalog.swift`, about 1,600 lines across 19 files) and fix every issue found, not only these two.

**Screen in question.** Hub with the "Not medical advice" banner and Red flags link, **New Routine**, **Browse Catalog**, **Pain history**, and "My Kineto Routines" (with Start) once any exist.

**Migration impact.** None expected. If a fix needs a model change, state it first (`CLAUDE.md` working rule).

**Suspects.** From reading `KinetoView.swift` only, so unverified until reproduced:
1. **Gate re-presenting.** `.onAppear { if !isCleared { showingGate = true } }` runs every time the hub reappears (back from the catalog, Pain history, or any sheet). If clearing the gate does not persist `kinetoClearedVersion` before it dismisses, a full-screen cover can re-present over the screen and swallow taps, which reads as a freeze.
2. **Three presentations on one view.** One `fullScreenCover` and two `.sheet(item:)` modifiers sit on the same `ScrollView`. SwiftUI drops a presentation requested while another is animating in or out, leaving the screen unresponsive or a button doing nothing.
3. **Heavy work on the main thread.** The catalog and its detail screens may do synchronous work (building entries, fetching all exercises, loading media) when opened; a hang there looks like a frozen Browse Catalog. Another session recently moved media I/O off the main actor (#51), so this class of problem already exists in the app.
4. **Not reachable from the gate flow.** Whether the catalog is blocked by the gate, by a navigation problem, or by an empty or failing data load is unknown and must be established first.

**Method**
1. Reproduce each control on a simulator build: Red flags, New Routine, Browse Catalog, Pain history, Start on a saved routine, and pick mode from the routine builder. Record which one fails and how (no response, blank screen, crash).
2. Use Instruments (Hangs, Time Profiler) and the Main Thread Checker to find work over 250 ms on the main thread.
3. Trace every presentation (cover, sheets, navigation) in the module and make sure only one can be pending at a time.
4. Read every file in `LLR/Kineto/` for the same classes of bug (state mutated during view updates, unbounded work in `body`, force unwraps, queries without limits).
5. Fix each cause at its root; add a regression test for each piece of logic (gate state, catalog loading) that can be tested without a UI.

**Acceptance**
1. Every control on the hub responds on the first tap, every time, including after returning from another screen and after dismissing a sheet.
2. Browse Catalog opens, lists every catalog exercise, searches, and opens an exercise detail. Pick mode works from the Kineto routine builder.
3. The gate shows once per catalog version and never re-presents once cleared; its cleared state survives relaunch.
4. No main-thread hang above 250 ms while using the hub, catalog, check-in, check-out, or pain history.
5. Only one modal presentation can be requested at a time from the hub; a second request is queued or ignored, never lost silently.
6. The unit tests pass, and a device checklist covers each control above.

**Out of scope.** Changing clinical content, red-flag text, or the physiotherapist gate rules (they still need real clinical sign-off).

**Process.** This is a bug-fix item: reproduce first, one root cause per commit, and report anything found that was not in this list.

## Possible later

- G1 drag-to-reorder.
- Ingredient corrections saved as personal food presets (F2 follow-up).
- RIR-aware progression and a planned-deload prompt (G9 proposals; wait for verified sources).
- USDA lookup table for Fuel, only if F1 shows arithmetic error dominates.

## Rollback

Every item is a revert of its own PR. The only schema changes are additive: `categoryRaw` on `Workout` and `Routine` (G7) and `distanceKm` on `Workout` (R2); reverting the code leaves unused columns with defaults and no data loss. Nothing here changes `Persistence.open`'s set-aside-on-failure behaviour.
