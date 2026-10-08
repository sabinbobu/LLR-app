# LLR — iPhone gym session tracker

## What it is
A local-first iPhone app for logging gym sessions: pick exercises, log sets (weight × reps), see what you lifted last time, and track progress per exercise. Solo project, built lean.

## Reference app (UI clone)
LLR is a functional clone of an existing gym tracker. The owner will provide screenshots of that app in `/reference/` (one file per screen, named by screen, e.g. `workout-active.png`).
- Before building any screen, read the matching screenshot and replicate its layout, hierarchy, spacing, and interaction flow in SwiftUI using native components.
- If a screen has no screenshot, ask for one instead of inventing the design.
- Do not copy the reference app's name, logo, icons, illustrations, exercise images, or exercise library text. Use SF Symbols and original content; recreate structure, not assets.
- Where a screenshot conflicts with the v1 scope below, the scope wins and the conflict gets flagged.

## Core principle
Logging a set must take at most 2 taps mid-workout. Every design decision is judged against this. Speed of entry beats feature count.

## v1 scope (ship this, nothing else)
1. Start a workout (blank, or copy of a previous one)
2. Add exercises from a built-in library or create custom ones
3. Log sets: weight, reps; previous session's values pre-filled
4. Rest timer that starts on set completion
5. History list of past workouts
6. Per-exercise progress: best set, estimated 1RM (Epley), simple line chart (Swift Charts)

## Approved beyond v1
- Import Hevy/Strong CSV exports; export a Strong-format CSV
- Lock Screen Live Activity: complete the next set, adjust or skip rest
- Rule-based progression targets inside a per-exercise rep range (double progression)
- Kineto: a physiotherapist-gated section for logging cited, low-load back-care exercises and pain before/after each session (see `LLR/Kineto/`, `LLR/Models/KinetoCatalog.swift`). Content still needs real clinical sign-off — see the roadmap in the plan this was built from.
- Exercise photos and videos (PRs #14, #15, plan in `docs/kineto-v2-plan.md`): your own photos/videos and notes on custom exercises, and notes/media on built-in Kineto exercises. Files live in Application Support (`ExerciseMediaStore`); photos are downscaled and videos re-encoded to 720p.
- Routines: a built-in library of 16 cited programs plus a routine builder (see `LLR/Models/RoutineLibrary.swift`, `docs/routine-library-research.md`).
- PRO features (ungated, no paywall — see `/Users/bobus/.claude/plans/scalable-doodling-gray.md` for the full plan and phase breakdown):
  - Live "New PR!" banner during a workout, plus a Records count in the workout header
  - Muscle recovery: a front/back body map with a per-muscle recovery % derived from recent working sets
  - Post-workout summary card with a shareable image
  - Stats: date-range picker (3M/6M/Year/All), a muscle-split radar chart, a training calendar with a weekly streak
  - Body measurements (weight, body fat, tape sites, height) and progress photos
  - A Home Screen widget showing the training streak
  - Weekly Volume: hard sets per muscle per week (secondary muscles count half) against a cited 10–20 set zone (`LLR/Logic/WeeklyVolume.swift`)
- Fuel (4th tab, `LLR/Fuel/`): food logging with daily calorie/macro targets (Mifflin-St Jeor + goal, protein 1.6 g/kg, all overridable). Optional AI estimates from a photo or description via free OpenRouter vision models, using the user's own key (Keychain). AI output is always an editable draft; nothing saves without review.

## Non-goals (do not build in v1)
Accounts, cloud sync, social features (leaderboards, friend comparisons), AI coaching or AI-generated/auto-generated workouts, Apple Watch, subscriptions/paywalls, HealthKit write-back.

## Stack
- Swift 5.9+, SwiftUI, iOS 17+ minimum
- SwiftData for persistence (no backend). The only network call is Fuel's OpenRouter request (`LLR/Logic/OpenRouterClient.swift`), made with the user's own key and only when they ask for an estimate; nothing else leaves the device. Device backup (iCloud/Finder) includes the SwiftData store and `ExerciseMedia` files alike (`Backend/ is a Cloudflare Worker + D1 exercise API the app does not call; see `Backend/README.md`)
- Swift Charts for progress graphs
- XCTest for logic; no UI tests until v1 is usable
- No third-party dependencies unless unavoidable

## Data model (SwiftData)
All 11 `@Model` classes are listed in `LLR/Models/Persistence.swift`; a type missing there is not stored.
- `Exercise` (`Exercise.swift`): id, name, muscleGroup, isCustom, restSeconds?, equipment, secondaryMuscles, instructions, repRangeMin/Max?, `sectionRaw` ("gym" | "kineto"), `kineto*` fields (all optional), personalNotes, `media` (cascade), `usages`
- `Workout`: id, startedAt, endedAt?, notes, name, exercises (cascade)
- `WorkoutExercise`: workout, exercise, order, sets (cascade)
- `SetEntry`: workoutExercise, order, weightKg, reps, completedAt?, kindRaw, durationSeconds?
- `Routine` / `RoutineExercise` / `RoutineSetPlan` (`RoutineModels.swift`): saved programs, cascade down the chain
- `BodyMeasurement`, `ProgressPhoto` (`MeasurementModels.swift`)
- `FoodEntry` (`FoodModels.swift`)
- `ExerciseMedia` (`ExerciseMedia.swift`): kindRaw, fileName, createdAt, exercise; bytes are files, not store data
- Store weight in kg internally; convert for display only.
- Migration: there is no `VersionedSchema`; every change must be an added property with a default (or optional) or a new entity, so lightweight migration applies. `PersistenceRecoveryTests` opens a real store written before Fuel/media (`LLRTests/Fixtures/legacy-pre-fuel.store`, made from commit 1ba2d27) — add a fixture the same way before any non-additive change. If a store fails to open, `Persistence.open` sets it aside as `*.corrupt-<timestamp>` and starts empty rather than crashing.

## Conventions
- One view per file; view logic that isn't trivial goes in an `@Observable` view model
- Pure logic (1RM math, previous-set lookup, PR detection) lives in plain structs with unit tests
- Comments explain WHY, never WHAT
- No placeholder code or `TODO` stubs committed; a feature is either working or absent
- Keep files under ~200 lines; split when exceeded

## Commands
- Build: `xcodebuild -scheme LLR -destination 'platform=iOS Simulator,name=iPhone 17' build`
- Test: `xcodebuild -scheme LLR -destination 'platform=iOS Simulator,name=iPhone 17' test`
- After editing `project.yml`, or adding/removing files under `LLR/`, run `xcodegen generate` before building — it scans the tree at generation time and won't pick up new files on its own.

## Working rules for Claude
- Implement one v1 item at a time; run build and tests before declaring it done
- If a change touches the data model, state the migration impact first
- Don't add features outside v1 scope; flag them instead
- After 2 failed fixes for the same error, stop and report the error plus top 2 hypotheses
