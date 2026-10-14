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
| F3 | Fuel: log food on past days and edit when an entry happened | Built; needs CI and a device check | — |
| R2 | Add Run: distance and time, body and muscle exhaustion | **In review** (spec below) | #52, #53 |
| K1 | Kineto (back care): fix freezes, make the catalog reachable | **Queued** for a future session (spec below) | — |
| U1 | Routine rows: swipe left to delete, replacing the three-dots menu | **Queued** for a future session (spec below) | — |
| U2 | Repeat button: a colour that complements the theme | **In review** (amber tokens and Repeat button done; device check pending) | — |
| U3 | Profile header card: a modern redesign | **Queued** for a future session (spec below; needs design sign-off first) | — |
| D1 | One design system: buttons, cards, corner radii | **Foundation in review** (screens not yet migrated; see `docs/design-system.md`) | — |
| W1 | Workout tab restructure: start in one tap | **Queued** for a future session (spec below; needs design sign-off first) | — |

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

**Suggested order.** D1 first (it defines the buttons, cards and radii the others use), then W1, then U1, U2 and U3 on top of them, and K1 whenever the owner wants the Kineto fixes (it is independent). U2 becomes one case of D1's button roles: if D1 lands first, U2 is done by assigning the amber to the "repeat" role and needs no separate pass.

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

### U1. Swipe left to delete a routine

**Request.** On the Workout tab, replace the three-dots menu on each "My Routines" row with a modern, smooth swipe-left-to-delete gesture.

**What exists today (so the change is scoped correctly)**
- The three-dots menu on a Workout-tab routine row contains only **Edit** (added in G4). It does not delete.
- Delete exists only in *See All → My Routines* (`RoutineListView`), as a native `List` swipe action that calls `context.delete(routine)` immediately: no confirmation and no undo.
- The Workout tab is a `ScrollView` of custom bordered cards, not a `List`, so the native `.swipeActions` is not available there.

**Migration impact.** None. Deleting a routine cascades to its exercises and set plans (existing rule) and never touches finished workouts.

**Design**
1. A reusable `SwipeToDelete` modifier (one file) for a routine card. Dragging left slides the card and reveals a red **Delete** button behind it; dragging past about 60% of the width (a full swipe) deletes it. Releasing earlier snaps open or closed by drag velocity and position.
2. Smoothness is the acceptance bar, not an extra: the card follows the finger 1:1 with no lag, rubber-bands past the end, and settles with a spring (no abrupt jumps); the row below slides up when a row is removed; one light haptic when the delete threshold is crossed and one when it fires.
3. The gesture must never fight vertical scrolling: it only starts when the drag is clearly horizontal, and a swipe that begins on the **Start** button still swipes. Only one row can be open at a time; opening another closes the first; scrolling closes it.
4. **Undo instead of a confirmation dialog.** Delete removes the routine at once and shows an Undo bar (6 s), the same pattern as deleted sets and exercises (`UndoToast`). This needs a `RoutineSnapshot` (name, section, category, exercises, rest, notes, superset, set plans) that can recreate the routine exactly, like `WorkoutSnapshot` does for workouts.
5. **Edit moves to a place that still works without the dots.** Tapping the card body (outside **Start**) opens the editor, and swiping right on a card reveals **Edit**. If neither is wanted, keep a single small edit icon; the owner decides.
6. Remove the ellipsis menu from the Workout-tab rows. Apply the same undo behaviour to the *See All* list so both places agree.
7. Accessibility: VoiceOver gets custom actions **Edit** and **Delete** on each row (the swipe is not discoverable otherwise); Reduce Motion replaces the slide with a fade.

**Decision.** A custom gesture, not a `List`. Strongest rejected alternative: convert the routines section (or the whole Workout tab) to a `List` to get the native swipe, which is the smoothest and most accessible option for free. It was rejected because the tab mixes tiles, navigation cards and bordered rows in one scroll, and nesting a `List` inside a `ScrollView` breaks scrolling; converting the whole tab changes its look and behaviour. Revisit if the custom gesture cannot reach native smoothness on a device.

**Files.** New `LLR/Components/SwipeToDelete.swift`, `LLR/Models/RoutineSnapshot.swift`; edited `LLR/Workout/WorkoutTabView.swift` and `LLR/Workout/RoutineListView.swift`.

**Acceptance**
1. Swiping a routine card left slides it with the finger and reveals Delete; a full swipe deletes it, a short swipe snaps back or open.
2. The gesture never blocks or hijacks vertical scrolling; **Start** still works; only one row is open at a time.
3. Deleting shows an Undo bar; Undo restores the routine with the same name, category, exercises, order, rest, notes, superset groups and set plans.
4. Deleting a routine never changes finished workouts, exercises, or history.
5. The three-dots menu is gone from Workout-tab rows and Edit is still one tap or swipe away.
6. VoiceOver can edit and delete; Reduce Motion is respected.
7. Judged on a device: no dropped frames or visible jumps while dragging, opening, deleting, or undoing.

**Tests.** `RoutineSnapshotTests` (snapshot then restore equals the original, including nested plans, delete cascades, finished workouts untouched). The gesture itself is checked by hand on a device.

**Effort.** About half a day for the gesture and its tuning, plus the snapshot and tests.

### U2. A complementary colour for the Repeat button

**Request.** Change the colour of the **Repeat** button (Workout tab, "Repeat a Workout" rows) to one that is complementary to the whole theme.

**Why it needs doing.** `repeatRow` in `WorkoutTabView` uses `.buttonStyle(.borderedProminent)` with the default tint, which is the theme accent (`Theme.accent`, #2563EB light / #3B82F6 dark). **Start** on the routine rows above it is the same blue, so the two different actions look identical.

**Migration impact.** None. Styling only.

**Decision: amber.** The accent blue sits at a hue of about 221°; its colour-wheel complement is about 41°, which is amber. Chosen values:

| Mode | Button fill | Label | Contrast of label on fill |
|---|---|---|---|
| Dark | #F59E0B (hue 38°) | #1C1300 | 8.6 : 1 |
| Light | #D97706 (hue 32°) | #1C1300 | 5.8 : 1 |

White text on these fills only reaches 2.1 : 1 and 3.2 : 1, so the label must be dark in both modes (WCAG AA needs 4.5 : 1 for text this size).

**Design**
1. New token `Theme.repeatAction` (adaptive, like `Theme.accent`) and `Theme.repeatActionLabel`.
2. Apply to the Repeat button in `repeatRow` only. Start keeps the blue accent. Tint the shape with `.tint(Theme.repeatAction)` and set the label colour explicitly.
3. The disabled state (a workout is in progress) keeps the system disabled look; the label must not become unreadable on it.
4. Keep amber out of macro colours: `Theme.carbs` is a similar yellow reserved for carbohydrates ("colour alone identifies it"), and the Push category is orange. Amber here is on a different screen from carbs, but if either reads too close on a device, shift Repeat toward 30° rather than touching the macro or category colours.
5. Text menu items named "Repeat Workout" (long-press and detail menus) stay uncoloured; only buttons carry the colour.

**Alternatives considered.** A soft tinted button (blue text on a faint blue fill) would also separate the two actions without a new colour, but it stays in the same hue family; the owner asked for a complement, so amber is the pick. Green was rejected because it already means "completed" (`Theme.completedCheck`).

**Acceptance**
1. On the Workout tab, Repeat and Start are clearly different at a glance, in dark and light mode.
2. The Repeat label meets 4.5 : 1 against its fill in both modes, enabled; disabled looks disabled.
3. No other button or view changes colour.
4. Confirmed on a device in both appearance modes.

**Tests.** `ThemeContrastTests`: resolve `repeatAction` and `repeatActionLabel` in light and dark and assert the contrast ratio is at least 4.5.

**Effort.** Under an hour.

### U3. Profile header card redesign

**Request.** Improve the Profile card (the card at the top of the Profile tab: photo, name, age, height, goal, workout count) from a UI point of view: modern and really cool.

**What it is today** (`ProfileHeaderCard.swift`, `AvatarView`, `FlowChips`). A flat `Theme.surface` rounded rectangle: a 76 pt round photo, the name, then a wrapping row of four equal grey chips (age, height, goal, workout count), and a chevron. Problems visible in use:
- Everything is the same weight: the chips carry the numbers, so nothing stands out and the card reads as a form, not a profile.
- The goal chip is long ("Gain Strength") and gets cut off or pushes the other chips onto a second line.
- The "N workouts" chip counts every history entry, so since run tracking it also counts runs. It is mislabelled.
- Nothing about the card says anything about training.

**Migration impact.** None. Display only; it reads values the app already stores.

**Design check first (required).** There is no `/reference/` folder in the repo, and `CLAUDE.md` says to ask for a screenshot rather than invent a screen design. The build session must start by either receiving a reference screenshot from the owner or showing the owner a preview of the direction below and getting a yes. Do not build blind.

**Recommended direction: a hero card.**
1. **Surface.** A subtle gradient (the accent at about 12% into the surface colour), a hairline top highlight, a larger corner radius (28), and a soft shadow in light mode. Static gradients only (no live blur), so scrolling stays smooth.
2. **Avatar with a weekly ring.** A larger photo (about 96 pt) wrapped in a seven-segment ring: one segment per day of the current week, filled when a workout or run happened that day (`TrainingCalendar.trainedDays` already provides this). It fills with a short animation when the screen appears (none with Reduce Motion). The no-photo fallback (gradient with initials) stays.
3. **Header.** Name at the top in a bolder, larger size; the goal as one pill under the name, with room to wrap, never cut off.
4. **Stats row.** A single row of equal columns separated by hairlines: **Age**, **Height**, **Sessions**, **Streak** (weeks). Big monospaced numbers with small labels in the secondary colour. At the largest Dynamic Type sizes it becomes a 2 × 2 grid.
5. **Interaction.** The whole card is still the tap target for the details screen; a small press-down scale with a spring; keep a quiet chevron or drop it (owner's call at the preview).
6. **Sessions, not workouts.** Count lifts and runs together and call the stat **Sessions**; this also fixes the mislabelled chip.

**Constraints.** One view per file and under about 200 lines (split the stats row and the ring into their own views); colours from `Theme` only, with any new token defined adaptively for light and dark; no new data, network or permissions; works in both appearance modes and at all Dynamic Type sizes; VoiceOver reads the card as one element with a sentence ("Sabeen, 28, 169 centimetres, goal gain strength, 4 sessions, 2 week streak").

**Alternatives considered.** A cover-photo style card (large blurred photo behind the name) looks striking but needs a photo; most profiles start with initials, so it would look empty for them. A minimal card (bigger name, fewer chips) is safe but not "really cool". The hero card keeps the photo optional and puts training on the card.

**Acceptance**
1. The goal is never truncated; nothing overlaps at any Dynamic Type size.
2. The ring shows exactly the days of this week with a workout or run; an empty week shows an empty ring.
3. "Sessions" equals the lifts and runs in history; Streak matches the calendar screen.
4. Looks right with a photo, with initials only, and with no name (placeholder).
5. Smooth to scroll past on a device; the animation respects Reduce Motion.
6. The owner approved the preview before the build, and approved the result on a device.

**Tests.** The week-ring segments and the session count are logic: a `ProfileHeaderStats` struct with unit tests (week boundaries, runs and lifts both count, empty week, streak equals `TrainingCalendar.weekStreak`). The visuals are checked by hand.

**Effort.** About a day, including the preview round with the owner.

### D1. One design system: buttons, cards, corner radii

**Source.** A review of the whole UI (code scan of all 229 view files plus the Workout, Kineto and Profile screens). The Home, Fuel and active-workout screens and light mode were not inspected on a device, so the audit step below covers them.

**Problem.** The app has no single set of building blocks, so screens drift apart.
- Six button styles are in use: plain (40 uses), `CardButtonStyle` (15), `PrimaryButtonStyle` (13), the system `.borderedProminent` (9), `SheetButtonStyle` (5) and `.bordered` (3). Three of them are "the main action" with different heights, fonts and disabled looks.
- Ten corner radii are in use (14 is the most common at 32 uses, then 16, 24, 8, 12, 10, 20, 18, 3 and 56).
- Cards differ by screen: the Workout tab uses outline-only cards, Profile uses filled cards.
- On the Workout tab, **Start** and **Repeat** are the same blue button.

**Migration impact.** None. Styling only.

**Design**
1. **Radius scale** in `Theme`: 8 (chips, small controls), 12 (fields, rows), 16 (cards, buttons), 24 (hero cards, sheets). Replace the ten values; anything that is a capsule stays a capsule.
2. **One card style** (`CardStyle`): filled `Theme.card`, one hairline border colour, radius 16, one padding value; an `emphasised` variant for hero cards (U3). The outline-only look is retired.
3. **Four button roles**, each a `ButtonStyle` with one height, font, pressed state and disabled state:
   - **primary**: filled accent, the one main action on a screen;
   - **secondary**: tinted fill, for the second action (the Repeat button's amber lives here, see U2);
   - **quiet**: text only;
   - **destructive**: red, always with a confirmation or an Undo.
   The system `.borderedProminent` and `.bordered` uses are moved to these roles; `PrimaryButtonStyle` and `SheetButtonStyle` collapse into `primary`.
4. A short `docs/design-system.md` that lists the tokens and roles, so new screens use them by default.

**Method.** Add the styles first and change no screen. Then migrate screen by screen (Workout, Profile, Fuel, Home, sheets, Kineto, onboarding), one PR per area, each with before and after screenshots from the simulator in the PR. Finish with a grep check that no screen uses a retired style or an off-scale radius. Keep behaviour identical; this is a visual pass.

**Acceptance**
1. Only the four roles remain in the code; no `.borderedProminent`, `.bordered` or legacy primary style outside the style definitions.
2. Every corner radius comes from the scale.
3. Every card in the app uses `CardStyle` (or its emphasised variant).
4. On the Workout tab, Start and Repeat are visibly different roles.
5. All colours are `Theme` tokens and work in dark and light mode; label contrast is at least 4.5 : 1 (checked by a test over the tokens).
6. No screen changes behaviour, and the owner has looked at each migrated area on a device.

**Tests.** `ThemeContrastTests` for token pairs in both modes; a lint-style test that fails when a banned style or an off-scale radius appears in the source tree.

**Effort.** About two days: one for the styles and the doc, one to migrate the screens.

### W1. Workout tab restructure: start in one tap

**Source.** The same UI review. The Workout tab is the app's core screen; `CLAUDE.md` says speed of entry beats feature count.

**Problem.** The tab is one long scroll of eight or nine sections of equal visual weight, in this order: Start Empty Workout (or Resume), Add Run (and the run summary), Log a Past Workout, Routines (New Routine, Explore Routines), the Kineto card, My Routines (five rows and See All), Repeat a Workout (ten rows), and How to get started. Starting your usual routine can mean scrolling past three screens of other things; the 10-row Repeat list duplicates the history that already has Repeat (G10); the onboarding link never goes away; and the Kineto card sits in the middle of the gym content.

**Migration impact.** None. Layout only.

**Design check first (required).** There is no `/reference/` folder, and `CLAUDE.md` says not to invent a screen design without one. The build session starts by receiving a reference screenshot or by showing the owner a preview of the layout below and getting a yes.

**Recommended layout, top to bottom**
1. **Primary action.** One large **Start Workout** button (Resume when one is open). Beside or under it a compact row of secondary actions: **Add Run**, **Log Past**.
2. **Quick start.** A horizontal strip of cards for the five most recent routines (name, exercise count, a Start button), with **See All** at the end. This is where U1's swipe-to-delete, or the card's long-press, applies. New Routine and Explore Routines become two small tiles at the end of the strip or a single "Routines" link.
3. **Repeat last.** One line of up to three chips for the last three workouts ("Repeat: Push Day · Legs day · Night Workout"), replacing the 10-row list. The full history, with long-press Repeat (G10), is unchanged.
4. **Runs.** The run summary card, only when runs exist, below the strip.
5. **Kineto.** A single compact row at the bottom ("Back care") that opens the Kineto hub. The gate, banner and red-flags flow are unchanged (this item does not touch clinical content).
6. **How to get started.** Shown only until the first workout is finished, then removed from the tab. It stays reachable from Profile → Settings → Help.

**Decisions.**
- Chips instead of a list for Repeat: a list with ten rows is what buries everything below it, and history already offers the full list. Rejected alternative: keep the list but collapse it behind a disclosure; this keeps the clutter one tap away but also keeps a second place to maintain the same rows.
- Kineto stays on this tab, but at the bottom: it is a gated section for back care, so it should not be prominent for everyone, and it must stay reachable within two taps of app launch.

**Acceptance**
1. From a cold launch, starting one of your three most recent routines takes two taps (Workout tab, then Start) with no scrolling, on an iPhone 15-sized screen.
2. The primary Start action is the most prominent control on the tab; Resume replaces it while a workout is open.
3. Quick start shows the five most recent routines in order; See All opens the full list; Edit and delete still work.
4. Repeat last shows the last three finished gym workouts and starts a copy in one tap; disabled with a reason while another workout is open.
5. Kineto is reachable in at most two taps from launch and its gate and disclaimer are unchanged.
6. The onboarding row disappears after the first finished workout and its content is still reachable from Settings.
7. The tab scrolls less than one screen on a typical account; nothing is hidden behind the tab bar.
8. The owner approved the preview before the build and approved the result on a device.

**Tests.** Pure logic: which routines are "recent", which workouts qualify for Repeat last (gym only, finished, last three), and when the onboarding row shows. The layout is checked by hand.

**Depends on / interacts with.** D1 (use its card and button roles); U1 (swipe-to-delete applies to the strip's cards, so build W1's cards first or build U1 against the strip); U2 (the Repeat chips take the secondary role).

**Effort.** About a day and a half, including the preview round.

## Possible later

- G1 drag-to-reorder.
- Ingredient corrections saved as personal food presets (F2 follow-up).
- RIR-aware progression and a planned-deload prompt (G9 proposals; wait for verified sources).
- USDA lookup table for Fuel, only if F1 shows arithmetic error dominates.

## Rollback

Every item is a revert of its own PR. The only schema changes are additive: `categoryRaw` on `Workout` and `Routine` (G7) and `distanceKm` on `Workout` (R2); reverting the code leaves unused columns with defaults and no data loss. Nothing here changes `Persistence.open`'s set-aside-on-failure behaviour.
