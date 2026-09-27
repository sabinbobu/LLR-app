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
- Kineto: a physiotherapist-gated section for logging cited, low-load back-care exercises and pain before/after each session (see `LLR/Kineto/`, `KinetoCatalog.swift`). Content still needs real clinical sign-off — see the roadmap in the plan this was built from.
- Routines: a built-in library of 16 cited programs plus a routine builder (see `LLR/Models/RoutineLibrary.swift`, `docs/routine-library-research.md`).
- PRO features (ungated, no paywall — see `/Users/bobus/.claude/plans/scalable-doodling-gray.md` for the full plan and phase breakdown):
  - Live "New PR!" banner during a workout, plus a Records count in the workout header
  - Muscle recovery: a front/back body map with a per-muscle recovery % derived from recent working sets
  - Post-workout summary card with a shareable image
  - Stats: date-range picker (3M/6M/Year/All), a muscle-split radar chart, a training calendar with a weekly streak
  - Body measurements (weight, body fat, tape sites, height) and progress photos
  - A Home Screen widget showing the training streak

## Non-goals (do not build in v1)
Accounts, cloud sync, social features (leaderboards, friend comparisons), AI coaching or AI-generated/auto-generated workouts, Apple Watch, subscriptions/paywalls, HealthKit write-back.

## Stack
- Swift 5.9+, SwiftUI, iOS 17+ minimum
- SwiftData for persistence (no backend, no network calls)
- Swift Charts for progress graphs
- XCTest for logic; no UI tests until v1 is usable
- No third-party dependencies unless unavoidable

## Data model (SwiftData)
- `Exercise`: id, name, muscleGroup, isCustom
- `Workout`: id, startedAt, endedAt?, notes
- `WorkoutExercise`: workout, exercise, order
- `SetEntry`: workoutExercise, order, weightKg, reps, completedAt
- Store weight in kg internally; convert for display only.

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
