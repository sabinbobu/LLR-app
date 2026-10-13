# LLR Implementation Plan

Specs for the open items from the owner's notes (originally two raw bullet lists, Gym and Fuel). G10 was added later from a direct request. Each item is verified against the code as of branch `feat/longer-rest-and-rest-pause` (HEAD `e77ae1f`). Code claims cite `path:line`.

## Status at a glance

| # | Item | Status | Size | Data model |
|---|------|--------|------|------------|
| G1 | Reorder exercises mid-workout (listed twice in the notes) | **Shipped** (#32) | — | none |
| G2 | Replace an exercise from the library | **Shipped** (#32) | — | none |
| G3 | Pre-fill last session's weights | **Shipped**, one question open (see G3) | — | none |
| G4 | Edit button for routines | **Shipped** (#34) | S | none |
| G5 | Minimised workout stays on screen like a video card | **Shipped** (#35), device checks pending | M | none |
| G6 | Warm-up measured by time | **Shipped** (#39) | M | none |
| G7 | Colour-coded sessions: push / pull / legs / yoga | **Shipped** (#40), approved in CLAUDE.md; calendar colouring deferred | M | **additive** |
| G8 | Stretching session after push / pull / legs | **Shipped** (#41), research unverified | L | none |
| G9 | Study weekly exercise loading for maximum progress | **Delivered** (#42), sources unverified | S | none |
| G10 | Restart or delete a recorded workout from the history lists | **Shipped** (#36) | S | none |
| F1 | Fuel: macro accuracy | **Harness shipped** (#37); baselines not yet recorded | M | none |
| F2 | Fuel: ingredients from photo, user corrects, then AI analysis | **Shipped** (#38); acceptance 6 unmeasured | L | none |

**Scope flags.** `LLR-app/CLAUDE.md` approves a closed list of features beyond v1. G7 (workout categories, yoga) and G8 (stretch sessions) are not on it. Add them to "Approved beyond v1" before building, or drop them. G6 and G5 are refinements of approved features.

**Verification status.** The full XCTest suite (384 tests, including the new tests for G4–G10, F1 and F2) was built and run on a macOS runner via `.github/workflows/tests.yml`: 0 failures, 1 skipped (the live OpenRouter accuracy report, which needs `OPENROUTER_KEY`). Run 38380254951, PR #45. Still unverified: F1 baselines and F2 acceptance 6 (need an OpenRouter key), G5 force-quit persistence and all UI behaviour (need a device), and the G8/G9 source quotes.

## Build order

```
G4 ──────────────────────────────┐   independent, ship first (smallest)
G5 ──────────────────────────────┤   independent
G5 ──> G10                       │   G10 reuses G5's shared workout presentation
F1 (eval harness) ──> F2         │   F2 is judged against the F1 baseline
G6 ──┐
G7 ──┴──> G8                     │   G8 needs timed warm-up/stretch rows and a category to attach to
G9 ──────────────────────────────┘   research doc, any time
```

Why this order: G4 and G5 are the cheapest wins and touch no model. F1 comes before F2 because without a baseline error number nobody can say whether the two-step flow is better. G8 reuses G6's timed rows and G7's category, so it goes last. G10 follows G5 because once the active workout is presented from `MainTabView`, "Repeat" from any list can use it; before that, every list would need its own full-screen cover.

---

## Shipped — no work, one follow-up each

### G1. Reorder exercises (notes lines 2 and 10)

- **Where:** `ActiveWorkoutModel+Reorder.swift:23-37` (`canMove`, `move`), menu entries in `ExerciseLogCard.swift:36-41`.
- **Behaviour today:** "Move Up" / "Move Down" swap `order` with the neighbour; Lock Screen is re-synced.
- **Gap:** one step per tap, no drag. For a 7-exercise workout, moving the last to first is 6 taps.
- **Follow-up (optional, S):** `.onMove` drag handles in a reorder mode, as already done for steps in `InstructionStepsEditor.swift:16`. Not required to close the original note.

### G2. Replace exercise (notes line 5)

- **Where:** `ActiveWorkoutModel+Reorder.swift:7` (`swap`), button at `ExerciseLogCard.swift:34`, hidden for Kineto picks (`ExerciseLogCard.swift:32`).
- **Behaviour today:** ticked sets stay on the old exercise, unticked sets move to the new one, prefilled from the new exercise's history. Covered by `ExerciseSwapMoveTests.swift`.
- **Gap vs the reference ("like MuscleWiki"):** the picker opens the whole library. Follow-up (S): open it pre-filtered to the replaced exercise's `muscleGroup`, with a "Show all" chip. No schema change.

### G3. Remember last weights (notes line 6)

- **Where:** `ActiveWorkoutModel.swift:47-50` mirrors last session's set count; `Exercise.progressionPrefill` (`ExerciseLibrary.swift:152`) feeds `Progression.prefill`.
- **Scoping:** history is per exercise and per section (`Models.swift:162-164`), not per workout type. Bench logged on a "Push A" day pre-fills a "Push B" bench from whichever session was most recent.
- **Open question for the owner:** does "of that type" mean *same exercise, any workout* (works today) or *same routine/day* (not built)? If the latter, filter `sessions(...)` by `Workout.name`. Cost: S, no schema change. Recommendation: keep today's behaviour. Per-exercise history is what progression math needs; per-routine history fragments it.

---

## G4. Edit button for routines

**Why:** the notes ask for it; today editing is hidden behind "See All".

**Current state**
- Edit exists only in the full list: `RoutineListView.swift:18` sets `editing`, sheet at `RoutineListView.swift:29`.
- The Workout tab's `routineRow` (`WorkoutTabView.swift:143-159`) shows name, exercises and a Start button only.
- The tab already presents `RoutineBuilderView` for new routines via `buildingRoutine` (`WorkoutTabView.swift:14`, sheet at `:95`).

**Change**
- Add a trailing `Menu` (ellipsis) to `routineRow` with "Edit" → `buildingRoutine = routine`. Reuse the existing sheet; no new state.
- Confirm `RoutineBuilderView`'s empty-draft cleanup does not delete a saved routine opened this way (comment at `RoutineBuilderView.swift:11` says it should not; verify with a test).

**Files:** `LLR/Workout/WorkoutTabView.swift` only.

**Acceptance**
1. Every row under "My Routines" has an Edit action reachable in one tap on the menu plus one tap on Edit.
2. Renaming a routine and saving updates the row text without leaving the tab.
3. Starting the routine after an edit creates a workout with the edited exercises, order and set plans.
4. Closing the editor without changes leaves the routine and its `createdAt` untouched.
5. Editing a routine does not change any finished workout in History.
6. Edit stays enabled while a workout is in progress (Start is the only action disabled, as at `WorkoutTabView.swift:155`).

**Tests:** +1 unit in `RoutineFactoryTests` (edit then start reflects edits). UI check by hand.

**Out of scope:** editing a routine *from inside* an active workout; duplicating routines.

**Effort:** 1 h.

---

## G5. Minimised workout stays on screen

**Why:** the owner wants to leave the workout to check something in the app (a past session, an exercise page) and keep it one tap away, like a minimised video.

**Current state**
- The chevron already dismisses without ending the workout (`ActiveWorkoutView.swift:141-147`).
- Resuming is only possible from the Workout tab, via `presented` state local to `WorkoutTabView` (`WorkoutTabView.swift:88-92`). Anywhere else in the app, an open workout is invisible.
- Persistence is not the problem: `Workout` and its sets are SwiftData objects, and the rest timer is a process-wide singleton, `RestTimer.shared` (`RestTimer.swift:9`), so a running rest survives dismissal. The model (`ActiveWorkoutModel`) is rebuilt on reopen (`ActiveWorkoutView.swift:16`) from the stored workout.

**Change**
- New `MiniWorkoutBar` view, shown above `FloatingTabBar` in `MainTabView`'s bottom inset (`MainTabView.swift:16-18`) whenever an unfinished workout exists and the full-screen workout is not presented.
- Contents: workout title, elapsed time (`Workout.duration`, `Models.swift:129`, driven by a `TimelineView`), and the rest countdown when `RestTimer.shared.isRunning`. Tap reopens the full-screen workout.
- Move ownership of the active-workout `fullScreenCover` from `WorkoutTabView` to `MainTabView` so any tab can present it. `WorkoutTabView` keeps its Start/Resume buttons but sets the shared state.
- Applies to Kineto workouts too (same unfinished query, `WorkoutTabView.swift:7-9`).

**Files:** `LLR/Main/MainTabView.swift`, `LLR/Workout/WorkoutTabView.swift`, new `LLR/Workout/MiniWorkoutBar.swift`.

**Acceptance**
1. With an unfinished workout, the bar appears on all four tabs; with none, it is absent.
2. Tapping the bar presents the workout with every ticked set, weight and rep unchanged.
3. Tapping Finish or discarding the workout removes the bar.
4. A rest started before minimising is still counting down in the bar, and ends at the same instant as in the full view.
5. Force-quit and relaunch: the bar is present and reopening shows all sets ticked before the quit. (UNVERIFIED that SwiftData autosave has flushed at an arbitrary kill point; test it on device and, if it fails, save explicitly in `toggle(_:)`.)
6. Bar plus tab bar do not cover tab content: scroll views end above both.

**Tests:** logic is trivial; one XCTest for a `hasActiveWorkout` helper if extracted. The rest is manual on device.

**Out of scope:** drag-to-minimise gesture, matched-geometry animation, Picture-in-Picture style floating window.

**Effort:** 1 h bar + 2 h moving presentation + 1 h on-device verification.

---

## G6. Warm-up measured by time

**Why:** a warm-up is "5 minutes on the bike", not "40 kg × 12".

**Interpretation chosen:** a warm-up *exercise* logged by duration (cardio or mobility at the start of a session). Rejected alternative: making the warm-up *sets* of a lifting exercise timed. A warm-up set is defined by its load ramp (`SetKind.warmup`, `SetKind.swift:5`); time carries no meaning for it. If the owner meant the second, say so and G6 changes to per-set rendering.

**Current state**
- Duration sets exist: `SetEntry.durationSeconds` (`Models.swift:68`), rendered by `HoldSetRowView`, chosen when *every* set of an exercise has a duration (`isDurationBased`, `Models.swift:104`).
- Timed gym exercises already get a progression rule (`Progression.Rule.time`, `Progression.swift:34`).
- Warm-up-kind sets are excluded from progress and PRs (`SetKind.countsTowardProgress`, `SetKind.swift:25`).
- The library has no obviously dedicated warm-up entries. A name search of `Resources/exercises.json` for cardio terms returns 57 hits; whether any are timed is UNVERIFIED and must be checked first.

**Change**
1. Audit `exercises.json` for timed entries; add original-text (not copied) timed warm-up entries where missing: easy cardio, dynamic mobility. Each is duration-based by default.
2. When a timed exercise is added to a workout as its first entry, default its sets to `kind = .warmup`, so it is excluded from volume, PRs, and Weekly Volume.
3. Duration entry in `HoldSetRowView` supports minutes up to 30 (verify the current cap).
4. Timer: completing a timed set must not start a long rest. A warm-up-kind set uses 0 s rest (extend `RestDuration.resolve` caller at `ActiveWorkoutModel.swift:109`).

**Files:** `LLR/Resources/exercises.json`, `LLR/Workout/ActiveWorkoutModel.swift`, `LLR/Workout/ExerciseLogCard.swift` (default kind). Possibly `LLR/Logic/RestDuration.swift`.

**Acceptance**
1. A timed warm-up exercise can be added, shows a duration row (not weight × reps), and can be ticked.
2. Ticking it starts no rest timer.
3. It adds 0 to `Workout.volumeKg`, to Weekly Volume sets and to any PR.
4. It appears in History and CSV export with its duration (`WorkoutCSV.swift:7` already carries `durationSeconds`).
5. Existing duration-based exercises (planks, Kineto) behave exactly as before.

**Tests:** +2 unit (`SetKindTests`: warm-up timed set contributes nothing; rest resolution returns none for warm-up kind), +1 in `WorkoutCSVTests` (round trip).

**Out of scope:** guided countdown with audio; GPS or heart-rate input.

**Effort:** 1 h library audit + 2 h library entries + 2 h defaults and rest + 1 h tests.

---

## G7. Colour-coded sessions: push / pull / legs / yoga

**Scope flag:** not in "Approved beyond v1". Needs a line added to `LLR-app/CLAUDE.md` first.

**Why:** see the training split at a glance in routines, History and the calendar.

**Current state**
- `WorkoutSection` is only `gym | kineto` (`Exercise.swift:56-58`) and is load-bearing: it scopes History, queries and prefill (`Models.swift:164`, `WorkoutTabView.swift:7-11`). It must not be overloaded.
- No category exists on `Workout` or `Routine` (`Models.swift:5-21`, `RoutineModels.swift:5-12`).
- "Yoga" has no exercises in the library; as a category it is only a label.

**Migration impact (state before building):** add `categoryRaw: String = ""` to `Workout` and to `Routine`. Additive with a default, so lightweight migration applies and no `VersionedSchema` is needed. `PersistenceRecoveryTests` opens the legacy fixture and must stay green; no new fixture required because the change is additive.

**Change**
- New `enum SessionCategory: String { push, pull, legs, yoga }` with a colour per case in `Theme`, plus a plain (`""`) uncategorised state.
- Set it three ways: routine editor picker, blank-workout start sheet, and inheritance when a workout starts from a routine (`WorkoutFactory.start(routine:)`, `WorkoutFactory.swift:49-62`).
- Show it as a coloured dot/chip on routine rows, History rows, the calendar day, and the active-workout header.
- Library programs (`RoutineLibrary.swift`, `ProgramDayCard`) map days to categories where the day name makes it unambiguous ("Push", "Pull", "Legs"); unmapped days stay uncategorised.
- Colours must pass contrast against `Theme.card` in light and dark.

**Files:** `LLR/Models/Models.swift`, `LLR/Models/RoutineModels.swift`, `LLR/Components/Theme.swift`, `LLR/Workout/WorkoutFactory.swift`, `LLR/Workout/RoutineBuilderView.swift`, `LLR/Workout/WorkoutTabView.swift`, `LLR/History/*` row views, `LLR/Profile/WorkoutCalendarView.swift`. That is more than 3 files: this item needs its own plan review before work starts.

**Acceptance**
1. Four categories plus uncategorised; each has a distinct colour readable in light and dark.
2. A workout started from a categorised routine carries that category.
3. Category is editable after the fact on a finished workout.
4. Existing workouts and routines open as uncategorised with no data loss (`PersistenceRecoveryTests` passes unchanged).
5. Category never affects history scoping, prefill, PRs or Weekly Volume.
6. CSV import/export are unchanged (category is not part of the Strong format).

**Tests:** +3 unit (`SessionCategory` raw round trip and unknown raw → uncategorised; factory inheritance; library day mapping), existing persistence test.

**Out of scope:** auto-detecting category from muscles; per-category stats pages; yoga exercises (see G8).

**Effort:** 2 h model + 3 h UI surfaces + 1 h library mapping + 1 h tests.

---

## G8. Stretching session after push / pull / legs

**Scope flag:** not in "Approved beyond v1". Depends on G6 (timed rows) and G7 (category).

**Why:** end each push/pull/legs session with a short stretch matched to what was trained.

**Current state**
- Nothing stretching-specific. Kineto has `mobility` and `nerveMobility` groups (`KinetoCatalog.swift:27-28`) but Kineto is a physiotherapist-gated back-care section with its own gate and pain logging; reusing it for general stretching would bypass that gate or dilute it.
- The routine library convention is *cited* programs (`docs/routine-library-research.md`).

**Change**
- Three built-in stretch routines (push, pull, legs), each a timed list (G6 rows), added to the routine library with source citations in a new research note, following the existing convention.
- On Finish of a categorised push/pull/legs workout, the summary offers "Add cooldown", which starts the matching stretch routine as a new workout (new `Workout`, same day, category = same).
- Stretch exercises are original-text library entries (no copied text or images), marked so they are excluded from volume and PRs (reuse G6's warm-up-kind default, or a `.warmup` equivalent).

**Files:** `LLR/Models/RoutineLibrary.swift`, `LLR/Resources/exercises.json`, `LLR/Workout/WorkoutRecap`/summary view, `LLR/Workout/WorkoutFactory.swift`, new `docs/stretch-routine-research.md`.

**Acceptance**
1. Finishing a push, pull or legs workout offers the matching stretch routine; finishing uncategorised or yoga workouts does not.
2. Starting it creates a separate workout whose rows are timed and count toward no volume, PR or Weekly Volume.
3. Each stretch routine cites at least one named source in the research note.
4. Declining the offer leaves no stray unfinished workout (`WorkoutFactory.removeEmptyHistory`, `WorkoutFactory.swift:9`, still cleans drafts).

**Tests:** +2 unit (matching routine chosen per category; no offer for other categories), +1 library validity (`RoutineLibraryTests` already validates entries).

**Out of scope:** yoga content; guided stretch videos (media attach already exists per exercise and can be used by the owner).

**Effort:** 4 h research + 3 h entries + 3 h UI and factory + 1 h tests.

**Open question:** should the stretch be a separate workout (spec above) or appended to the finished one? Recommendation: separate. Appending would change a finished workout's duration and volume after the fact.

---

## G9. Study weekly exercise loading for maximum progress

**Type:** research deliverable, no code.

**Why:** the notes ask to study how load should change week to week.

**Current state:** `Progression.swift` already implements double progression, linear, Greyskull LP and a time rule with a 10% deload after 3 stalled sessions (`Progression.swift:19-28`). Weekly Volume against a cited 10–20 set zone exists (`LLR/Logic/WeeklyVolume.swift`).

**Deliverable:** `docs/progression-research.md`, in the style of `docs/routine-library-research.md`: sources with quotes, a table comparing each source's rule to the four existing rules, and a list of *gaps* only. Candidate topics: RIR-based autoregulation (`SetEntry.rir` already stored, `Models.swift:71`), planned deload weeks versus the stall-triggered deload, weekly set progression.

**Acceptance**
1. Every claim has a named, linkable source and a quote.
2. Each gap is stated as "rule X lacks Y; source Z does Y", with a proposed change and its migration impact. Changes are proposals only.
3. No code or schema edited.

**Effort:** 3–4 h.

---

## G10. Restart or delete a recorded workout

**Scope:** within approved v1 (item 1 "copy of a previous one", item 5 "history list"). No scope flag.

**Why:** the owner wants to restart or delete a recorded training without hunting for it.

**Interpretation chosen:** "restart" means *start a new workout from a past one* (today's "Repeat"). Rejected alternative: reopen the finished workout (`endedAt = nil`) and keep logging in it. That rewrites the recorded duration and the "sessions that started earlier" basis for its records (`Models.swift:106-108`), and Edit already corrects a finished workout (`WorkoutDetailView.swift:117`). If the owner meant reopening, say so and this item changes.

**Current state**
- Both actions already exist, but only in the workout detail screen's `…` menu: Repeat at `WorkoutDetailView.swift:121-124` (gym only, disabled while a workout is unfinished, no reason shown), Delete at `:129` with a confirmation dialog at `:149-154`.
- Repeat is also offered on the Workout tab for the 10 most recent gym workouts (`WorkoutTabView.swift:64-66`, `:171`).
- The history lists are `LazyVStack`s of `NavigationLink`s: Home (`HomeView.swift:14-19`) and Profile (`ProfileView.swift:94-98`). Neither has a context menu or swipe actions, so reaching Delete takes open workout, `…`, Delete, confirm. `swipeActions` would not work here without converting to `List`; a context menu does.
- Repeat copies exercises, order, superset groups and the *completed* sets' weight, reps, kind and duration into a new workout (`WorkoutFactory.swift:18-40`). The source is never modified.
- Delete is `context.delete(workout)` with no explicit save and no widget sync. Sets and exercises go with it by cascade (`Models.swift:21`). The streak widget only refreshes when the app next backgrounds (`MainTabView.swift:21`).
- Derived data needs no cleanup: progression, PRs and recovery are recomputed from the log on every read (`Progression.swift:5-7`).

**Change**
- New shared modifier `workoutActions(_ workout:)` in a new file, applied to `WorkoutCard` in Home and Profile and used by `WorkoutDetailView`'s menu, so the repeat and delete logic exists once.
- Long-press menu: "Repeat Workout" (gym only) and "Delete Workout" (destructive). Repeat starts the workout via the presentation action from G5.
- When Repeat is disabled because a workout is in progress, the label says why: "Repeat Workout (finish current first)".
- Delete keeps the confirmation. For a workout with recorded pain (`Workout.hasPainRecorded`, `Models.swift:39`), the confirmation text says the pain log is deleted too.
- After delete: `try? context.save()` then `TrainingSnapshotSync.sync(context:)`, so the widget streak is correct immediately.

**Decision:** no undo for workout delete. Strongest rejected alternative: an Undo toast like sets and exercises have (`ActiveWorkoutModel+Undo.swift:11`). `WorkoutSnapshot` (`WorkoutSnapshot.swift:7`) copies name, notes, dates and entries but not `sectionRaw` or the four Kineto pain fields (`Models.swift:14-17`), and the toast host exists only in the active workout screen. Undo would need a snapshot extension plus a host in two list screens, for an action that already asks for confirmation.

**Files:** `LLR/History/WorkoutDetailView.swift`, `LLR/Home/HomeView.swift`, `LLR/Profile/ProfileView.swift`, new `LLR/History/WorkoutActions.swift`. 4 files: plan approval before editing. Requires G5 for the shared presentation.

**Acceptance**
1. Long-pressing a workout card in Home and in Profile shows Delete; gym workouts also show Repeat.
2. Repeat creates a new unfinished workout with the source's exercises, order, superset groups and completed sets (weight, reps, kind, duration), `startedAt` of now, and opens it full-screen. The source workout is unchanged.
3. With a workout already in progress, Repeat is disabled and its label states why. Kineto workouts show no Repeat, as today.
4. Delete asks for confirmation; confirming removes the workout, its exercises and its sets, and it disappears from Home, Profile, the calendar and the heatmap.
5. After delete, that workout no longer counts in exercise history and prefill, PRs, Weekly Volume, muscle recovery or the streak, and the widget snapshot is regenerated in the same action.
6. Deleting a Kineto workout with recorded pain shows a confirmation that mentions the pain log.
7. Delete never removes an `Exercise`, custom exercise, exercise media or routine.
8. The detail screen's `…` menu behaves as before (same actions, same confirmation).
9. No path deletes an unfinished workout; that stays Discard (`ActiveWorkoutView.swift:35`).

**Tests:** +3 unit in `WorkoutEditingTests`: delete cascades to sets and exercises entries but keeps the `Exercise`; delete removes the session from `Exercise.sessions(...)`; repeat copies structure and completed sets and leaves the source untouched. `TrainingSnapshotTests` already covers the sync output. Context menu and confirmation are checked by hand.

**Out of scope:** reopening a finished workout; multi-select bulk delete; undo (see Decision); repeating a Kineto session (it starts through its pain check-in, `WorkoutDetailView.swift:119`).

**Effort:** 1 h shared modifier + 1 h wiring both lists + 1 h detail refactor + 1 h tests. Plus G5.

---

## F1. Fuel: macro accuracy

**Why:** the owner reports the current model does not measure calories and macros correctly.

**Current state**
- One call does everything: the model identifies foods, guesses grams *and* returns kcal and macros in one JSON (`FoodAnalysis.swift:51-58` prompt, parse at `:104-135`).
- Default is a free model, `google/gemma-4-31b-it:free` (`OpenRouterClient.swift:10`), with free fallbacks (`:12`). Temperature 0.2 (`FoodAnalysis.swift:74`).
- The only quality check is `kcalLooksInconsistent`, which flags kcal vs 4/4/9 mismatch over 25% (`FoodAnalysis.swift:24-28`). It cannot detect a wrong portion or wrong food.
- Tests only cover parsing (`FoodAnalysisTests.swift`), not accuracy.

**Root cause (hypothesis, UNVERIFIED until measured):** portion estimation from a photo is the largest error source, and free models do the arithmetic from memory. Neither is measured today.

**Change**
1. Build an accuracy harness before changing anything: a fixture set of 20 meals with known weights and USDA-based ground-truth kcal/macros, a script that runs the current pipeline against a chosen model, and a report of mean absolute percentage error per meal and per macro. Fixtures are text descriptions first (no network flakiness from photos); a smaller photo set is optional.
2. Record the baseline for the current default and for one paid model from `OpenRouterClient.paidModels` (`:15`).
3. Only then change prompt/model/pipeline (F2) and compare.

**Files:** new `LLRTests/FoodAccuracyTests.swift` (skipped unless an `OPENROUTER_KEY` env var is set, so CI never calls the network), new fixture JSON under `LLRTests/Fixtures`, new `docs/fuel-accuracy.md` for results. No production code changes.

**Acceptance**
1. Harness runs from one command and prints per-meal and mean kcal and macro error.
2. Fixture set has 20 meals with a source for each ground-truth number.
3. Baseline is recorded in `docs/fuel-accuracy.md` with model name and date.
4. The default test run skips these tests and passes with no network and no key.

**Out of scope:** switching the default model (a result of this item, not part of it).

**Effort:** 3 h fixtures + 2 h harness + 1 h baseline runs.

---

## F2. Fuel: ingredients from a photo, user corrects, then analysis

**Why:** letting the owner fix the AI's ingredient and portion guess before macros are computed removes the biggest error source and matches how a person would estimate a meal.

**Current state**
- Photo or text goes straight to macros; the review screen edits *results* (`FoodReviewView.swift`, name and numeric fields at `:51` and `:77`), after the fact.
- A text-only path already exists (`FoodAnalysis.Input.text`, `FoodAnalysis.swift:7-9`), so Stage 2 can reuse it.
- `FoodEntry` stores one item per row (`FoodModels.swift:31-40`); no schema change needed.

**Change: two stages**
1. **Identify (vision):** photo → list of `{name, grams}` only, no macros. New prompt and parser alongside the existing ones (`FoodAnalysis.swift`).
2. **Correct (user):** new editable list screen: rename, change grams, delete, add an ingredient, before anything is analysed. Prefills from Stage 1.
3. **Analyse (AI, text):** the corrected list is sent as text through the existing `.text` path with the quantities stated explicitly; the response flows into the existing `FoodReviewView` as today.
4. Text-only input (no photo) skips Stage 1 and goes straight to the correction screen with the parsed description, or directly to analysis if the user chose "Estimate macros" without a photo (current behaviour kept).

**Decision:** AI does Stage 3, as the owner specified. Strongest rejected alternative: compute macros in-app from a bundled USDA-derived table and use the model only to identify foods and grams. It is more accurate and free to run per meal, but needs a curated per-100 g table and name matching. Revisit it only if F1 shows Stage 3 arithmetic is a large error source after portions are corrected.

**Network and privacy:** still exactly the existing OpenRouter call, now two calls per photo meal (vision then text), only when the user taps. The Stage 3 request carries no image. Update the privacy line in `LLR-app/CLAUDE.md` ("only network call") to say two requests per estimate.

**Files:** `LLR/Logic/FoodAnalysis.swift` (identify prompt + parser; this file will exceed ~200 lines, so split into `FoodAnalysis+Identify.swift`), `LLR/Logic/OpenRouterClient.swift` (new entry point), `LLR/Fuel/AddFoodSheet.swift` (routing), new `LLR/Fuel/IngredientCorrectionView.swift`. 4 files: needs plan approval before editing.

**Acceptance**
1. A photo produces an editable ingredient list (name + grams) and no macros are shown or saved before the user confirms.
2. The user can change a name, change grams, delete an ingredient and add one; Analyse is disabled when the list is empty or any grams is zero or negative.
3. The Stage 3 request body contains the corrected names and grams and no image data (assert in a unit test on `requestBody`).
4. Nothing is saved to `FoodEntry` until the existing review screen is confirmed (invariant from `CLAUDE.md`: "nothing saves without review").
5. Error states from `OpenRouterClient.ClientError` (`:17-33`) are shown for each stage, with "Enter manually" still available.
6. F1 harness shows mean kcal error on the photo-derived fixtures is lower than the F1 baseline; if not, the result is reported, not hidden.

**Tests:** +3 unit (identify parse incl. fenced/garbled JSON as at `FoodAnalysis.swift:90-93`; correction → text request body; empty/zero-gram validation), existing parse tests unchanged.

**Out of scope:** barcode scanning; saving ingredient corrections as personal food presets (a good later feature, not now).

**Effort:** 2 h prompt/parser + 4 h correction screen + 2 h routing and errors + 2 h tests.

---

## Rollback

Every item is a revert of its own PR. G7 is the only schema change and is additive, so reverting the code leaves two unused columns with defaults and no data loss. Nothing here changes `Persistence.open`'s set-aside-on-failure behaviour.
