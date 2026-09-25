# Routine library research

Research for LLR's built-in routine library. Every program below was published by a well-known coach, author or champion bodybuilder. Each section gives the source, a quote from it, choices and substitutions, and one JSON object in the agreed shape. Researched 2026-09-24/25.

## Conventions used in every JSON block

- **Exercise names** are exact `Name` strings from `LLR/Resources/exercises.json`. Anything not in the library is mapped to the closest entry and flagged under "Library substitutions".
- **Set-count ranges** (for example "2–3 sets") use the **lower** bound, and the range goes in `notes`. Rep ranges use `reps` plus `repsMax`.
- **`kind: "failure"`** marks AMRAP, "+", "max reps" and "to failure" sets. When a set has no rep target, `reps` is left out.
- **Warm-ups** are only included when the author makes them part of the prescription (Reg Park's two ramp sets, Arnold Blueprint's 30-rep first set).
- **`rest`** is rounded to the allowed values. It is left out when the author doesn't give one.
- **Duplicate exercises in one routine.** 5/3/1 BBB lists the same lift twice (main sets plus the 5×10). The rest times differ, so they are two entries. The app must allow the same exercise twice in a routine.
- **Weekly percentage waves.** Where a program changes its scheme week to week (5/3/1 main sets, Texas Method), the JSON holds week 1 or a fixed rotation. The percentages go in `notes`.

---

## 1. Starting Strength — Mark Rippetoe

- **Purpose / level / days / equipment:** beginner strength · beginner · 3 days/week · barbell
- **Schedule:** Workout A and B alternate on three non-consecutive days. Phase 1 usually lasts 1–3 weeks. Phase 2 swaps the Day B deadlift for power cleans (5×3). Phase 3 alternates deadlift and clean on Day A and puts chin-ups on Day B. Phase 3 is described but not encoded.
- **Progression:** add weight every session while all work sets are completed.
- **Source:** https://startingstrength.com/get-started/programs. The live site blocks automated readers (Cloudflare), so it was read via Wayback snapshot `web.archive.org/web/20251220211120/…/get-started/programs`.
  > "Perform the program on a 3 day per week schedule, on non-consecutive days, i.e. Mon/Wed/Fri…"
  > "Phase 1 … Squat 5 reps x 3 sets* | Press/Bench Press 5 reps x 3 sets | Deadlift 5 reps x 1 set … *Sets here include only work-sets"
  > "Phase 2 … Deadlift 5 reps x 1 set | Power Clean 3 reps x 5 sets"
  > "…add 10 lbs to the squat the first 2-3 times it's performed, 15-20 lbs to the deadlift the first couple times … After that, jumps become 5 lbs per workout. For the press, bench press, and power clean … 5 lb jumps … Later on, you'll move to 2.5 lb or smaller jumps"
- **Rest:** the program page gives none. Michael Wolf's article on startingstrength.com (https://startingstrength.com/article/rest-between-sets) says: "After a week or two … 3 minutes between sets is usually required … After another few weeks … Moving the rest up to about 5 minutes between sets is usually necessary". Phase 1 therefore uses 180 and Phase 2 uses 300. Rippetoe himself says to rest as long as it takes, "7 minutes … Maybe 8" ("The First Three Questions", 2015). That is above the app's 300 s maximum.
- **Disagreements / choices:** the website shows "Press/Bench Press" in both columns. I encoded press on A and bench on B, which is how the alternation works out and matches the book's A/B.
- **Library substitutions:** none. The press is `Overhead Press (Barbell)`.
- **Trademark:** "STARTING STRENGTH" is registered in the US to Asgaard Funding, L.L.C. (TX) and is live. The registrations cover **mobile app software** (Serial 85760005), books (87176207), DVDs (85146322) and fitness facilities (85459056).

```json
{
  "id": "starting-strength",
  "name": "Starting Strength",
  "author": "Mark Rippetoe",
  "goal": "strength",
  "level": "beginner",
  "equipment": "barbell",
  "daysPerWeek": 3,
  "summary": "Rippetoe's novice linear progression: three heavy barbell lifts per session, three full-body sessions a week, more weight every time. Built for true beginners who want to get strong fast.",
  "schedule": "Alternate Workout A and Workout B on three non-consecutive days (e.g. Mon/Wed/Fri). Run Phase 1 for about 1–3 weeks, then Phase 2, where power cleans replace the Workout B deadlift.",
  "progression": "Add weight every session while all work sets are completed: squat and deadlift +10 lb (~5 kg) for the first few sessions, then +5 lb (~2.5 kg); press, bench press and power clean +5 lb, later +2.5 lb or less.",
  "source": "Mark Rippetoe, 'The Starting Strength Program', startingstrength.com; Starting Strength: Basic Barbell Training, 3rd ed.",
  "sourceURL": "https://startingstrength.com/get-started/programs",
  "routines": [
    {
      "name": "Phase 1 · Workout A",
      "exercises": [
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 3, "reps": 5 }], "rest": 180 },
        { "exercise": "Overhead Press (Barbell)", "sets": [{ "count": 3, "reps": 5 }], "rest": 180 },
        { "exercise": "Deadlift (Barbell)", "sets": [{ "count": 1, "reps": 5 }] }
      ]
    },
    {
      "name": "Phase 1 · Workout B",
      "exercises": [
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 3, "reps": 5 }], "rest": 180 },
        { "exercise": "Bench Press (Barbell)", "sets": [{ "count": 3, "reps": 5 }], "rest": 180 },
        { "exercise": "Deadlift (Barbell)", "sets": [{ "count": 1, "reps": 5 }] }
      ]
    },
    {
      "name": "Phase 2 · Workout A",
      "exercises": [
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 3, "reps": 5 }], "rest": 300 },
        { "exercise": "Overhead Press (Barbell)", "sets": [{ "count": 3, "reps": 5 }], "rest": 300 },
        { "exercise": "Deadlift (Barbell)", "sets": [{ "count": 1, "reps": 5 }] }
      ]
    },
    {
      "name": "Phase 2 · Workout B",
      "exercises": [
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 3, "reps": 5 }], "rest": 300 },
        { "exercise": "Bench Press (Barbell)", "sets": [{ "count": 3, "reps": 5 }], "rest": 300 },
        { "exercise": "Power Clean", "sets": [{ "count": 5, "reps": 3 }] }
      ]
    }
  ]
}
```

---

## 2. StrongLifts 5×5 — Mehdi Hadim

- **Purpose / level / days / equipment:** beginner strength · beginner · 3 days/week · barbell
- **Schedule:** A and B alternate every session, most commonly Mon/Wed/Fri.
- **Progression:** add weight when all 5×5 was completed last time, otherwise repeat the weight.
- **Source:** https://stronglifts.com/stronglifts-5x5/workout-program/
  > "Workout A: Squat 5×5, Bench Press 5×5, Barbell Row 5×5 | Workout B: Squat 5×5, Overhead Press 5×5, Deadlift 1×5" (table) — "Alternate workouts A and B each time you lift"
  > "Rest about 3min between your five sets of five reps." (the easy / normal / hard table gives 1–2 / 3 / 5 min)
  > "Start by adding 5lb on the Squat, Bench, OHP and Row. Men can usually add 10lb on Deadlifts for a few weeks."
- **Disagreements / choices:** none. The 2007 table on stronglifts.com/stronglifts-5x5/history/ matches.
- **Library substitutions:** none. "Barbell Row" is `Bent Over Row (Barbell)`.
- **Trademark:** the site footer uses "Stronglifts™". In the US, "STRONGLIFTS" is live only for clothing (Serial 86655346, Hadim Mehdi, Belgium). The fitness-training-services registration (85603512) is cancelled. Non-US registers were not checked.

```json
{
  "id": "stronglifts-5x5",
  "name": "StrongLifts 5×5",
  "author": "Mehdi Hadim",
  "goal": "strength",
  "level": "beginner",
  "equipment": "barbell",
  "daysPerWeek": 3,
  "summary": "Two alternating full-body barbell workouts built on five sets of five. Starts light and adds weight almost every session; made for new or returning lifters.",
  "schedule": "Alternate Workout A and Workout B three times a week with a rest day between sessions (most people train Mon/Wed/Fri).",
  "progression": "If you completed all sets last time, add 5 lb (2.5 kg) on squat, bench, overhead press and row; men can add 10 lb (5 kg) on the deadlift for a few weeks. If you missed reps, repeat the weight.",
  "source": "Mehdi Hadim, 'Stronglifts 5×5 Workout Program: Quick Start Guide', stronglifts.com",
  "sourceURL": "https://stronglifts.com/stronglifts-5x5/workout-program/",
  "routines": [
    {
      "name": "Workout A",
      "exercises": [
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 5, "reps": 5 }], "rest": 180 },
        { "exercise": "Bench Press (Barbell)", "sets": [{ "count": 5, "reps": 5 }], "rest": 180 },
        { "exercise": "Bent Over Row (Barbell)", "sets": [{ "count": 5, "reps": 5 }], "rest": 180 }
      ]
    },
    {
      "name": "Workout B",
      "exercises": [
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 5, "reps": 5 }], "rest": 180 },
        { "exercise": "Overhead Press (Barbell)", "sets": [{ "count": 5, "reps": 5 }], "rest": 180 },
        { "exercise": "Deadlift (Barbell)", "sets": [{ "count": 1, "reps": 5 }] }
      ]
    }
  ]
}
```

---

## 3. Texas Method — Mark Rippetoe & Glenn Pendlay

- **Purpose / level / days / equipment:** powerlifting-style strength · intermediate · 3 days/week · barbell (plus a chin-up bar and a back-extension bench)
- **Schedule:** Monday is volume, Wednesday is recovery, Friday is intensity. Bench press and press swap roles each week, so there are two week templates (A and B).
- **Progression:** progress week to week. Friday's set of 5 is a new 5RM (or within about 2%). Monday's 5×5 uses about 90% of that 5RM.
- **Source:** Mark Rippetoe, "The Texas Method", https://startingstrength.com/article/programming/the_texas_method (2013, first published on T-Nation in 2010). Read via Wayback snapshot `20260128214011`.
  > "…a volume day for the major lifts on Monday, a lighter recovery/variety day on Wednesday, and a high-intensity day on Friday"
  > "if your 5 rep max squat is 345, then 315 x 5 x 5 would be Monday's squat workout. The bench press and the press … alternate every other Monday for 5 x 5 with about 90% of 5RM."
  > "…just one heavy set of five deadlifts on Monday"
  > "Squats are 80% of Monday's work weight for 2 sets of 5 … if presses were 5 x 5 on Monday, benches are done Wednesday with 3 sets of a little lighter weight … I like 3 sets to failure for chins, with 5 minutes between sets, and 5 sets of 10 back extensions or glute/ham raises"
  > "Friday is intensity day. It focuses the tonnage from Monday into a new 5RM … do power cleans for 5 sets of 3 reps across, or power snatches for 6 doubles."
- **Rest:** Monday's weight should allow all 25 reps "without more than 8-10 minutes rest between sets". That exceeds the app's 300 s cap, so the main lifts have no rest value. Chins are 300.
- **Disagreements / choices:** attribution. Rippetoe's article says "we" and traces the idea to Doug Hepburn via Bill Starr. StrongLifts' history page credits Glenn Pendlay (Wichita Falls). The author field lists both names.
- **Library substitutions:** none. Back extension is `Back Extension (Hyperextension)`; `Glute Ham Raise` is the alternative.
- **Trademark:** no US mark found for "Texas Method".

```json
{
  "id": "texas-method",
  "name": "Texas Method",
  "author": "Mark Rippetoe & Glenn Pendlay",
  "goal": "strength",
  "level": "intermediate",
  "equipment": "barbell",
  "daysPerWeek": 3,
  "summary": "The classic next step after a novice linear progression: a high-volume Monday, a light Wednesday and a heavy Friday, with progress made week to week instead of session to session.",
  "schedule": "Mon volume, Wed recovery, Fri intensity. Bench press and press swap roles every week: run Week A, then Week B, and repeat.",
  "progression": "Aim for a new 5RM on Friday every week (or within ~2%). Monday's 5×5 uses about 90% of that 5RM; Wednesday's squat is 80% of Monday's weight.",
  "source": "Mark Rippetoe, 'The Texas Method', startingstrength.com (2013; originally T-Nation, 2010)",
  "sourceURL": "https://startingstrength.com/article/programming/the_texas_method",
  "routines": [
    {
      "name": "Week A · Monday (Volume)",
      "exercises": [
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 5, "reps": 5 }], "notes": "≈90% of 5RM" },
        { "exercise": "Bench Press (Barbell)", "sets": [{ "count": 5, "reps": 5 }], "notes": "≈90% of 5RM" },
        { "exercise": "Deadlift (Barbell)", "sets": [{ "count": 1, "reps": 5 }], "notes": "One heavy set" }
      ]
    },
    {
      "name": "Week A · Wednesday (Recovery)",
      "exercises": [
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 2, "reps": 5 }], "notes": "80% of Monday's weight" },
        { "exercise": "Overhead Press (Barbell)", "sets": [{ "count": 3, "reps": 5 }], "notes": "Light day" },
        { "exercise": "Chin Up", "sets": [{ "count": 3, "kind": "failure" }], "rest": 300 },
        { "exercise": "Back Extension (Hyperextension)", "sets": [{ "count": 5, "reps": 10 }], "notes": "Or glute-ham raise; optional" }
      ]
    },
    {
      "name": "Week A · Friday (Intensity)",
      "exercises": [
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 1, "reps": 5 }], "notes": "New 5RM" },
        { "exercise": "Bench Press (Barbell)", "sets": [{ "count": 1, "reps": 5 }], "notes": "New 5RM" },
        { "exercise": "Power Clean", "sets": [{ "count": 5, "reps": 3 }], "notes": "Or power snatch 6×2" }
      ]
    },
    {
      "name": "Week B · Monday (Volume)",
      "exercises": [
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 5, "reps": 5 }], "notes": "≈90% of 5RM" },
        { "exercise": "Overhead Press (Barbell)", "sets": [{ "count": 5, "reps": 5 }], "notes": "≈90% of 5RM" },
        { "exercise": "Deadlift (Barbell)", "sets": [{ "count": 1, "reps": 5 }], "notes": "One heavy set" }
      ]
    },
    {
      "name": "Week B · Wednesday (Recovery)",
      "exercises": [
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 2, "reps": 5 }], "notes": "80% of Monday's weight" },
        { "exercise": "Bench Press (Barbell)", "sets": [{ "count": 3, "reps": 5 }], "notes": "A little lighter than your last bench 5×5" },
        { "exercise": "Chin Up", "sets": [{ "count": 3, "kind": "failure" }], "rest": 300 },
        { "exercise": "Back Extension (Hyperextension)", "sets": [{ "count": 5, "reps": 10 }], "notes": "Or glute-ham raise; optional" }
      ]
    },
    {
      "name": "Week B · Friday (Intensity)",
      "exercises": [
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 1, "reps": 5 }], "notes": "New 5RM" },
        { "exercise": "Overhead Press (Barbell)", "sets": [{ "count": 1, "reps": 5 }], "notes": "New 5RM" },
        { "exercise": "Power Clean", "sets": [{ "count": 5, "reps": 3 }], "notes": "Or power snatch 6×2" }
      ]
    }
  ]
}
```

---

## 4. 5/3/1 Boring But Big — Jim Wendler

- **Purpose / level / days / equipment:** powerlifting-style strength plus size · intermediate · 4 days/week · barbell (plus a chin-up bar and dumbbells)
- **Schedule:** Press, Deadlift, Bench and Squat days. Cycles last 4 weeks.
- **Main sets (all percentages of the Training Max, which is 90% of 1RM):**

  | Set | Week 1 | Week 2 | Week 3 | Week 4 (deload) |
  |---|---|---|---|---|
  | 1 | 65% × 5 | 70% × 3 | 75% × 5 | 40% × 5 |
  | 2 | 75% × 5 | 80% × 3 | 85% × 3 | 50% × 5 |
  | 3 | 85% × 5+ | 90% × 3+ | 95% × 1+ | 60% × 5 |

- **Progression:** after each cycle, add 5 lb to the press and bench training max and 10 lb to the squat and deadlift training max.
- **Sources:**
  - Main sets, rest and progression: Jim Wendler, "5/3/1: How to Build Pure Strength", T-Nation, 7 July 2009. https://t-nation.com/t/5-3-1-how-to-build-pure-strength/281694 blocks bots, so it was read via Wayback `20240621102835`.
    > "Week 1 … 65% x 5 / 75% x 5 / 85% x 5+ … Week 2 70% x 3 / 80% x 3 / 90% x 3+ … Week 3 75% x 5 / 85% x 3 / 95% x 1+ … Week 4 40% x 5 / 50% x 5 / 60% x 5" — "The calculations are based on 90% of it."
    > "After you finish the first cycle, you add five pounds to your 1RM calculations for the two upper-body lifts and 10 pounds to your 1RM for the squat and deadlift."
    > "In all workouts, rest 3 to 5 minutes between sets of the core lift, and 1 to 2 minutes between sets of the assistance exercises." (core lift 240, 5×10 and assistance 90)
  - BBB template: Jim Wendler, "Boring But Big", https://www.jimwendler.com/blogs/jimwendler-com/101077382-boring-but-big
    > "Day One: Press – 5/3/1, Press – 5 sets of 10 reps, Lat work – 5 sets of 10 reps; Day Two: Deadlift – 5/3/1, Deadlift – 5 sets of 10 reps, Abs – 5 sets; Day Three: Bench Press – 5/3/1, Bench Press – 5 sets of 10 reps, Lat work – 5 sets of 10 reps; Day Four: Squat – 5/3/1, Squat – 5 sets of 10 reps, Abs – 5 sets"
    > "The general rule of thumb is to use 50-60% of your Training Max for the 5 sets of 10 reps … For people completely new to this … Cycle One: 5 sets of 10 @ 30% … Cycle Two: … 45% … Cycle Three: … 60%"
- **Disagreements / choices:**
  - Two Wendler-written BBB versions disagree on the 5×10 loads.
    - The "BBB" article uses 50–60% of TM.
    - The "BBB 3-Month Challenge" (jimwendler.com) uses 50% / 60% / 70% by month, drops the "+" sets, and uses 25–50 reps of rows/chins, face pulls and abs instead of 5×10 lat work.
    - I encoded the BBB article's "Example 1" (same lift for the 5×10).
  - The article only says "Lat work" and "Abs – 5 sets". The concrete exercises come from Wendler's own 2009 T-Nation template: Chin-Up 5×10, Dumbbell Row 5×10, Hanging Leg Raise 5×15.
  - The JSON sets show week 1. `notes` carry the other weeks.
- **Library substitutions:** none.
- **Trademark:** "JIM WENDLER 5/3/1" is registered in the US to Jim Wendler LLC (OH) and is live (Serial 90752575, e-books and printed matter). An earlier "JIM WENDLER 5/3/1" filing for mobile app software (85738319) is cancelled. No mark was found for "Boring But Big".

```json
{
  "id": "wendler-531-bbb",
  "name": "5/3/1 Boring But Big",
  "author": "Jim Wendler",
  "goal": "strength",
  "level": "intermediate",
  "equipment": "barbell",
  "daysPerWeek": 4,
  "summary": "Wendler's 5/3/1 strength waves on the four big lifts, followed by five sets of ten of the same lift for size. Slow, steady progress for lifters past the beginner stage.",
  "schedule": "Four days a week (e.g. Mon/Tue/Thu/Fri): Press, Deadlift, Bench, Squat. Each 4-week cycle: week 1 fives, week 2 threes, week 3 5/3/1, week 4 deload.",
  "progression": "Training max = 90% of 1RM. After each 4-week cycle add 5 lb (~2.5 kg) to the press and bench training max and 10 lb (~5 kg) to the squat and deadlift training max.",
  "source": "Jim Wendler, '5/3/1: How to Build Pure Strength' (T-Nation, 2009) and 'Boring But Big' (jimwendler.com)",
  "sourceURL": "https://www.jimwendler.com/blogs/jimwendler-com/101077382-boring-but-big",
  "routines": [
    {
      "name": "Day 1 · Press",
      "exercises": [
        { "exercise": "Overhead Press (Barbell)", "sets": [{ "count": 2, "reps": 5 }, { "count": 1, "reps": 5, "kind": "failure" }], "rest": 240, "notes": "% of TM. Wk1 65/75/85 ×5,5,5+ · Wk2 70/80/90 ×3,3,3+ · Wk3 75/85/95 ×5,3,1+ · Wk4 40/50/60 ×5" },
        { "exercise": "Overhead Press (Barbell)", "sets": [{ "count": 5, "reps": 10 }], "rest": 90, "notes": "BBB 5×10 at 50–60% TM (new: 30%→45%→60% over 3 cycles)" },
        { "exercise": "Chin Up", "sets": [{ "count": 5, "reps": 10 }], "rest": 90, "notes": "Lat work" }
      ]
    },
    {
      "name": "Day 2 · Deadlift",
      "exercises": [
        { "exercise": "Deadlift (Barbell)", "sets": [{ "count": 2, "reps": 5 }, { "count": 1, "reps": 5, "kind": "failure" }], "rest": 240, "notes": "% of TM. Wk1 65/75/85 ×5,5,5+ · Wk2 70/80/90 ×3,3,3+ · Wk3 75/85/95 ×5,3,1+ · Wk4 40/50/60 ×5" },
        { "exercise": "Deadlift (Barbell)", "sets": [{ "count": 5, "reps": 10 }], "rest": 90, "notes": "BBB 5×10 at 50–60% TM (new: 30%→45%→60% over 3 cycles)" },
        { "exercise": "Hanging Leg Raise", "sets": [{ "count": 5, "reps": 15 }], "rest": 90, "notes": "Abs" }
      ]
    },
    {
      "name": "Day 3 · Bench",
      "exercises": [
        { "exercise": "Bench Press (Barbell)", "sets": [{ "count": 2, "reps": 5 }, { "count": 1, "reps": 5, "kind": "failure" }], "rest": 240, "notes": "% of TM. Wk1 65/75/85 ×5,5,5+ · Wk2 70/80/90 ×3,3,3+ · Wk3 75/85/95 ×5,3,1+ · Wk4 40/50/60 ×5" },
        { "exercise": "Bench Press (Barbell)", "sets": [{ "count": 5, "reps": 10 }], "rest": 90, "notes": "BBB 5×10 at 50–60% TM (new: 30%→45%→60% over 3 cycles)" },
        { "exercise": "Dumbbell Row", "sets": [{ "count": 5, "reps": 10 }], "rest": 90, "notes": "Lat work" }
      ]
    },
    {
      "name": "Day 4 · Squat",
      "exercises": [
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 2, "reps": 5 }, { "count": 1, "reps": 5, "kind": "failure" }], "rest": 240, "notes": "% of TM. Wk1 65/75/85 ×5,5,5+ · Wk2 70/80/90 ×3,3,3+ · Wk3 75/85/95 ×5,3,1+ · Wk4 40/50/60 ×5" },
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 5, "reps": 10 }], "rest": 90, "notes": "BBB 5×10 at 50–60% TM (new: 30%→45%→60% over 3 cycles)" },
        { "exercise": "Hanging Leg Raise", "sets": [{ "count": 5, "reps": 15 }], "rest": 90, "notes": "Abs" }
      ]
    }
  ]
}
```

---

## 5. Reg Park 5×5 — Reg Park (phases 1–3)

- **Purpose / level / days / equipment:** strength plus size (old-school bodybuilding) · beginner · 3 days/week · barbell (plus a hyperextension bench)
- **Schedule:** one workout repeated three times a week. Each phase lasts about three months.
- **Progression:** each 5×5 is two ramping warm-up sets plus three work sets at one weight. When all 3×5 are done, add 5–10 lb to every set. Park was against training to failure.
- **Source:** **second-hand only.** The primary source is Reg Park's booklet *Strength & Bulk Training for Weight Lifters and Body Builders* (1958 or 1960; the secondaries disagree), which is not online.
  - Best available: "Reg Park's 5x5 Program", T-Nation staff, 2008. https://archive.t-nation.com/training/reg-parks-5x5-program/
    > "Phase One: 45-Degree Back Extension 3×10 | Back Squat 5×5 | Bench Press 5×5 | Deadlift 5×5 — Rest 3-5 minutes between the last 3 sets of each exercise. Train three days per week for three months."
    > "As Park explained it, 5x5 includes two progressively heavier warm-up sets and three sets at the same weight … When you can complete the last 3x5 at a given weight, increase the weight on all five sets 5-10 pounds."
  - Corroborated by Mehdi Hadim, who owns the book and cites page numbers: https://stronglifts.com/stronglifts-5x5/history/ — "Hyperextension 3×10 / Squat 5×5 / Bench Press 5×5 / Deadlift 5×5 … Between sets Reg Park recommended 3-5min rest."
- **Disagreements / choices:**
  - Book year: 1958 per StrongLifts, 1960 per T-Nation.
  - Increment: "+5 lb" per StrongLifts, "+5–10 lb" per T-Nation.
  - Rest: Phase 1 uses 240 (from 3–5 min). Phases 2 and 3 use 120 ("Rest 2 minutes between sets").
  - Phases 2 and 3 come from T-Nation only.
- **Library substitutions:**
  - "High pull" → `Deadlift High Pull`.
  - "Behind-the-neck press or one-arm dumbbell press" → `Overhead Press (Dumbbell)`. The library has neither a behind-the-neck press nor a one-arm press.
  - "Lying triceps extension" → `Skullcrusher (Barbell)`.
- **Trademark:** no US mark found for "Reg Park".

```json
{
  "id": "reg-park-5x5",
  "name": "Reg Park 5×5",
  "author": "Reg Park",
  "goal": "muscle",
  "level": "beginner",
  "equipment": "barbell",
  "daysPerWeek": 3,
  "summary": "The original 5×5 'strength and bulk' course from the three-time Mr. Universe who inspired Arnold: heavy basics three times a week, adding exercises every three months.",
  "schedule": "Same workout three days a week (e.g. Mon/Wed/Fri). Phase 1 for about three months, then Phase 2 for three months, then Phase 3.",
  "progression": "Each 5×5 = two ramping warm-up sets plus three work sets at one weight. When all three work sets hit 5 reps, add 5–10 lb (2.5–5 kg) to every set. Don't train to failure.",
  "source": "Reg Park, Strength & Bulk Training for Weight Lifters and Body Builders (as reproduced by T-Nation, 2008, and Stronglifts)",
  "sourceURL": "https://archive.t-nation.com/training/reg-parks-5x5-program/",
  "routines": [
    {
      "name": "Phase 1",
      "exercises": [
        { "exercise": "Back Extension (Hyperextension)", "sets": [{ "count": 3, "reps": 10 }], "notes": "45° back extension; add weight once easy" },
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 2, "reps": 5, "kind": "warmup" }, { "count": 3, "reps": 5 }], "rest": 240 },
        { "exercise": "Bench Press (Barbell)", "sets": [{ "count": 2, "reps": 5, "kind": "warmup" }, { "count": 3, "reps": 5 }], "rest": 240 },
        { "exercise": "Deadlift (Barbell)", "sets": [{ "count": 2, "reps": 5, "kind": "warmup" }, { "count": 3, "reps": 5 }], "rest": 240 }
      ]
    },
    {
      "name": "Phase 2",
      "exercises": [
        { "exercise": "Back Extension (Hyperextension)", "sets": [{ "count": 3, "reps": 10 }], "rest": 120, "notes": "3–4 sets" },
        { "exercise": "Front Squat", "sets": [{ "count": 2, "reps": 5, "kind": "warmup" }, { "count": 3, "reps": 5 }], "rest": 120 },
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 2, "reps": 5, "kind": "warmup" }, { "count": 3, "reps": 5 }], "rest": 120 },
        { "exercise": "Bench Press (Barbell)", "sets": [{ "count": 2, "reps": 5, "kind": "warmup" }, { "count": 3, "reps": 5 }], "rest": 120 },
        { "exercise": "Overhead Press (Barbell)", "sets": [{ "count": 2, "reps": 5, "kind": "warmup" }, { "count": 3, "reps": 5 }], "rest": 120 },
        { "exercise": "Deadlift High Pull", "sets": [{ "count": 2, "reps": 5, "kind": "warmup" }, { "count": 3, "reps": 5 }], "rest": 120, "notes": "High pull" },
        { "exercise": "Deadlift (Barbell)", "sets": [{ "count": 2, "reps": 5, "kind": "warmup" }, { "count": 3, "reps": 5 }], "rest": 120 },
        { "exercise": "Standing Calf Raise (Barbell)", "sets": [{ "count": 5, "reps": 25 }], "rest": 120 }
      ]
    },
    {
      "name": "Phase 3",
      "exercises": [
        { "exercise": "Back Extension (Hyperextension)", "sets": [{ "count": 4, "reps": 10 }], "rest": 120 },
        { "exercise": "Front Squat", "sets": [{ "count": 2, "reps": 5, "kind": "warmup" }, { "count": 3, "reps": 5 }], "rest": 120 },
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 2, "reps": 5, "kind": "warmup" }, { "count": 3, "reps": 5 }], "rest": 120 },
        { "exercise": "Overhead Press (Barbell)", "sets": [{ "count": 2, "reps": 5, "kind": "warmup" }, { "count": 3, "reps": 5 }], "rest": 120 },
        { "exercise": "Bench Press (Barbell)", "sets": [{ "count": 2, "reps": 5, "kind": "warmup" }, { "count": 3, "reps": 5 }], "rest": 120 },
        { "exercise": "Bent Over Row (Barbell)", "sets": [{ "count": 2, "reps": 5, "kind": "warmup" }, { "count": 3, "reps": 5 }], "rest": 120 },
        { "exercise": "Deadlift (Barbell)", "sets": [{ "count": 2, "reps": 5, "kind": "warmup" }, { "count": 3, "reps": 5 }], "rest": 120 },
        { "exercise": "Overhead Press (Dumbbell)", "sets": [{ "count": 2, "reps": 5, "kind": "warmup" }, { "count": 3, "reps": 5 }], "rest": 120, "notes": "One arm at a time, or behind-the-neck press" },
        { "exercise": "Bicep Curl (Barbell)", "sets": [{ "count": 2, "reps": 5, "kind": "warmup" }, { "count": 3, "reps": 5 }], "rest": 120 },
        { "exercise": "Skullcrusher (Barbell)", "sets": [{ "count": 5, "reps": 8 }], "rest": 120, "notes": "Lying triceps extension" },
        { "exercise": "Standing Calf Raise (Barbell)", "sets": [{ "count": 5, "reps": 25 }], "rest": 120 }
      ]
    }
  ]
}
```

---

## 6. PHAT (Power Hypertrophy Adaptive Training) — Layne Norton

- **Purpose / level / days / equipment:** strength plus size (powerbuilding) · intermediate · 5 days/week · full gym
- **Schedule:** Day 1 upper power, Day 2 lower power, Day 3 rest, Day 4 back and shoulders hypertrophy, Day 5 lower hypertrophy, Day 6 chest and arms hypertrophy, Day 7 rest.
- **Progression and rules:** see the quotes.
- **Sources:**
  - Layne Norton, https://biolayne.com/articles/training/phat-power-hypertrophy-adaptive-training/ (his own site, 30 May 2016).
  - Identical routine in his 2011 SimplyShredded article, https://simplyshredded.com/mega-feature-layne-norton-training-series-full-powerhypertrophy-routine-updated-2011.html. The two routine sections were diffed and are the same apart from whitespace.
  > "Day 1: Upper Body Power … Day 2: Lower Body Power … Day 3: Rest … Day 4: Back and Shoulders Hypertrophy … Day 5: Lower Body Hypertrophy … Day 6: Chest and Arms Hypertrophy … Day 7: Rest"
  > Power days: "…stay in the 3-5 rep range … If that means you need to take 5-6 minutes between sets then so be it." → 300
  > Speed work: "6 sets of 3 reps with 65-70% of normal 3-5 rep max … Rest no longer than 90 seconds in between each of the speed sets." → 90
  > Hypertrophy: "Your rep range should be 8-20 and keep your rest periods to 1-2 minutes between sets." → 90
  > "For the first 2-4 weeks you should NOT train to failure at all … I only recommend going to absolute failure on the last 1-2 sets of each exercise once you have adapted" — "you may want to cut out an assistance/auxiliary exercise on each day to start"
- **Disagreements / choices:**
  - Where Norton offers two options, the JSON takes the first one listed. The alternatives are in `notes`.
  - Power-day assistance work has no stated rest, so none is set.
- **Library substitutions:**
  - Rack chins → `Inverted Row`. The library has no rack chin; this changes the exercise the most.
  - Cambered-bar curl → `EZ Bar Biceps Curl`.
  - Donkey calf raise → `Calf Press (Machine)` (same hip-flexed, straight-knee position).
  - Hammer Strength chest press → `Iso-Lateral Chest Press (Machine)`.
  - Incline cable fly → `Low Cable Fly Crossovers`.
  - Seated cambered-bar triceps extension → `Triceps Extension (Barbell)`, which is the library's seated overhead version.
- **Trademark:** no Norton-owned US mark found for "PHAT". Unrelated "PHAT" marks exist in other classes.

```json
{
  "id": "phat",
  "name": "PHAT (Power Hypertrophy Adaptive Training)",
  "author": "Layne Norton",
  "goal": "muscle",
  "level": "intermediate",
  "equipment": "fullGym",
  "daysPerWeek": 5,
  "summary": "A five-day powerbuilding split: two heavy upper/lower power days, then three bodybuilding days that open with speed work. Each muscle is hit twice a week with both heavy and moderate-rep work.",
  "schedule": "Day 1 Upper Power, Day 2 Lower Power, Day 3 rest, Day 4 Back & Shoulders Hypertrophy, Day 5 Lower Hypertrophy, Day 6 Chest & Arms Hypertrophy, Day 7 rest.",
  "progression": "Move more weight on the power days (3–5 reps); rotate power movements every 2–3 weeks. No sets to failure for the first 2–4 weeks, then only the last 1–2 sets of an exercise. Deload at 60–70% of normal weights every 6–12 weeks as needed.",
  "source": "Layne Norton, 'PHAT: Power Hypertrophy Adaptive Training', biolayne.com (2016; first published on SimplyShredded, 2011)",
  "sourceURL": "https://biolayne.com/articles/training/phat-power-hypertrophy-adaptive-training/",
  "routines": [
    {
      "name": "Day 1 · Upper Body Power",
      "exercises": [
        { "exercise": "Bent Over Row (Barbell)", "sets": [{ "count": 3, "reps": 3, "repsMax": 5 }], "rest": 300, "notes": "Or Pendlay row" },
        { "exercise": "Pull Up (Weighted)", "sets": [{ "count": 2, "reps": 6, "repsMax": 10 }] },
        { "exercise": "Inverted Row", "sets": [{ "count": 2, "reps": 6, "repsMax": 10 }], "notes": "Stand-in for rack chins" },
        { "exercise": "Bench Press (Dumbbell)", "sets": [{ "count": 3, "reps": 3, "repsMax": 5 }], "rest": 300 },
        { "exercise": "Chest Dip (Weighted)", "sets": [{ "count": 2, "reps": 6, "repsMax": 10 }] },
        { "exercise": "Seated Overhead Press (Dumbbell)", "sets": [{ "count": 3, "reps": 6, "repsMax": 10 }] },
        { "exercise": "EZ Bar Biceps Curl", "sets": [{ "count": 3, "reps": 6, "repsMax": 10 }], "notes": "Cambered-bar curl" },
        { "exercise": "Skullcrusher (Barbell)", "sets": [{ "count": 3, "reps": 6, "repsMax": 10 }] }
      ]
    },
    {
      "name": "Day 2 · Lower Body Power",
      "exercises": [
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 3, "reps": 3, "repsMax": 5 }], "rest": 300 },
        { "exercise": "Hack Squat (Machine)", "sets": [{ "count": 2, "reps": 6, "repsMax": 10 }] },
        { "exercise": "Leg Extension (Machine)", "sets": [{ "count": 2, "reps": 6, "repsMax": 10 }] },
        { "exercise": "Straight Leg Deadlift", "sets": [{ "count": 3, "reps": 5, "repsMax": 8 }] },
        { "exercise": "Lying Leg Curl (Machine)", "sets": [{ "count": 2, "reps": 6, "repsMax": 10 }], "notes": "Or glute-ham raise" },
        { "exercise": "Standing Calf Raise (Machine)", "sets": [{ "count": 3, "reps": 6, "repsMax": 10 }] },
        { "exercise": "Seated Calf Raise", "sets": [{ "count": 2, "reps": 6, "repsMax": 10 }] }
      ]
    },
    {
      "name": "Day 4 · Back & Shoulders Hypertrophy",
      "exercises": [
        { "exercise": "Bent Over Row (Barbell)", "sets": [{ "count": 6, "reps": 3 }], "rest": 90, "notes": "Speed work: 65–70% of your 3–5RM, explosive" },
        { "exercise": "Inverted Row", "sets": [{ "count": 3, "reps": 8, "repsMax": 12 }], "rest": 90, "notes": "Stand-in for rack chins" },
        { "exercise": "Seated Cable Row - V Grip (Cable)", "sets": [{ "count": 3, "reps": 8, "repsMax": 12 }], "rest": 90 },
        { "exercise": "Chest Supported Incline Row (Dumbbell)", "sets": [{ "count": 2, "reps": 12, "repsMax": 15 }], "rest": 90, "notes": "Or chest-supported shrugs" },
        { "exercise": "Lat Pulldown - Close Grip (Cable)", "sets": [{ "count": 2, "reps": 15, "repsMax": 20 }], "rest": 90 },
        { "exercise": "Seated Overhead Press (Dumbbell)", "sets": [{ "count": 3, "reps": 8, "repsMax": 12 }], "rest": 90 },
        { "exercise": "Upright Row (Barbell)", "sets": [{ "count": 2, "reps": 12, "repsMax": 15 }], "rest": 90 },
        { "exercise": "Lateral Raise (Dumbbell)", "sets": [{ "count": 3, "reps": 12, "repsMax": 20 }], "rest": 90, "notes": "Dumbbells or cables" }
      ]
    },
    {
      "name": "Day 5 · Lower Body Hypertrophy",
      "exercises": [
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 6, "reps": 3 }], "rest": 90, "notes": "Speed work: 65–70% of your 3–5RM, explosive" },
        { "exercise": "Hack Squat (Machine)", "sets": [{ "count": 3, "reps": 8, "repsMax": 12 }], "rest": 90 },
        { "exercise": "Leg Press (Machine)", "sets": [{ "count": 2, "reps": 12, "repsMax": 15 }], "rest": 90 },
        { "exercise": "Leg Extension (Machine)", "sets": [{ "count": 3, "reps": 15, "repsMax": 20 }], "rest": 90 },
        { "exercise": "Romanian Deadlift (Barbell)", "sets": [{ "count": 3, "reps": 8, "repsMax": 12 }], "rest": 90 },
        { "exercise": "Lying Leg Curl (Machine)", "sets": [{ "count": 2, "reps": 12, "repsMax": 15 }], "rest": 90 },
        { "exercise": "Seated Leg Curl (Machine)", "sets": [{ "count": 2, "reps": 15, "repsMax": 20 }], "rest": 90 },
        { "exercise": "Calf Press (Machine)", "sets": [{ "count": 4, "reps": 10, "repsMax": 15 }], "rest": 90, "notes": "Stand-in for donkey calf raises" },
        { "exercise": "Seated Calf Raise", "sets": [{ "count": 3, "reps": 15, "repsMax": 20 }], "rest": 90 }
      ]
    },
    {
      "name": "Day 6 · Chest & Arms Hypertrophy",
      "exercises": [
        { "exercise": "Bench Press (Dumbbell)", "sets": [{ "count": 6, "reps": 3 }], "rest": 90, "notes": "Speed work: 65–70% of your 3–5RM, explosive" },
        { "exercise": "Incline Bench Press (Dumbbell)", "sets": [{ "count": 3, "reps": 8, "repsMax": 12 }], "rest": 90 },
        { "exercise": "Iso-Lateral Chest Press (Machine)", "sets": [{ "count": 3, "reps": 12, "repsMax": 15 }], "rest": 90, "notes": "Hammer Strength chest press" },
        { "exercise": "Low Cable Fly Crossovers", "sets": [{ "count": 2, "reps": 15, "repsMax": 20 }], "rest": 90, "notes": "Stand-in for incline cable flyes" },
        { "exercise": "Preacher Curl (Barbell)", "sets": [{ "count": 3, "reps": 8, "repsMax": 12 }], "rest": 90, "notes": "Cambered (EZ) bar" },
        { "exercise": "Concentration Curl", "sets": [{ "count": 2, "reps": 12, "repsMax": 15 }], "rest": 90 },
        { "exercise": "Spider Curl (Dumbbell)", "sets": [{ "count": 2, "reps": 15, "repsMax": 20 }], "rest": 90 },
        { "exercise": "Triceps Extension (Barbell)", "sets": [{ "count": 3, "reps": 8, "repsMax": 12 }], "rest": 90, "notes": "Seated, cambered bar" },
        { "exercise": "Triceps Rope Pushdown", "sets": [{ "count": 2, "reps": 12, "repsMax": 15 }], "rest": 90 },
        { "exercise": "Triceps Kickback (Cable)", "sets": [{ "count": 2, "reps": 15, "repsMax": 20 }], "rest": 90 }
      ]
    }
  ]
}
```

---

## 7. The Golden Six — attributed to Arnold Schwarzenegger

- **Purpose / level / days / equipment:** bodybuilding / general size · beginner · 3 days/week · barbell (plus a chin-up bar)
- **Schedule:** the same workout three times a week on alternating days.
- **Progression:** not given by the source.
- **Source:** **second-hand only.** I found no Arnold-written or Arnold-official source for "the Golden Six". Best available: Bradley Joe Kelly, "Tip: Train With Arnold's Golden Six", T-Nation, 2016. https://archive.t-nation.com/training/tip-train-with-arnolds-golden-six/
  > "…he started his career on a full-body routine … The program was nicknamed 'The Golden Six' … Squat 4×10 | Wide-Grip Flat Bench Press 3×10 | Chin-Up 3×failure | Behind-the-Neck Overhead Press 4×10 | Barbell Curl 3×10 | Bent Knee Sit-Up 3-4×failure … it should be done three times a week on alternating days"
- **Disagreements / choices:**
  - Many aggregator sites list the same six lifts. Some swap the behind-the-neck press for a military press or the sit-ups for crunches.
  - The attribution to Arnold is folklore-level. **Recommendation: ship it only with author "Arnold Schwarzenegger (attributed)".**
- **Library substitutions:**
  - Behind-the-neck press → `Overhead Press (Barbell)`. The library has no behind-the-neck press.
  - Bent-knee sit-up → `Sit Up`.
- **Trademark:** no fitness-related US mark found for "Golden Six". Arnold's name and likeness raise a right-of-publicity issue; see section 8.

```json
{
  "id": "golden-six",
  "name": "The Golden Six",
  "author": "Arnold Schwarzenegger (attributed)",
  "goal": "muscle",
  "level": "beginner",
  "equipment": "barbell",
  "daysPerWeek": 3,
  "summary": "Six basic lifts, full body, three times a week — the routine Arnold reportedly started on. Short and simple, which suits beginners.",
  "schedule": "The same workout three times a week on alternating days (e.g. Mon/Wed/Fri).",
  "progression": "Not specified by the source; add weight once every set reaches its target reps.",
  "source": "Bradley Joe Kelly, 'Tip: Train With Arnold's Golden Six', T-Nation (2016) — second-hand; no Arnold-authored source found",
  "sourceURL": "https://archive.t-nation.com/training/tip-train-with-arnolds-golden-six/",
  "routines": [
    {
      "name": "Full Body",
      "exercises": [
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 4, "reps": 10 }] },
        { "exercise": "Bench Press - Wide Grip (Barbell)", "sets": [{ "count": 3, "reps": 10 }] },
        { "exercise": "Chin Up", "sets": [{ "count": 3, "kind": "failure" }] },
        { "exercise": "Overhead Press (Barbell)", "sets": [{ "count": 4, "reps": 10 }], "notes": "Original: behind-the-neck press" },
        { "exercise": "Bicep Curl (Barbell)", "sets": [{ "count": 3, "reps": 10 }] },
        { "exercise": "Sit Up", "sets": [{ "count": 3, "kind": "failure" }], "notes": "Bent-knee sit-ups, 3–4 sets" }
      ]
    }
  ]
}
```

---

## 8. Arnold Split (Blueprint to Mass, Phase 1) — Arnold Schwarzenegger

- **Version chosen:** the *Arnold Schwarzenegger Blueprint Trainer*, "Blueprint to Mass" Phase 1 (weeks 1–4), published on Bodybuilding.com in 2013–14. The *Encyclopedia of Modern Bodybuilding* version is book-only and was not checked.
- **Why this counts as official:** Arnold's company, Fitness Publications, Inc., filed "ARNOLD SCHWARZENEGGER BLUEPRINT TO MASS" with the USPTO (Serial 86197133). The article byline is "Bodybuilding.com", not Arnold.
- **Purpose / level / days / equipment:** classic bodybuilding · advanced · 6 days/week · full gym
- **Schedule:** Chest/Back/Abs, then Shoulders/Arms/Abs, then Legs. The cycle runs twice, then there is a rest day. Day 4 was checked and is identical to Day 1.
- **Source:** http://www.bodybuilding.com/fun/arnold-schwarzenegger-blueprint-trainer-day-1.html (plus `-day-2`, `-day-3`), read via Wayback snapshots 20140225135837, 20141227175230 and 20141229002719.
  > "Week 1, Day 1 - Chest & Back / Day 2 - Shoulders & Arms / Day 3 - Legs / Day 4 - Chest & Back / Day 5 - Shoulders & Arms / Day 6 - Legs / Day 7 - Rest"
  > "Follow rep ranges below unless listed otherwise. 30 reps is a warm-up set. Flat Barbell Bench Press 5 sets of 30, 12, 10, 8, 6 reps 45 seconds rest … Chin-Up (Wide-grip) 4 sets to failure … Hanging Leg Raise 5 sets of 25 reps"
  > "Clean and Press 5 sets of 5 reps 45 seconds rest … Decline Sit-up 5 sets of 25 reps"
  > "Barbell Squat 5 sets of 8-12 reps 45 seconds rest … Good Morning (only perform once per week) … Kneeling Cable Crunch 4 sets of 25 reps"
- **Progression:** the day pages give no week-to-week rule. The descending reps (12, 10, 8, 6) imply adding weight each set.
- **Disagreements / choices:**
  - Phase 2 (weeks 5–8) changes the schemes. For example, Day 29 has incline bench 10×4, flat bench 5×6, flyes plus cable crossover 5×12, 50 total wide-grip chins, and rows 8×8. Only Phase 1 is encoded.
  - Legs day has an optional max-effort squat every couple of weeks. It is mentioned in `notes` only.
- **Library substitutions:**
  - Wide-grip chin-up → `Wide Pull Up`.
  - Decline sit-up → `Decline Crunch`.
  - Wrist curls → `Seated Wrist Curl (Barbell)`.
  - Reverse wrist curls → `Reverse Wrist Curl (Dumbbell)`.
- **Trademark and publicity:**
  - The "…BLUEPRINT TO MASS" and "…BLUEPRINT" applications are dead or abandoned (86197133, 86197124).
  - The larger risk is Arnold's name and likeness (right of publicity). Don't imply endorsement. A descriptive name such as "Chest/Back · Shoulders/Arms · Legs (Arnold-style split)" is safer than using his name as a brand.

```json
{
  "id": "arnold-split-blueprint",
  "name": "Arnold Split (Blueprint to Mass)",
  "author": "Arnold Schwarzenegger",
  "goal": "muscle",
  "level": "advanced",
  "equipment": "fullGym",
  "daysPerWeek": 6,
  "summary": "Arnold's golden-era double-rotation split: chest/back, shoulders/arms, legs, each twice a week, high volume with pyramids and supersets. For experienced lifters with 1.5–2 hours to train.",
  "schedule": "Chest & Back, Shoulders & Arms, Legs, Chest & Back, Shoulders & Arms, Legs, rest. Weeks 1–4 of the 8-week Blueprint to Mass.",
  "progression": "Pyramid within each exercise: a 30-rep warm-up set, then 12, 10, 8 and 6 reps, going heavier as reps drop. Rest 45 seconds between sets.",
  "source": "Arnold Schwarzenegger Blueprint Trainer — Blueprint to Mass, Phase 1 (Bodybuilding.com, 2013–14)",
  "sourceURL": "https://web.archive.org/web/20140225135837/http://www.bodybuilding.com/fun/arnold-schwarzenegger-blueprint-trainer-day-1.html",
  "routines": [
    {
      "name": "Chest, Back & Abs",
      "exercises": [
        { "exercise": "Bench Press (Barbell)", "sets": [{ "count": 1, "reps": 30, "kind": "warmup" }, { "count": 1, "reps": 12 }, { "count": 1, "reps": 10 }, { "count": 1, "reps": 8 }, { "count": 1, "reps": 6 }], "rest": 45 },
        { "exercise": "Incline Bench Press (Barbell)", "sets": [{ "count": 1, "reps": 30, "kind": "warmup" }, { "count": 1, "reps": 12 }, { "count": 1, "reps": 10 }, { "count": 1, "reps": 8 }, { "count": 1, "reps": 6 }], "rest": 45, "notes": "Low-angle incline" },
        { "exercise": "Chest Fly (Dumbbell)", "sets": [{ "count": 1, "reps": 30, "kind": "warmup" }, { "count": 1, "reps": 12 }, { "count": 1, "reps": 10 }, { "count": 1, "reps": 8 }, { "count": 1, "reps": 6 }], "rest": 45, "notes": "Superset with the next exercise" },
        { "exercise": "Pullover (Dumbbell)", "sets": [{ "count": 1, "reps": 30, "kind": "warmup" }, { "count": 1, "reps": 12 }, { "count": 1, "reps": 10 }, { "count": 1, "reps": 8 }, { "count": 1, "reps": 6 }], "rest": 45 },
        { "exercise": "Wide Pull Up", "sets": [{ "count": 4, "kind": "failure" }], "rest": 45, "notes": "Wide-grip chin-up" },
        { "exercise": "Bent Over Row (Barbell)", "sets": [{ "count": 1, "reps": 30, "kind": "warmup" }, { "count": 1, "reps": 12 }, { "count": 1, "reps": 10 }, { "count": 1, "reps": 8 }, { "count": 1, "reps": 6 }], "rest": 45, "notes": "Superset with the next exercise" },
        { "exercise": "Bent Over Row (Dumbbell)", "sets": [{ "count": 1, "reps": 30, "kind": "warmup" }, { "count": 1, "reps": 12 }, { "count": 1, "reps": 10 }, { "count": 1, "reps": 8 }, { "count": 1, "reps": 6 }], "rest": 45 },
        { "exercise": "Hanging Leg Raise", "sets": [{ "count": 5, "reps": 25 }], "rest": 45 }
      ]
    },
    {
      "name": "Shoulders, Arms & Abs",
      "exercises": [
        { "exercise": "Clean and Press", "sets": [{ "count": 5, "reps": 5 }], "rest": 45 },
        { "exercise": "Overhead Press (Dumbbell)", "sets": [{ "count": 1, "reps": 30, "kind": "warmup" }, { "count": 1, "reps": 12 }, { "count": 1, "reps": 10 }, { "count": 1, "reps": 8 }, { "count": 1, "reps": 6 }], "rest": 45, "notes": "Standing. Superset with the next exercise" },
        { "exercise": "Front Raise (Dumbbell)", "sets": [{ "count": 1, "reps": 30, "kind": "warmup" }, { "count": 1, "reps": 12 }, { "count": 1, "reps": 10 }, { "count": 1, "reps": 8 }, { "count": 1, "reps": 6 }], "rest": 45 },
        { "exercise": "Lateral Raise (Dumbbell)", "sets": [{ "count": 1, "reps": 30, "kind": "warmup" }, { "count": 1, "reps": 12 }, { "count": 1, "reps": 10 }, { "count": 1, "reps": 8 }, { "count": 1, "reps": 6 }], "rest": 45, "notes": "Superset with the next exercise" },
        { "exercise": "Upright Row (Barbell)", "sets": [{ "count": 1, "reps": 30, "kind": "warmup" }, { "count": 1, "reps": 12 }, { "count": 1, "reps": 10 }, { "count": 1, "reps": 8 }, { "count": 1, "reps": 6 }], "rest": 45 },
        { "exercise": "Bicep Curl (Barbell)", "sets": [{ "count": 1, "reps": 30, "kind": "warmup" }, { "count": 1, "reps": 12 }, { "count": 1, "reps": 10 }, { "count": 1, "reps": 8 }, { "count": 1, "reps": 6 }], "rest": 45 },
        { "exercise": "Seated Incline Curl (Dumbbell)", "sets": [{ "count": 1, "reps": 30, "kind": "warmup" }, { "count": 1, "reps": 12 }, { "count": 1, "reps": 10 }, { "count": 1, "reps": 8 }, { "count": 1, "reps": 6 }], "rest": 45, "notes": "Superset with the next exercise" },
        { "exercise": "Concentration Curl", "sets": [{ "count": 1, "reps": 30, "kind": "warmup" }, { "count": 1, "reps": 12 }, { "count": 1, "reps": 10 }, { "count": 1, "reps": 8 }, { "count": 1, "reps": 6 }], "rest": 45 },
        { "exercise": "Bench Press - Close Grip (Barbell)", "sets": [{ "count": 1, "reps": 30, "kind": "warmup" }, { "count": 1, "reps": 12 }, { "count": 1, "reps": 10 }, { "count": 1, "reps": 8 }, { "count": 1, "reps": 6 }], "rest": 45 },
        { "exercise": "Skullcrusher (Barbell)", "sets": [{ "count": 1, "reps": 30, "kind": "warmup" }, { "count": 1, "reps": 12 }, { "count": 1, "reps": 10 }, { "count": 1, "reps": 8 }, { "count": 1, "reps": 6 }], "rest": 45, "notes": "Superset with the next exercise" },
        { "exercise": "Single Arm Tricep Extension (Dumbbell)", "sets": [{ "count": 1, "reps": 30, "kind": "warmup" }, { "count": 1, "reps": 12 }, { "count": 1, "reps": 10 }, { "count": 1, "reps": 8 }, { "count": 1, "reps": 6 }], "rest": 45 },
        { "exercise": "Seated Wrist Curl (Barbell)", "sets": [{ "count": 1, "reps": 30, "kind": "warmup" }, { "count": 1, "reps": 12 }, { "count": 1, "reps": 10 }, { "count": 1, "reps": 8 }, { "count": 1, "reps": 6 }], "rest": 45, "notes": "Superset with the next exercise" },
        { "exercise": "Reverse Wrist Curl (Dumbbell)", "sets": [{ "count": 1, "reps": 30, "kind": "warmup" }, { "count": 1, "reps": 12 }, { "count": 1, "reps": 10 }, { "count": 1, "reps": 8 }, { "count": 1, "reps": 6 }], "rest": 45 },
        { "exercise": "Decline Crunch", "sets": [{ "count": 5, "reps": 25 }], "rest": 45, "notes": "Decline sit-up in the original" }
      ]
    },
    {
      "name": "Legs",
      "exercises": [
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 5, "reps": 8, "repsMax": 12 }], "rest": 45, "notes": "Optional max-effort squat every couple of weeks" },
        { "exercise": "Straight Leg Deadlift", "sets": [{ "count": 5, "reps": 8, "repsMax": 12 }], "rest": 45 },
        { "exercise": "Good Morning (Barbell)", "sets": [{ "count": 5, "reps": 8, "repsMax": 12 }], "rest": 45, "notes": "Only once per week" },
        { "exercise": "Lunge (Barbell)", "sets": [{ "count": 5, "reps": 8, "repsMax": 12 }], "rest": 45 },
        { "exercise": "Leg Extension (Machine)", "sets": [{ "count": 5, "reps": 8, "repsMax": 12 }], "rest": 45, "notes": "Superset with the next exercise" },
        { "exercise": "Seated Leg Curl (Machine)", "sets": [{ "count": 5, "reps": 8, "repsMax": 12 }], "rest": 45 },
        { "exercise": "Standing Calf Raise (Machine)", "sets": [{ "count": 5, "reps": 8, "repsMax": 12 }], "rest": 45, "notes": "Superset with the next exercise" },
        { "exercise": "Seated Calf Raise", "sets": [{ "count": 5, "reps": 8, "repsMax": 12 }], "rest": 45 },
        { "exercise": "Cable Crunch", "sets": [{ "count": 4, "reps": 25 }], "rest": 45, "notes": "Kneeling cable crunch" }
      ]
    }
  ]
}
```

---

## 9. German Volume Training — Charles Poliquin

- **Purpose / level / days / equipment:** hypertrophy · intermediate (Poliquin calls it "Beginner/Intermediate") · 3 sessions per 5-day cycle (about 4 a week) · full gym
- **Schedule:** Day 1 chest and back, Day 2 legs and abs, Day 3 off, Day 4 arms and shoulders, Day 5 off. Run six cycles, then a 3-week block of 6–8 reps, then GVT Phase 2 (10×6). Phase 2 is not encoded.
- **Source:** Charles Poliquin, "German Volume Training", Poliquin Group, 6 August 2010. http://www.poliquingroup.com/ArticlesMultimedia/Articles/Article/441/German_Volume_Training.aspx — the site is gone, so it was read via Wayback `20130927092047`.
  > "A-1 Decline Dumbbell Presses, Semi-Supinated Grip (palms facing each other) 10 | 10 | 40X0 | 90 sec — A-2 Chin-Ups (palms facing you) 10 | 10 | 40X0 | 90 sec — B-1 Incline Dumbbell Flyes 3 | 10-12 | 3020 | 60 sec — B-2 One-Arm Dumbbell Rows 3 | 10-12 | 3020 | 60 sec"
  > "A-1 Back Squats 10 | 10 | 4020 … A-2 Lying Leg Curls Feet Outward 10 | 10 | 40X0 … B-1 Low-Cable Pull-Ins 3 | 15-20 | 2020 | 60 sec … B-2 Seated Calf Raises 3 | 15-20"
  > "A-1 Parallel Bar Dips 10 | 10 | 40X0 … A-2 Incline Hammer Curls 10 | 10 | 40X0 … B-1 Bent-Over Dumbbell Lateral Raises 3 | 10-12 | 20X0 … B-2 Seated Dumbbell Lateral Raises 3 | 10-12 | 20X0"
  > "Notes: Rest 90 seconds between each 'A' exercise and each superset; rest 60 seconds between each 'B' exercise and each superset."
  > "…begin with a weight you could lift for 20 reps to failure … 60 percent of their 1RM … Once you're able to do 10 sets of 10 with constant rest intervals, increase the weight on the bar by 4 to 5 percent"
- **Disagreements / choices:**
  - A 2021 Bodybuilding.com reprint under Poliquin's byline differs (https://shop.bodybuilding.com/blogs/training/german-volume-training-plans-the-10-sets-method):
    - different exercises (barbell bench plus barbell row, squat plus leg curl; arms day uses a 10×6 close-grip Smith bench and barbell curl)
    - a "4-0-2" tempo
    - no A1/A2 pairing
  - I used the Poliquin Group original, which has the A1/A2 supersets requested.
- **Library substitutions:**
  - Low-cable pull-ins → `Reverse Crunch` (loses the cable resistance).
  - Parallel-bar dips → `Triceps Dip`.
  - Bent-over dumbbell lateral raise → `Rear Delt Reverse Fly (Dumbbell)`.
  - Incline hammer curl → `Seated Incline Hammer Curl (Dumbbell)`.
- **Trademark:** no US mark found for "German Volume Training".

```json
{
  "id": "german-volume-training",
  "name": "German Volume Training",
  "author": "Charles Poliquin",
  "goal": "muscle",
  "level": "intermediate",
  "equipment": "fullGym",
  "daysPerWeek": 3,
  "summary": "Ten sets of ten on one big lift per body part, paired as antagonist supersets with short rest. Brutal volume aimed at fast size gains; run it in six-cycle blocks.",
  "schedule": "5-day cycle: Day 1 Chest & Back, Day 2 Legs & Abs, Day 3 off, Day 4 Arms & Shoulders, Day 5 off (about 4 sessions a week). Run six cycles, then switch to lower reps for three weeks.",
  "progression": "Start the 10×10 lifts at ~60% of 1RM (a weight you could do 20 times) and keep it for all ten sets. Once you complete 10×10 with constant rest, add 4–5%.",
  "source": "Charles Poliquin, 'German Volume Training', Poliquin Group (2010)",
  "sourceURL": "https://web.archive.org/web/20130927092047/http://www.poliquingroup.com:80/ArticlesMultimedia/Articles/Article/441/German_Volume_Training.aspx",
  "routines": [
    {
      "name": "Day 1 · Chest & Back",
      "exercises": [
        { "exercise": "Decline Bench Press (Dumbbell)", "sets": [{ "count": 10, "reps": 10 }], "rest": 90, "notes": "A1 · Superset with the next exercise. Neutral grip, tempo 4-0-X-0" },
        { "exercise": "Chin Up", "sets": [{ "count": 10, "reps": 10 }], "rest": 90, "notes": "A2 · Tempo 4-0-X-0" },
        { "exercise": "Incline Chest Fly (Dumbbell)", "sets": [{ "count": 3, "reps": 10, "repsMax": 12 }], "rest": 60, "notes": "B1 · Superset with the next exercise. Tempo 3-0-2-0" },
        { "exercise": "Dumbbell Row", "sets": [{ "count": 3, "reps": 10, "repsMax": 12 }], "rest": 60, "notes": "B2 · One arm, tempo 3-0-2-0" }
      ]
    },
    {
      "name": "Day 2 · Legs & Abs",
      "exercises": [
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 10, "reps": 10 }], "rest": 90, "notes": "A1 · Superset with the next exercise. Tempo 4-0-2-0" },
        { "exercise": "Lying Leg Curl (Machine)", "sets": [{ "count": 10, "reps": 10 }], "rest": 90, "notes": "A2 · Feet turned out, tempo 4-0-X-0" },
        { "exercise": "Reverse Crunch", "sets": [{ "count": 3, "reps": 15, "repsMax": 20 }], "rest": 60, "notes": "B1 · Superset with the next exercise. Stand-in for low-cable pull-ins" },
        { "exercise": "Seated Calf Raise", "sets": [{ "count": 3, "reps": 15, "repsMax": 20 }], "rest": 60, "notes": "B2 · Tempo 2-0-2-0" }
      ]
    },
    {
      "name": "Day 4 · Arms & Shoulders",
      "exercises": [
        { "exercise": "Triceps Dip", "sets": [{ "count": 10, "reps": 10 }], "rest": 90, "notes": "A1 · Superset with the next exercise. Parallel-bar dips, tempo 4-0-X-0" },
        { "exercise": "Seated Incline Hammer Curl (Dumbbell)", "sets": [{ "count": 10, "reps": 10 }], "rest": 90, "notes": "A2 · Tempo 4-0-X-0" },
        { "exercise": "Rear Delt Reverse Fly (Dumbbell)", "sets": [{ "count": 3, "reps": 10, "repsMax": 12 }], "rest": 60, "notes": "B1 · Superset with the next exercise. Bent-over lateral raise" },
        { "exercise": "Seated Lateral Raise (Dumbbell)", "sets": [{ "count": 3, "reps": 10, "repsMax": 12 }], "rest": 60, "notes": "B2" }
      ]
    }
  ]
}
```

---

## 10. Generic Bulking Routine — Lyle McDonald

- **Purpose / level / days / equipment:** hypertrophy · intermediate (roughly 1–3 years of training, per Lyle) · 4 days/week · full gym
- **Schedule:** upper/lower, each twice a week.
- **Progression:** 8-week cycles: two submaximal run-up weeks, then six weeks of adding weight, then drop back and repeat.
- **Source:** Lyle McDonald, "Training Volume and Muscle Growth: Part 3", section "A Sample GBR Workout". https://bodyrecomposition.com/training/training-volume-muscle-growth-3 (2018, updated 2020). The workout is a table image on that page.
  > Table: "Upper Body — Bench Press 4X6-8/3' · Row 4X6-8/3' · Flye/Incline Bench 2-3X10-12/1.5' · Cable pullover/pulldown 2-3X10-12/1.5' · Lateral Raise 4X8-10/2' · Rear Delt 4X8-10/2' · Biceps 2-3X10-12/1.5' · Triceps 2-3X10-12/1.5' | Lower Body — Squat 4X6-8/3' · RDL 4X6-8/3' · Leg Ext/Split Squat 2-3X10-12/1.5' · Leg Curl 2-3X10-12/1.5' · Calf Raise 4X8-10/2' · Seated Calf 4X8-10/2' · Abs Whatever · Low Back Whatever"
  > "It was an Upper/Lower routine done 4 times per week … 2 weeks of a submaximal run up and then 6 weeks of trying to make progressive weight increase"
  > "Big compound movements get 3 minutes, smaller muscles get 2 minutes and high rep work gets 90 seconds"
  > From "A Look at Some Popular Hypertrophy Programs" (bodyrecomposition.com): "Sets are meant to be stopped 1-2 reps short of failure"
- **Disagreements / choices:**
  - The widely copied 2008 forum version is only available second-hand (e.g., jcdfitness.com, liftvault). It has 3–4×6–8 compounds, 1–2×12–15 arm work and no side or rear delt work.
  - I used Lyle's own 2018/2020 table.
  - "Abs / Low back: Whatever" isn't encoded because it has no rep target. It goes in the last exercise's `notes`.
  - Lyle says to vary exercises between the two weekly sessions if you like; both sessions are encoded identically.
- **Library substitutions:** none. Generic slots were filled with the first option: Row → `Bent Over Row (Barbell)`, Rear Delt → `Rear Delt Reverse Fly (Dumbbell)`, Biceps → `Bicep Curl (Dumbbell)`, Triceps → `Triceps Pushdown`.
- **Trademark:** none found.

```json
{
  "id": "generic-bulking-routine",
  "name": "Generic Bulking Routine",
  "author": "Lyle McDonald",
  "goal": "muscle",
  "level": "intermediate",
  "equipment": "fullGym",
  "daysPerWeek": 4,
  "summary": "Lyle McDonald's upper/lower hypertrophy template: heavy 6–8 rep compounds plus moderate-rep accessories, each muscle twice a week. For intermediates who want steady size gains.",
  "schedule": "Four days a week: Upper, Lower, rest, Upper, Lower (e.g. Mon/Tue/Thu/Fri), rest at the weekend.",
  "progression": "8-week cycles: 2 submaximal run-up weeks, then 6 weeks adding weight as consistently as possible, stopping sets 1–2 reps short of failure. Then drop the weights and start a new cycle.",
  "source": "Lyle McDonald, 'Training Volume and Muscle Growth: Part 3' — sample GBR workout, bodyrecomposition.com",
  "sourceURL": "https://bodyrecomposition.com/training/training-volume-muscle-growth-3",
  "routines": [
    {
      "name": "Upper",
      "exercises": [
        { "exercise": "Bench Press (Barbell)", "sets": [{ "count": 4, "reps": 6, "repsMax": 8 }], "rest": 180 },
        { "exercise": "Bent Over Row (Barbell)", "sets": [{ "count": 4, "reps": 6, "repsMax": 8 }], "rest": 180, "notes": "Any row" },
        { "exercise": "Incline Bench Press (Barbell)", "sets": [{ "count": 2, "reps": 10, "repsMax": 12 }], "rest": 90, "notes": "Or flyes; 2–3 sets" },
        { "exercise": "Lat Pulldown (Cable)", "sets": [{ "count": 2, "reps": 10, "repsMax": 12 }], "rest": 90, "notes": "Or cable pullover; 2–3 sets" },
        { "exercise": "Lateral Raise (Dumbbell)", "sets": [{ "count": 4, "reps": 8, "repsMax": 10 }], "rest": 120 },
        { "exercise": "Rear Delt Reverse Fly (Dumbbell)", "sets": [{ "count": 4, "reps": 8, "repsMax": 10 }], "rest": 120 },
        { "exercise": "Bicep Curl (Dumbbell)", "sets": [{ "count": 2, "reps": 10, "repsMax": 12 }], "rest": 90, "notes": "Any curl; 2–3 sets" },
        { "exercise": "Triceps Pushdown", "sets": [{ "count": 2, "reps": 10, "repsMax": 12 }], "rest": 90, "notes": "Any triceps exercise; 2–3 sets" }
      ]
    },
    {
      "name": "Lower",
      "exercises": [
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 4, "reps": 6, "repsMax": 8 }], "rest": 180 },
        { "exercise": "Romanian Deadlift (Barbell)", "sets": [{ "count": 4, "reps": 6, "repsMax": 8 }], "rest": 180 },
        { "exercise": "Leg Extension (Machine)", "sets": [{ "count": 2, "reps": 10, "repsMax": 12 }], "rest": 90, "notes": "Or split squat; 2–3 sets" },
        { "exercise": "Lying Leg Curl (Machine)", "sets": [{ "count": 2, "reps": 10, "repsMax": 12 }], "rest": 90, "notes": "2–3 sets" },
        { "exercise": "Standing Calf Raise (Machine)", "sets": [{ "count": 4, "reps": 8, "repsMax": 10 }], "rest": 120 },
        { "exercise": "Seated Calf Raise", "sets": [{ "count": 4, "reps": 8, "repsMax": 10 }], "rest": 120, "notes": "Then abs and low-back work of your choice" }
      ]
    }
  ]
}
```

---

## 11. Heavy Duty (Ideal Routine) — Mike Mentzer

- **Purpose / level / days / equipment:** low-time, high-intensity (HIT) · intermediate · one workout every 4+ days (about 2 a week) · full gym
- **Schedule:** workouts 1 through 4 in rotation, 96 hours apart. Add rest days as you get stronger.
- **Progression:** judge each workout by strength. If you aren't stronger, rest more.
- **Source:** "Mike Mentzer's Ideal Routine: A Heavy Duty Blueprint", John Little, MikeMentzer.org, 2026. This site describes itself as "the only official website … authorized to represent Mike Mentzer and Heavy Duty®". https://mikementzer.org/mike-mentzers-ideal-routine-a-heavy-duty-blueprint/
  > "Each workout is separated by 96 hours (four days), with flexibility to add additional rest days as needed."
  > "Day One – Chest & Back: Pec Deck: 1 set, 6–10 reps to failure, Superset with Incline Press (machine preferred): 1 set, 1–3 reps to failure; Close-Grip Palms-Up Pulldowns: 1 set, 6–10 reps; Deadlifts (regular style): 1 set, 5–8 reps (near failure), Alternative if needed: Shrugs, 6–10 reps"
  > "Day Two – Legs: Leg Extensions: 1 set, 8–15 reps, Superset with Leg Press (or Squat if no leg press): 1 set, 8–15 reps; Standing Calf Raises: 1 set, 12–20 reps"
  > "Day Three – Delts & Arms: Dumbbell Laterals 1×6–10; Rear Delt Raises (or reverse pec deck) 1×6–10; Barbell Curls (straight bar) 1×6–10; Triceps Pressdowns 1×6–10, Superset with Dips: 1 set, 3–5 reps (or negatives if necessary)"
  > "Day Four – Legs: Leg Extensions (static hold): 1 heavy static hold, 10–25 seconds, Superset with Squats (Smith or free weight): 1 set, 8–15 reps; Standing Calf Raises: 1 set, 12–20 reps"
  > "…are you stronger the next time you perform the workout? If strength increases, growth has been stimulated."
- **Disagreements / choices:**
  - The "Consolidated Routine" (four compound exercises — squats, deadlifts, dips, pulldowns — split over two workouts four to seven days apart) is described on the same site (https://mikementzer.org/mike-mentzer-consolidated-routine-four-exercise-heavy-duty-blueprint/) but without rep targets. I encoded the fully specified Ideal Routine instead.
  - Every set is `failure` except the deadlift ("near failure") and the static hold.
  - Mentzer's warm-ups are not included.
- **Library substitutions:**
  - Close-grip palms-up pulldown → `Reverse Grip Lat Pulldown (Cable)`.
  - The leg-extension static hold is encoded as 1 rep with a note, because the schema has no field for time.
- **Trademark:** "HEAVY DUTY" is registered in the US to Hit Universal Ltd (UK) and is live (Serial 98139512; printed books and personal training). Mentzer's own earlier registrations (74520401, 76455050) are dead.

```json
{
  "id": "heavy-duty-ideal-routine",
  "name": "Heavy Duty (Ideal Routine)",
  "author": "Mike Mentzer",
  "goal": "muscle",
  "level": "intermediate",
  "equipment": "fullGym",
  "daysPerWeek": 2,
  "summary": "Mentzer's high-intensity training: one all-out set per exercise, a few big movements, and lots of rest between workouts. For lifters who want short sessions and can push to true failure.",
  "schedule": "Rotate Workouts 1→2→3→4, one workout every 4 days (96 h). As you get stronger, add rest days — every 5–7 days is common.",
  "progression": "Beat the previous weight or reps on every set. If you aren't stronger than last time, add rest days before the next workout.",
  "source": "Mike Mentzer's Ideal Routine, as presented on MikeMentzer.org (John Little, 2026), from Mentzer's own teaching",
  "sourceURL": "https://mikementzer.org/mike-mentzers-ideal-routine-a-heavy-duty-blueprint/",
  "routines": [
    {
      "name": "Workout 1 · Chest & Back",
      "exercises": [
        { "exercise": "Butterfly (Pec Deck)", "sets": [{ "count": 1, "reps": 6, "repsMax": 10, "kind": "failure" }], "notes": "Superset with the next exercise" },
        { "exercise": "Incline Chest Press (Machine)", "sets": [{ "count": 1, "reps": 1, "repsMax": 3, "kind": "failure" }], "notes": "Machine preferred" },
        { "exercise": "Reverse Grip Lat Pulldown (Cable)", "sets": [{ "count": 1, "reps": 6, "repsMax": 10, "kind": "failure" }], "notes": "Close grip, palms up" },
        { "exercise": "Deadlift (Barbell)", "sets": [{ "count": 1, "reps": 5, "repsMax": 8 }], "notes": "Near failure; shrugs 6–10 if you can't deadlift" }
      ]
    },
    {
      "name": "Workout 2 · Legs",
      "exercises": [
        { "exercise": "Leg Extension (Machine)", "sets": [{ "count": 1, "reps": 8, "repsMax": 15, "kind": "failure" }], "notes": "Superset with the next exercise" },
        { "exercise": "Leg Press (Machine)", "sets": [{ "count": 1, "reps": 8, "repsMax": 15, "kind": "failure" }], "notes": "Or squat" },
        { "exercise": "Standing Calf Raise (Machine)", "sets": [{ "count": 1, "reps": 12, "repsMax": 20, "kind": "failure" }] }
      ]
    },
    {
      "name": "Workout 3 · Delts & Arms",
      "exercises": [
        { "exercise": "Lateral Raise (Dumbbell)", "sets": [{ "count": 1, "reps": 6, "repsMax": 10, "kind": "failure" }] },
        { "exercise": "Rear Delt Reverse Fly (Dumbbell)", "sets": [{ "count": 1, "reps": 6, "repsMax": 10, "kind": "failure" }], "notes": "Or reverse pec deck" },
        { "exercise": "Bicep Curl (Barbell)", "sets": [{ "count": 1, "reps": 6, "repsMax": 10, "kind": "failure" }], "notes": "Straight bar" },
        { "exercise": "Triceps Pushdown", "sets": [{ "count": 1, "reps": 6, "repsMax": 10, "kind": "failure" }], "notes": "Superset with the next exercise" },
        { "exercise": "Triceps Dip", "sets": [{ "count": 1, "reps": 3, "repsMax": 5, "kind": "failure" }], "notes": "Negatives if you can't do reps" }
      ]
    },
    {
      "name": "Workout 4 · Legs",
      "exercises": [
        { "exercise": "Leg Extension (Machine)", "sets": [{ "count": 1, "reps": 1 }], "notes": "One heavy static hold, 10–25 s. Superset with the next exercise" },
        { "exercise": "Squat (Barbell)", "sets": [{ "count": 1, "reps": 8, "repsMax": 15, "kind": "failure" }], "notes": "Smith or free weight" },
        { "exercise": "Standing Calf Raise (Machine)", "sets": [{ "count": 1, "reps": 12, "repsMax": 20, "kind": "failure" }] }
      ]
    }
  ]
}
```

---

## 12. Westside for Skinny Bastards (Part III template) — Joe DeFranco

- **Purpose / level / days / equipment:** athletic performance · intermediate · 4 days/week · full gym
- **Schedule:** Monday max-effort upper, Tuesday dynamic-effort lower (jumps), Thursday repetition upper, Friday max-effort lower.
- **Progression:** max-effort days work up to a 3–5RM. Try to beat it over time and rotate the ME lift.
- **Source:** Joe DeFranco, "Westside for Skinny Bastards, Part III: The Final Chapter". http://www.defrancostraining.com/articles/38-articles/65-westside-for-skinny-bastards-part3.html — the live DeFranco site now 404s, so it was read via Wayback `20081229141314`.
  > "MONDAY – Max-Effort Upper Body TUESDAY – Dynamic-Effort Lower Body WEDNESDAY – Off THURSDAY – Repetition Upper Body FRIDAY – Max-Effort Lower Body"
  > Mon: "Max-Effort Exercise – work up to a max set of 3-5 reps … Supplemental Exercise – perform 2 sets of max reps … (Choose a weight you can perform for 15-20 reps on the 1st set … rest 3-4 minutes between sets) … Horizontal pulling / Rear delt superset … 3-4 supersets of 8-12 reps … Traps – 3 – 4 sets of 8-15 reps … Elbow flexor exercise – 3-4 sets of 8-15 reps"
  > Tue: "Jump training … 5-8 sets of 1-3 jumps … Unilateral exercise … 2-3 sets of 8-10 reps … Hip extension exercise … 3 sets of 8-12 reps … Weighted Abdominals … 4 sets of 10-15 reps"
  > Thu: "Repetition Exercise … 3 sets of max reps OR 4 sets of 12-15 reps … Vertical pulling / Rear delt superset … 3-4 supersets of 8-12 reps … Medial delts … 4 sets of 8-12 reps … Traps / Arms superset … 3 supersets … Grip / Forearms"
  > Fri: "MAX-EFFORT LIFT – work up to a max set of 3-5 reps … UNILATERAL MOVEMENT – 3 sets of 6-12 reps … HAMSTRING / POSTERIOR CHAIN MOVEMENT – 3 sets of 8-12 reps … Ground-based, high-rep abdominal circuit – Example: sprinter sit-ups, V-ups, toe touches, hip thrusts. Perform 10-20 reps of each exercise and go through the circuit 2-3 times. Rest 1-2 minutes between circuits."
  > Rep-day rest: "I now recommend 90 seconds rest between repetition sets for most females and beginners, and three minutes rest for stronger athletes."
- **Disagreements / choices:**
  - Each slot is a menu. I picked the first listed option unless that would repeat an exercise already used that week. Then the next option was chosen:
    - Thursday: incline DB press and face pulls
    - Thursday traps/arms: barbell shrugs and DB triceps extension
    - Friday: reverse lunge and RDL
  - Parts I and II use an older 3-day template; Part III supersedes them.
- **Library substitutions:**
  - Sprinter sit-ups → `Sit Up`.
  - Ground "hip thrusts" → `Hip Thrust` (bodyweight).
  - Everything else matched exactly.
- **Trademark:**
  - No US mark found for "Westside for Skinny Bastards".
  - "WESTSIDE BARBELL" is registered to Tee and Ell Weight Lifting and Exercise Enterprises, Inc. (Louie Simmons' company; Serials 85617325, 88676099, 90138871). Don't brand anything "Westside Barbell".

```json
{
  "id": "westside-for-skinny-bastards",
  "name": "Westside for Skinny Bastards",
  "author": "Joe DeFranco",
  "goal": "athletic",
  "level": "intermediate",
  "equipment": "fullGym",
  "daysPerWeek": 4,
  "summary": "DeFranco's Westside-style template for young athletes: two max-effort days, a jumping day and a high-rep upper day. Builds strength, size and explosiveness.",
  "schedule": "Mon Max-Effort Upper, Tue Dynamic-Effort Lower (jumps), Wed off, Thu Repetition Upper, Fri Max-Effort Lower, weekend off.",
  "progression": "Max-effort days: work up to a new 3–5RM and rotate the max-effort lift (bench/floor press/incline/close-grip/weighted chin; box squat/squat/deadlift/trap-bar/rack pull). Repetition sets: beat last time's reps.",
  "source": "Joe DeFranco, 'Westside for Skinny Bastards, Part III: The Final Chapter', defrancostraining.com",
  "sourceURL": "https://web.archive.org/web/20081229141314/http://www.defrancostraining.com:80/articles/38-articles/65-westside-for-skinny-bastards-part3.html",
  "routines": [
    {
      "name": "Monday · Max-Effort Upper",
      "exercises": [
        { "exercise": "Bench Press (Barbell)", "sets": [{ "count": 1, "reps": 3, "repsMax": 5 }], "notes": "Work up to a 3–5RM" },
        { "exercise": "Bench Press (Dumbbell)", "sets": [{ "count": 2, "kind": "failure" }], "rest": 180, "notes": "Weight you can do 15–20× on set 1" },
        { "exercise": "Dumbbell Row", "sets": [{ "count": 3, "reps": 8, "repsMax": 12 }], "notes": "Superset with the next exercise; 3–4 rounds" },
        { "exercise": "Rear Delt Reverse Fly (Dumbbell)", "sets": [{ "count": 3, "reps": 8, "repsMax": 12 }] },
        { "exercise": "Shrug (Dumbbell)", "sets": [{ "count": 3, "reps": 8, "repsMax": 15 }], "notes": "3–4 sets" },
        { "exercise": "Bicep Curl (Barbell)", "sets": [{ "count": 3, "reps": 8, "repsMax": 15 }], "notes": "3–4 sets" }
      ]
    },
    {
      "name": "Tuesday · Dynamic-Effort Lower",
      "exercises": [
        { "exercise": "Box Jump", "sets": [{ "count": 5, "reps": 1, "repsMax": 3 }], "notes": "5–8 sets" },
        { "exercise": "Bulgarian Split Squat (Dumbbell)", "sets": [{ "count": 2, "reps": 8, "repsMax": 10 }], "notes": "Per leg, front foot elevated; 2–3 sets" },
        { "exercise": "Back Extension (Hyperextension)", "sets": [{ "count": 3, "reps": 8, "repsMax": 12 }], "notes": "45° hyperextension" },
        { "exercise": "Side Bend (Dumbbell)", "sets": [{ "count": 4, "reps": 10, "repsMax": 15 }], "notes": "Weighted abs" }
      ]
    },
    {
      "name": "Thursday · Repetition Upper",
      "exercises": [
        { "exercise": "Incline Bench Press (Dumbbell)", "sets": [{ "count": 3, "kind": "failure" }], "rest": 90, "notes": "Max reps (or 4×12–15); stronger lifters rest up to 3 min" },
        { "exercise": "Lat Pulldown (Cable)", "sets": [{ "count": 3, "reps": 8, "repsMax": 12 }], "notes": "Superset with the next exercise; 3–4 rounds" },
        { "exercise": "Face Pull", "sets": [{ "count": 3, "reps": 8, "repsMax": 12 }] },
        { "exercise": "Lateral Raise (Dumbbell)", "sets": [{ "count": 4, "reps": 8, "repsMax": 12 }] },
        { "exercise": "Shrug (Barbell)", "sets": [{ "count": 3, "reps": 8, "repsMax": 10 }], "notes": "Superset with the next exercise" },
        { "exercise": "Triceps Extension (Dumbbell)", "sets": [{ "count": 3, "reps": 10, "repsMax": 15 }] },
        { "exercise": "Wrist Roller", "sets": [{ "count": 2, "reps": 2, "repsMax": 3 }], "notes": "2–3 sets; skip if deadlifting next day" }
      ]
    },
    {
      "name": "Friday · Max-Effort Lower",
      "exercises": [
        { "exercise": "Box Squat (Barbell)", "sets": [{ "count": 1, "reps": 3, "repsMax": 5 }], "notes": "Work up to a 3–5RM" },
        { "exercise": "Reverse Lunge (Barbell)", "sets": [{ "count": 3, "reps": 6, "repsMax": 12 }], "notes": "Per leg" },
        { "exercise": "Romanian Deadlift (Barbell)", "sets": [{ "count": 3, "reps": 8, "repsMax": 12 }] },
        { "exercise": "V Up", "sets": [{ "count": 2, "reps": 10, "repsMax": 20 }], "notes": "Ab circuit, 2–3 rounds" },
        { "exercise": "Toe Touch", "sets": [{ "count": 2, "reps": 10, "repsMax": 20 }], "notes": "Ab circuit" },
        { "exercise": "Sit Up", "sets": [{ "count": 2, "reps": 10, "repsMax": 20 }], "notes": "Ab circuit; sprinter sit-ups" },
        { "exercise": "Hip Thrust", "sets": [{ "count": 2, "reps": 10, "repsMax": 20 }], "rest": 90, "notes": "Ab circuit, bodyweight; rest 1–2 min between rounds" }
      ]
    }
  ]
}
```

---

## 13. Kettlebell Simple & Sinister — Pavel Tsatsouline

- **Purpose / level / days / equipment:** kettlebell conditioning and strength · beginner · near-daily · one kettlebell
- **Schedule:** near-daily practice, with two sessions a week as the minimum when life gets busy.
- **Progression:** train unhurried and test the time standards occasionally. Goal weights are listed in the JSON.
- **Sources (StrongFirst, Pavel's organisation):**
  - https://www.strongfirst.com/simple-sinister-progression-tactic/ (Pavel Tsatsouline):
    > "…the program calls for 10×10 one-arm swings (five sets per arm), with the goal of eventually being able to do them in five minutes with a particular size kettlebell any time."
    > "Most of your S&S sessions do not rush the clock and wait until you can pass the talk test before your next set. On the last session of each week push harder and occasionally all out and test yourself."
  - https://www.strongfirst.com/achieve/sinister/:
    > "This program involves 100 one-hand swings and 10 get-ups … 10 swings every 30 seconds … 1 get-up every minute on the minute, switching hands each minute" — "SIMPLE Goal: Women get-up 16kg, swing 24kg; Men 32kg / 32kg — SINISTER Goal: Women 24kg / 32kg; Men 48kg / 48kg"
  - https://www.strongfirst.com/an-excerpt-from-kettlebell-simple-sinister/ (Pavel):
    > "…the S&S program, while tolerating a minimum of two workouts a week if you are in a pickle, prescribes near-daily training."
- **Disagreements / choices:**
  - The book prescribes a short warm-up of prying goblet squats, halos and hip bridges. The exact reps could not be verified from an online primary source, so the warm-up is omitted. The library has `Kettlebell Goblet Squat`, `Kettlebell Halo` and `Glute Bridge` if it gets added later.
  - No rest value is set because rest is governed by the talk test.
- **Library substitutions:** none.
- **Trademark:**
  - "SIMPLE & SINISTER" is registered in the US to Power By Pavel, Inc. and is live (Serial 97103854).
  - "STRONGFIRST" is registered to StrongFirst, Inc. and is live (85784190).

```json
{
  "id": "simple-and-sinister",
  "name": "Kettlebell Simple & Sinister",
  "author": "Pavel Tsatsouline",
  "goal": "conditioning",
  "level": "beginner",
  "equipment": "kettlebell",
  "daysPerWeek": 6,
  "summary": "One kettlebell, two lifts — 100 one-arm swings and 10 Turkish get-ups — practised almost every day. Builds all-round strength and conditioning in about half an hour.",
  "schedule": "Near-daily practice (minimum two sessions a week if life gets in the way).",
  "progression": "Train unhurried, resting until you pass the talk test. Occasionally (e.g. the last session of the week) test the standard: 100 swings in 5 min, then 10 get-ups in 10 min. Goals — Simple: 32 kg swing and get-up (men), 24 kg swing / 16 kg get-up (women); Sinister: 48 kg (men), 32 kg swing / 24 kg get-up (women).",
  "source": "Pavel Tsatsouline, Kettlebell Simple & Sinister; StrongFirst articles",
  "sourceURL": "https://www.strongfirst.com/simple-sinister-progression-tactic/",
  "routines": [
    {
      "name": "Daily Practice",
      "exercises": [
        { "exercise": "Kettlebell Swing", "sets": [{ "count": 10, "reps": 10 }], "notes": "One-arm, switch hands each set (5 sets per arm)" },
        { "exercise": "Kettlebell Turkish Get Up", "sets": [{ "count": 10, "reps": 1 }], "notes": "Switch sides each rep (5 per side)" }
      ]
    }
  ]
}
```

---

## 14. Convict Conditioning — "New Blood" — Paul "Coach" Wade

- **Why this over Mark Lauren's *You Are Your Own Gym*:** YAYOG's plans are weekly-changing ladders and intervals that exist only in the book and app, with no online primary source. Convict Conditioning has a fixed two-day plan and ten named steps per movement, confirmed by the publisher's own contents list.
- **Purpose / level / days / equipment:** bodyweight / home · beginner · 2 days/week · bodyweight (plus a pull-up bar)
- **Schedule:** Monday push-ups and leg raises, Friday pull-ups and squats.
- **Progression:** each movement has 10 steps. Move to the next step once you hit the current step's progression standard.
- **Sources:**
  - **Primary:** Paul Wade, *Convict Conditioning* (Dragon Door, 2009) — book only. Dragon Door's store is offline as of 2026. Its archived sales page (https://web.archive.org/web/20091206045352/http://www.dragondoor.com:80/b41.html) lists the contents:
    > "5 major Convict Conditioning training programs… Page 276 · The New Blood training program… Page 278"
    > "STEP FIVE: Full Pushups… Page 54", "STEP FIVE: Full Squats… Page 92", "STEP FIVE: Full Pullups… Page 130", "STEP FIVE: Flat Straight Leg Raises… Page 164", "STEP TEN: One-Arm Pushups… One-Leg Squats… One-Arm Pullups… Hanging Straight Leg Raises"
  - **Schedule — second-hand only, but consistent:**
    - Paleo Minds: "New Blood splits pushups, leg raises, pullups and squats, over two workouts a week" (http://www.paleominds.co.uk/convict-conditioning-336-hours-later-beginner-mistakes-and-reprogramming/)
    - Hardcore Fight Fitness: "NEW BLOOD … ponedjeljak [Monday]: PUSHUPS = 2-3 seta, LEG RAISES = 2-3 seta … petak [Friday]: PULLUPS = 2-3 seta, SQUATS = 2-3 seta" (http://hardcorefightfitness.blogspot.com/2012/08/convict-conditioning-by-paul-coach-wade.html)
- **Disagreements / choices:**
  - **Reps are deliberately left out.** Each step's standards (beginner, intermediate, progression) are in the book only, and secondary sources disagree. For step-5 push-ups, one gives 2×20 and another suggests 2×30.
  - Under the schema, no reps reads as "max reps". **Main agent: either fill these from the book or show "work sets at your step's standard" in the UI.**
  - The "full" step 5 of each movement is encoded because it is the canonical version and exists in the library. Earlier and later steps that exist in the library are in `notes`.
- **Library substitutions:**
  - Flat straight leg raise (step 5) → `Lying Leg Raise`.
  - Full pull-up → `Pull Up`.
  - Most intermediate steps (uneven push-ups, jackknife squats, and so on) are not in the library.
- **Trademark:** no US registration found for "Convict Conditioning".

```json
{
  "id": "convict-conditioning-new-blood",
  "name": "Convict Conditioning: New Blood",
  "author": "Paul Wade",
  "goal": "bodyweight",
  "level": "beginner",
  "equipment": "bodyweight",
  "daysPerWeek": 2,
  "summary": "Prison-style calisthenics: four big bodyweight movements, each with ten progressively harder steps, trained twice a week. Needs only a pull-up bar.",
  "schedule": "Monday: push-ups and leg raises. Friday: pull-ups and squats. 2–3 work sets each; the rest of the week off.",
  "progression": "Train each movement at your current step (1–10). When you reach that step's progression standard, move to the next step. Leave a rep or two in the tank.",
  "source": "Paul Wade, Convict Conditioning (Dragon Door, 2009) — 'New Blood' program, p. 278; schedule confirmed second-hand",
  "sourceURL": "https://web.archive.org/web/20091206045352/http://www.dragondoor.com:80/b41.html",
  "routines": [
    {
      "name": "Monday · Push & Core",
      "exercises": [
        { "exercise": "Push Up", "sets": [{ "count": 2 }], "notes": "Step 5 of 10 — use your step (Incline Push Ups, Kneeling Push Up …); 2–3 work sets" },
        { "exercise": "Lying Leg Raise", "sets": [{ "count": 2 }], "notes": "Step 5 of 10 — earlier: Lying Knee Raise; later: Hanging Knee Raise → Hanging Leg Raise" }
      ]
    },
    {
      "name": "Friday · Pull & Legs",
      "exercises": [
        { "exercise": "Pull Up", "sets": [{ "count": 2 }], "notes": "Step 5 of 10 — earlier: Inverted Row; 2–3 work sets" },
        { "exercise": "Squat (Bodyweight)", "sets": [{ "count": 2 }], "notes": "Step 5 of 10 — later: Assisted Pistol Squats → Pistol Squat" }
      ]
    }
  ]
}
```

---

## 15. Glute Lab 4-Day Glute Program — Bret Contreras

- **Purpose / level / days / equipment:** glute and lower-body focus · intermediate · 4 days/week · full gym (plus bands)
- **Schedule:** Monday, Tuesday, Thursday and Friday. Each day is full body with glutes first.
- **Progression:** not specified in the source.
- **Source:** Bret Contreras, "How to Design an Optimal Glute Training Program", bretcontreras.com, 11 February 2015. https://bretcontreras.com/how-to-design-an-optimal-glute-training-program/
  > "I'm going to give you a sample four day glute training program that I'd give someone who trained with me at my gym – The Glute Lab."
  > "Monday: barbell hip thrust pyramid 1 x 10, 1 x 8, 1 x 6, 1 x 15; goblet squat 3 x 12; heavy kettlebell deadlift 2 x 15; 45 degree hyper 2 x 20; band seated hip abduction 2 x 20; incline press 2 x 10; lat pulldown 2 x 10"
  > "Tuesday: band hip thrust 3 x 10; walking lunge 2 x 50 (total steps, so 25 per leg); reverse hyper 3 x 10; lateral band walk 2 x 20; push up 2 x AMRAP; Hammer Strength row 2 x 10"
  > "Thursday: barbell hip thrust 3 x 6; Bulgarian split squat 2 x 10; 45 degree hyper 2 x 30; pendulum quadruped hip extension 2 x 10; band side lying clam 2 x 20; dumbbell shoulder press 2 x 10; one arm row 2 x 10"
  > "Friday: double band hip thrust 3 x 20 (band around knees and band over the hips); Cybex leg press 3 x 10; American deadlift 2 x 8; band standing hip abduction 2 x 20; dumbbell bench press 2 x 10; inverted row 2 x 10"
- **Disagreements / choices:**
  - *Strong Curves* (the book with Kellie Davis) has other programs, but they are book-only. This one is Bret's own published program.
  - No rest times are given.
  - The same article also offers a bodybuilder split and a powerlifter version; not encoded.
- **Library substitutions:**
  - Heavy kettlebell deadlift → `Deadlift (Dumbbell)`.
  - Band seated hip abduction → `Hip Abduction (Machine)`.
  - Band standing hip abduction → `Hip Abduction (Cable)`.
  - Band and double-band hip thrust → `Hip Thrust` (bodyweight), with the band noted.
  - Pendulum quadruped hip extension → `Glute Kickback (Machine)`.
  - Hammer Strength row → `Iso-Lateral Row (Machine)`.
  - American deadlift → `Romanian Deadlift (Barbell)`.
- **Trademark:**
  - "GLUTE LAB" is registered in the US to BC Athletics, LLC (Bret's company, AZ) and is live (Serial 87513088). Don't name the routine "Glute Lab" without permission.
  - No US mark found for "Strong Curves".

```json
{
  "id": "contreras-glute-program",
  "name": "Bret Contreras 4-Day Glute Program",
  "author": "Bret Contreras",
  "goal": "glutes",
  "level": "intermediate",
  "equipment": "fullGym",
  "daysPerWeek": 4,
  "summary": "The sample program 'the Glute Guy' gives his gym clients: hip thrusts every session plus squats, hinges and abduction work, with light upper-body pressing and pulling. For lifters who want to grow their glutes.",
  "schedule": "Four full-body sessions a week, glutes first: Mon, Tue, Thu, Fri.",
  "progression": "Not specified in the source.",
  "source": "Bret Contreras, 'How to Design an Optimal Glute Training Program', bretcontreras.com (2015)",
  "sourceURL": "https://bretcontreras.com/how-to-design-an-optimal-glute-training-program/",
  "routines": [
    {
      "name": "Monday",
      "exercises": [
        { "exercise": "Hip Thrust (Barbell)", "sets": [{ "count": 1, "reps": 10 }, { "count": 1, "reps": 8 }, { "count": 1, "reps": 6 }, { "count": 1, "reps": 15 }], "notes": "Pyramid" },
        { "exercise": "Goblet Squat", "sets": [{ "count": 3, "reps": 12 }] },
        { "exercise": "Deadlift (Dumbbell)", "sets": [{ "count": 2, "reps": 15 }], "notes": "Stand-in for a heavy kettlebell deadlift" },
        { "exercise": "Back Extension (Hyperextension)", "sets": [{ "count": 2, "reps": 20 }], "notes": "45° hyper" },
        { "exercise": "Hip Abduction (Machine)", "sets": [{ "count": 2, "reps": 20 }], "notes": "Stand-in for band seated hip abduction" },
        { "exercise": "Incline Bench Press (Barbell)", "sets": [{ "count": 2, "reps": 10 }] },
        { "exercise": "Lat Pulldown (Cable)", "sets": [{ "count": 2, "reps": 10 }] }
      ]
    },
    {
      "name": "Tuesday",
      "exercises": [
        { "exercise": "Hip Thrust", "sets": [{ "count": 3, "reps": 10 }], "notes": "Band across the hips" },
        { "exercise": "Walking Lunge", "sets": [{ "count": 2, "reps": 50 }], "notes": "50 total steps (25 per leg)" },
        { "exercise": "Reverse Hyperextension", "sets": [{ "count": 3, "reps": 10 }] },
        { "exercise": "Lateral Band Walks", "sets": [{ "count": 2, "reps": 20 }] },
        { "exercise": "Push Up", "sets": [{ "count": 2, "kind": "failure" }], "notes": "AMRAP" },
        { "exercise": "Iso-Lateral Row (Machine)", "sets": [{ "count": 2, "reps": 10 }], "notes": "Hammer Strength row" }
      ]
    },
    {
      "name": "Thursday",
      "exercises": [
        { "exercise": "Hip Thrust (Barbell)", "sets": [{ "count": 3, "reps": 6 }] },
        { "exercise": "Bulgarian Split Squat (Dumbbell)", "sets": [{ "count": 2, "reps": 10 }], "notes": "Per leg" },
        { "exercise": "Back Extension (Hyperextension)", "sets": [{ "count": 2, "reps": 30 }], "notes": "45° hyper" },
        { "exercise": "Glute Kickback (Machine)", "sets": [{ "count": 2, "reps": 10 }], "notes": "Stand-in for pendulum quadruped hip extension" },
        { "exercise": "Clamshell", "sets": [{ "count": 2, "reps": 20 }], "notes": "Band, side-lying" },
        { "exercise": "Shoulder Press (Dumbbell)", "sets": [{ "count": 2, "reps": 10 }] },
        { "exercise": "Dumbbell Row", "sets": [{ "count": 2, "reps": 10 }], "notes": "One arm" }
      ]
    },
    {
      "name": "Friday",
      "exercises": [
        { "exercise": "Hip Thrust", "sets": [{ "count": 3, "reps": 20 }], "notes": "Double band: around knees and over hips" },
        { "exercise": "Leg Press (Machine)", "sets": [{ "count": 3, "reps": 10 }] },
        { "exercise": "Romanian Deadlift (Barbell)", "sets": [{ "count": 2, "reps": 8 }], "notes": "American deadlift: RDL + posterior pelvic tilt at the top" },
        { "exercise": "Hip Abduction (Cable)", "sets": [{ "count": 2, "reps": 20 }], "notes": "Stand-in for band standing hip abduction" },
        { "exercise": "Bench Press (Dumbbell)", "sets": [{ "count": 2, "reps": 10 }] },
        { "exercise": "Inverted Row", "sets": [{ "count": 2, "reps": 10 }] }
      ]
    }
  ]
}
```

---

## 16. StrongLifts Quarantine (dumbbell-only) — Mehdi Hadim — swapped in for Blood & Guts

- **Why the swap:** Blood & Guts was dropped (see the end of this file). This is the only candidate I found with a primary source that fills the empty `dumbbells` equipment slot and the "home / hotel gym" use case. It is less famous than Blood & Guts but comes from an author already in the library. Drop it if dumbbell-only variety isn't wanted.
- **Purpose / level / days / equipment:** home or hotel strength plus size · beginner · 3 days/week · dumbbells and a bench
- **Schedule:** A and B alternate, three times a week.
- **Progression:** add weight when every set hits 12 reps.
- **Source:** https://stronglifts.com/quarantine/
  > "Workout A: DB Lunges 5×12, DB Bench Press 5×12, DB Row 5×12, DB Curl 3×12 | Workout B: DB Romanian Deadlift 5×12, DB Incline Bench Press 5×12, DB Overhead Press 5×12, Situps 3×12"
  > "On unilateral exercises like DB Lunges, this means twelve reps per leg" — "Quarantine is a 3x/week dumbbell program … Alternate workouts A and B each time you train."
  > "If you complete twelve reps on all sets, add weight next workout. Pick the next heaviest dumbbell that you have available."
  > "Do twelve reps for one leg. Then do 12 reps for your other leg. That's set one. Rest 2-3min" → 150 on lunges only. No general rest rule is stated.
- **Library substitutions:** none.
- **Trademark:** see StrongLifts (section 2).

```json
{
  "id": "stronglifts-quarantine",
  "name": "StrongLifts Quarantine (Dumbbell)",
  "author": "Mehdi Hadim",
  "goal": "muscle",
  "level": "beginner",
  "equipment": "dumbbells",
  "daysPerWeek": 3,
  "summary": "A dumbbell-and-bench version of StrongLifts for home or hotel gyms: two alternating full-body workouts with sets of twelve. Good when there's no barbell.",
  "schedule": "Alternate Workout A and Workout B three times a week (e.g. Mon/Wed/Fri).",
  "progression": "When you complete 12 reps on all sets, move up to the next heaviest dumbbell next workout; expect slower jumps than with a barbell.",
  "source": "Mehdi Hadim, 'Quarantine: Dumbbell Hotel Gym Workout', stronglifts.com",
  "sourceURL": "https://stronglifts.com/quarantine/",
  "routines": [
    {
      "name": "Workout A",
      "exercises": [
        { "exercise": "Lunge (Dumbbell)", "sets": [{ "count": 5, "reps": 12 }], "rest": 150, "notes": "12 per leg" },
        { "exercise": "Bench Press (Dumbbell)", "sets": [{ "count": 5, "reps": 12 }] },
        { "exercise": "Dumbbell Row", "sets": [{ "count": 5, "reps": 12 }] },
        { "exercise": "Bicep Curl (Dumbbell)", "sets": [{ "count": 3, "reps": 12 }] }
      ]
    },
    {
      "name": "Workout B",
      "exercises": [
        { "exercise": "Romanian Deadlift (Dumbbell)", "sets": [{ "count": 5, "reps": 12 }] },
        { "exercise": "Incline Bench Press (Dumbbell)", "sets": [{ "count": 5, "reps": 12 }] },
        { "exercise": "Overhead Press (Dumbbell)", "sets": [{ "count": 5, "reps": 12 }] },
        { "exercise": "Sit Up", "sets": [{ "count": 3, "reps": 12 }] }
      ]
    }
  ]
}
```

---

## Coverage

| Program | Purpose | Level | Equipment | Days/wk |
|---|---|---|---|---|
| Starting Strength | beginner strength | beginner | barbell | 3 |
| StrongLifts 5×5 | beginner strength | beginner | barbell | 3 |
| Texas Method | powerlifting-style strength | intermediate | barbell | 3 |
| 5/3/1 Boring But Big | strength plus size | intermediate | barbell | 4 |
| Reg Park 5×5 | strength plus size (old-school) | beginner | barbell | 3 |
| PHAT | strength plus size (powerbuilding) | intermediate | fullGym | 5 |
| The Golden Six *(attributed)* | bodybuilding, full body | beginner | barbell | 3 |
| Arnold Split (Blueprint to Mass) | bodybuilding, high volume | advanced | fullGym | 6 |
| German Volume Training | hypertrophy (10×10) | intermediate | fullGym | 3 per 5-day cycle |
| Generic Bulking Routine | hypertrophy, upper/lower | intermediate | fullGym | 4 |
| Heavy Duty (Ideal Routine) | low-time, high-intensity | intermediate | fullGym | ~2 |
| Westside for Skinny Bastards | athletic performance | intermediate | fullGym | 4 |
| Kettlebell Simple & Sinister | kettlebell conditioning | beginner | kettlebell | 6 (near-daily) |
| Convict Conditioning: New Blood | bodyweight / home | beginner | bodyweight | 2 |
| Bret Contreras 4-Day Glute Program | glutes / lower body | intermediate | fullGym | 4 |
| StrongLifts Quarantine | dumbbell-only / home | beginner | dumbbells | 3 |

## Dropped and swapped

- **Blood & Guts (Dorian Yates) — dropped.**
  - No primary source is reachable. dorianyates.net and dorianyates.com are offline. The archived official site's "Training Guides" page only ever said "COMING SOON". The *Blood & Guts* video and book are not online.
  - Secondary write-ups disagree on the exercises (e.g., Smith-machine incline vs barbell incline, Hammer Strength press vs flat bench, which day comes first).
  - Low-volume HIT is already covered by Heavy Duty.
- **Swapped in: StrongLifts Quarantine (dumbbell-only).** It fills the unused `dumbbells` equipment value and the home/hotel use case, with a primary source (section 16).
- **Bodyweight pick: Convict Conditioning "New Blood" over Mark Lauren's *You Are Your Own Gym*.** YAYOG's plans are weekly-changing ladders and intervals that exist only in the book and app.
- **Not encoded but described:**
  - Starting Strength Phase 3
  - Arnold Blueprint Phase 2 (weeks 5–8)
  - GVT Phase 2 (10×6)
  - Mentzer's Consolidated Routine (no rep targets published)
  - S&S warm-up (reps not verifiable online)

## Trademark summary (USPTO search at tmsearch.uspto.gov, 2026-09-25; US only; not legal advice)

| Name | US status |
|---|---|
| Starting Strength | **Registered, live** — Asgaard Funding, L.L.C.; includes **mobile app software** (85760005) |
| StrongLifts | Live for clothing only (86655346); services mark cancelled (85603512); site uses ™ |
| 5/3/1 | **"JIM WENDLER 5/3/1" registered, live** (90752575); app-software filing cancelled (85738319) |
| Heavy Duty | **Registered, live** — Hit Universal Ltd (98139512) |
| Simple & Sinister / StrongFirst | **Registered, live** — Power By Pavel, Inc. (97103854) / StrongFirst, Inc. (85784190) |
| Glute Lab | **Registered, live** — BC Athletics, LLC (87513088) |
| Westside Barbell (not WS4SB) | **Registered, live** — Tee and Ell Weight Lifting and Exercise Enterprises, Inc. |
| Arnold Schwarzenegger Blueprint (to Mass) | Applications abandoned (86197124, 86197133) — **right of publicity for his name and likeness still applies** |
| Texas Method, GVT, PHAT (Norton), Golden Six, Generic Bulking Routine, Reg Park, Convict Conditioning, Strong Curves, Westside for Skinny Bastards | No relevant US mark found |

**Practical takeaway:**

- Crediting an author ("by Jim Wendler") and describing a published program is normal and low-risk.
- Using a registered program name as the app's own product or feature name, or implying endorsement (especially Arnold's), is the risk.
- Starting Strength's registration explicitly covers mobile app software.
