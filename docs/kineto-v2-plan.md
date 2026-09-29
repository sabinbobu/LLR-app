# Kineto v2: research and plan

Researched 2026-09-28. This covers the Kineto catalog (`LLR/Resources/kineto_exercises.json`, v1, 15 exercises) and the user-made exercise editor from #14.

## Status (2026-09-28)

- **Steps 3–5 are implemented, along with the code half of step 6.** That covers the new categories, `howto` on every catalog entry, `PrescribedOnly`, and category pills that hide when a category is empty. None of it has been built or tested yet, because the session that wrote it had no Xcode (Linux container). Run `xcodegen generate`, then build and test, before merging.
- **The content half of step 6 has not started.** No exercises have been added and the catalog is still `version: 1`, because steps 1–2 are blocked (sources can't be opened; the physio hasn't reviewed the table). Once they're done, adding the exercises only means editing `kineto_exercises.json`.
- `ExerciseInfoSheet` now also opens the Kineto page for anything logged in a Kineto workout or routine, not only for duration sets. That way a rep-based exercise like Pelvic Tilt shows your physio's video too.

## 0. Read this first

1. **Custom Kineto exercises with photos and videos already exist.** PR #14 shipped `ExerciseEditorView` and `KinetoExerciseFields`, so v2 finishes that editor rather than building a new one. It still has 6 gaps, listed in §3.
2. **None of the new sources below have been opened.** This session's network policy blocked page fetches (csp.org.uk, nhs.uk, nhsinform.scot, the NHS trust sites, pubmed, pmc, jospt.org). Everything in §1–§2 comes from web-search result text only. The Kineto rule is "every exercise must have a source URL you actually opened", so this content can't ship until roadmap step 1 is done. Doses marked **?** came from a search summary that didn't make clear which leaflet they came from.
3. **"Tested by kinetotherapists" has no registry.** There is no list of exercises that physios have validated. This plan uses two tests instead. An exercise must be (a) printed in patient material written by a physiotherapy department or the physiotherapists' professional body, and (b) of a type that a guideline or systematic review supports. The Tier column in §2 shows how well each exercise meets both.

## 1. Sources, ranked by credibility

| # | Source | Kind | Why it ranks here |
|---|---|---|---|
| 1 | [NICE NG59, recommendations](https://www.nice.org.uk/guidance/ng59/chapter/recommendations) | guideline | National guideline. Rec 1.2.1: consider group exercise (biomechanical, aerobic, mind–body) for low back pain with or without sciatica. It supports exercise types, not named exercises. |
| 2 | [APTA/JOSPT CPG, revision 2021](https://www.jospt.org/doi/10.2519/jospt.2021.0304) | guideline | The US physio guideline. Grade A for specific trunk-muscle activation and movement-control exercise in chronic LBP. Updates the 2012 CPG the catalog already cites. |
| 3 | [Cochrane: exercise therapy for chronic LBP (Hayden 2021)](https://www.cochranelibrary.com/cdsr/doi/10.1002/14651858.CD009790.pub2/full) + [NMA summary on PEDro](https://pedro.org.au/english/systematic-review-found-that-some-types-of-exercise-are-more-effective-than-others-for-adults-with-chronic-low-back-pain/) | systematic review | 249 trials; moderate certainty that exercise helps. The NMA ranks Pilates, McKenzie, functional restoration and core strengthening highest. |
| 4 | [Cochrane: motor control exercise (Saragiotto 2016)](https://pubmed.ncbi.nlm.nih.gov/26742533/) | systematic review | Motor control exercise beats minimal care, but at 3–12 months it's no better than other exercise. That tempers claims for "deep core" exercises. |
| 5 | [Hip strengthening added to LBP rehab (de Jesus 2020)](https://doi.org/10.1177/0269215520941914) | systematic review | Adding hip strengthening reduces pain and disability. Basis for the new Strength category. |
| 6 | [Neural mobilisation SR/MA (Basson 2017)](https://pubmed.ncbi.nlm.nih.gov/28704626/) | systematic review | Limited evidence that neural mobilisation helps nerve-related back and leg pain. The authors say the conclusions may change. |
| 7 | [McKenzie by credentialed therapists, directional preference SR/MA](https://pmc.ncbi.nlm.nih.gov/articles/PMC11924268/) | systematic review | Supports extension or flexion work when it matches the patient's directional preference. |
| 8 | [Long 2004, "Does it matter which exercise?"](https://www.ovid.com/jnls/spinejournal/abstract/10.1097/01.brs.0000146464.23007.2a~does-it-matter-which-exercise-a-randomized-control-trial-of) | RCT | Exercises matched to directional preference beat opposite or non-directional ones. The app's direction warning already relies on it. |
| 9 | [Halliday 2016, McKenzie vs motor control with DP](https://www.jospt.org/doi/10.2519/jospt.2016.6379) | RCT | The counterweight to #8; see Disagreements. |
| 10 | [Neurodynamic mobilisation + motor control, disc herniation RCT](https://pubmed.ncbi.nlm.nih.gov/31464753/) | RCT | Adding a nerve technique reduced neuropathic symptoms and SLR sensitivity, but not pain or disability. |
| 11 | [SLR neurodynamics + manipulation RCT (2023)](https://pmc.ncbi.nlm.nih.gov/articles/PMC10642333/) | RCT | Uses the straight-leg raise "to induce tension in the sciatic nerve". Basis for the hamstring-stretch caution below. |
| 12 | [Coppieters & Butler 2008, sliders vs tensioners](https://www.sciencedirect.com/science/article/abs/pii/S1356689X07000343) | lab study | Sliders move the nerve further with much less strain than tensioners. This is why the catalog uses a slider and never a tensioner. |
| 13 | NHS physio department leaflets: [South Tees (clam)](https://www.southtees.nhs.uk/resources/the-clam/), [South Tees (sciatic slider)](https://www.southtees.nhs.uk/resources/sciatic-nerve-slider/), [Plymouth (lower back strengthening)](https://www.plymouthhospitals.nhs.uk/display-pil/pil-lower-back-strengthening-exercises-4042/), [Plymouth (back rehab booklet)](https://www.plymouthhospitals.nhs.uk/download/back-rehabilitation-programme-final-august-2019-v2pdf.pdf?ver=21180&doc=docm93jijm4n9154), [Sussex Community (sciatica)](https://www.sussexcommunity.nhs.uk/patients-and-visitors/resources/patient-resources/sciatica/rehabilitation-exercises), [Sussex Community (mechanical LBP)](https://www.sussexcommunity.nhs.uk/patients-and-visitors/resources/patient-resources/mechanical-low-back-pain/management-and-self-help), [Worcestershire (core stability 1)](https://www.worcsacute.nhs.uk/documents/documents/patient-information-leaflets-a-z/core-stability-1-physiotherapy/?layout=file), [CUH (stretches for the hip)](https://www.cuh.nhs.uk/patient-information/stretches-for-the-hip/), [NHS Ayrshire & Arran](https://www.nhsaaa.net/musculoskeletal-msk-service-patient-portal/low-back-pain-msk-patient-portal/low-back-pain-exercises-msk-patient-portal/) | patient-education | The closest thing to "physio-tested": NHS physio departments write these and hand them out. They show clinical practice, not trial evidence. |
| 14 | [CSP, video exercises for back pain](https://www.csp.org.uk/conditions/back-pain/video-exercises-back-pain), [NHS.uk exercises for sciatica](https://www.nhs.uk/live-well/exercise/exercises-sciatica-problems/) | patient-education | CSP is the UK physiotherapists' professional body. Both have videos but give few written doses. |
| 15 | [Mayo Clinic Health System, LBP exercises (PDF)](https://www.mayoclinichealthsystem.org/-/media/national-files/documents/hometown-health/2021/low-back-pain-exercises.pdf) | patient-education | A US health system. Only used for the hamstring stretch. |

**Excluded:** commercial clinic and blog pages (spine-health, joionline, physitrack, goodrx and similar). They were only used to find primary sources.

## 2. Candidate exercises (13 new, plus new levels on 3 existing ones)

★ marks a name that already exists in `exercises.json`. Those entries carry only Kineto fields; seeding never touches the gym row.
Tier **A**: a guideline or review supports the exercise type, and an NHS/CSP leaflet includes the exercise. **B**: only one of those two. **C**: weak.
"Physio" in the Dose column means the leaflet says "as advised by your physiotherapist" or gives no dose. It shows as *Set by your physiotherapist*, as Side Plank does today.

| Name | Category | Dir. | Muscle (primary / secondary) | Equip. | Levels → dose | Cautions & common mistakes | Sources | Tier |
|---|---|---|---|---|---|---|---|---|
| Abdominal Hollowing | Stability & endurance | neutral | Abdominals / Lower Back | — | L1 Hold 10 × 10 s · L2 Long hold 10 × 30 s (Plymouth: "hold 10–30 s, repeat up to 10 times") | Holding your breath. Losing the pelvis's neutral midpoint. **Disagreement:** see below. | Plymouth LBS; Saragiotto 2016; Grenier & McGill 2007 (already cited) | A |
| Heel Slide | Stability & endurance | neutral | Abdominals / — | — | Physio | Back arching or pelvis rotating (Worcestershire). Plymouth starts it only once deep abdominals can be activated. | Worcestershire CS1; Plymouth booklet; APTA 2021 | A |
| Bent Knee Fall Out | Stability & endurance | neutral | Abdominals / Adductors | — | Physio | Pelvis rocking with the knee. UNVERIFIED: the how-to text; the only thing seen was Plymouth naming it. | Plymouth booklet; APTA 2021 | A |
| Clamshell ★ | **Strength** (new) | neutral | Glutes (gym row) | Resistance Band (gym row) | L1 No band: physio · L2 With band: physio | Heels together; lift the top knee "using the muscles in your buttock", hold, lower slowly (South Tees). | South Tees; de Jesus 2020 | A |
| Sit to Stand | Strength | neutral | Quadriceps / Glutes | Other (chair) | L1 1 × 15 · L2 3 × 15 **?** | Arms across chest; squeeze glutes as you rise. | NHS leaflet **?** (Plymouth LBS or Ayrshire; confirm which); Hayden 2021 NMA (functional) | B |
| Wall Squat (Swiss Ball) | Strength | neutral | Quadriceps / Glutes | Other | Physio | Ball behind lower back against the wall; set deep abdominals and pelvic floor first (Plymouth). | Plymouth LBS | B |
| Piriformis Stretch | Mobility | flexion | Glutes / — | — | Hold 30 s **?** | Figure-4 position, pulling the thigh toward the chest, so tag it flexion and let the direction warning apply. | NHS.uk sciatica (piriformis video) | B |
| Hamstring Stretch (Lying) | Mobility | neutral | Hamstrings / — | — | Physio | **With leg symptoms this is a straight-leg raise, which tensions the sciatic nerve** (2023 RCT). Stop if it brings on leg pain or tingling. | Mayo Clinic HS; PMC10642333 | C |
| Hip Flexor Stretch | Mobility | neutral | Quadriceps / — | — | Physio | Keep the spine neutral and the lower abdominals gently on (CUH). UNVERIFIED: which variant CUH shows (the search showed a prone quad-style stretch). | CUH hip stretches; de Jesus 2020 (hip stretching + back exercise) | C |
| Back Extension (Standing) | Mobility | extension | Lower Back / — | — | Physio | Only if extension is your direction (Long 2004). **Disagreement:** see below. | Long 2004; McKenzie SR/MA; APTA 2012 (already cited) | A (DP-matched only) |
| Sciatic Nerve Slider (Seated) | **Nerve mobility** (new) | neutral | Other / — | — | Physio | Seated: straighten the knee and point the toe while looking up; return while lowering the chin. Go slowly, and it should never hurt (South Tees). **Prescribed-only** (§4). Stop if tingling or numbness spreads. | South Tees; NHS.uk sciatica; Basson 2017; RCT 31464753; Coppieters & Butler 2008 | B |
| Swimming ★ | Aerobic (title for `walking`) | neutral | Cardio (gym row) | — | Physio | Start short. | Sussex mechanical LBP (lists swimming and cycling); NICE NG59 1.2.1 | A |
| Cycling ★ | Aerobic | neutral | Cardio (gym row) | Machine (gym row) | Physio | Start short. | Sussex mechanical LBP; NICE NG59 1.2.1 | A |

**New levels on existing entries** (from Sussex Community; each dose is marked **?** until the page is opened):
- Glute Bridge: add "NHS sciatica". Hold 5 s, repeat for 30 s, 3–5 sets. Encoded as `Sets 3, DurationSeconds 30`, with the pattern in `Notes`.
- Knee Rolls: add "Sussex". Hold 5 s each side, repeat for 30 s, 3–5 sets. Same encoding.
- Knee to Chest Stretch: add "Knee hug (both knees)". Hold 20–30 s, 3–5 times. Encoded as `Sets 3, DurationSeconds 20`, with "build to 30 s × 5" in `Notes`.

**Disagreements to show in the app, not settle:**
- *Hollowing vs bracing.* Grenier & McGill 2007 found bracing gave more lumbar stability. Plymouth and motor-control programmes teach hollowing. Saragiotto 2016 found neither kind of motor-control exercise beats general exercise. Ship both, and tell the user to do whichever one their physio taught.
- *McKenzie extension.* Long 2004 and the McKenzie SR/MA support it when it matches directional preference. Halliday 2016 compared McKenzie with motor control in that same group, and the result is the counterweight. UNVERIFIED: the size of that result, because the abstract wasn't opened.
- *Nerve sliders.* The review evidence is "limited" (Basson 2017). The disc-herniation RCT improved neural signs but not pain or disability. Keep the slider only if your physio prescribes it.

**Considered and cut:** Pallof press (no NHS/CSP source found), femoral nerve slider (for upper lumbar roots; too niche), Swiss-ball quadruped and seated work (Plymouth; adds equipment for little gain), side-lying hip abduction (no leaflet found; Clamshell covers the same muscles).

## 3. What the custom editor is still missing

Built-in catalog fields compared with what a user-made Kineto exercise can hold today:

| Field | Built-in | Custom today | v2 |
|---|---|---|---|
| Name, primary muscle, how-to steps, category, direction, mistakes, cautions, photos/videos | ✓ | ✓ | New categories only |
| **Secondary muscles, equipment** | ✓ | ✗ `CustomExerciseDraft.apply` writes them only for `.gym` | Share `GymExerciseFields`' two rows across both sections |
| **Levels** (label, sets, reps, hold, notes; any number) | ✓ | ✗ one unlabelled dose, no notes | Levels editor: add, delete, reorder, minimum 1 |
| **Sources** (title, URL, kind) | ✓ | ✗ none | Sources editor. New kind `physiotherapist`: "Prescribed by <name>", URL optional |
| **Rest timer** | gym only | ✗ | Same picker as gym |
| **Personal photos/videos and notes on a *built-in*** (e.g. your physio filming your Bird Dog) | ✗ | n/a | "My notes & media" sheet. The cited fields stay read-only. |

**A bug in v1, found while reading the code:** a built-in Kineto exercise's detail page never shows how-to steps. `KinetoExerciseDetailView` renders `ExerciseStepsView` only when `custom != nil`. The 9 non-★ entries have `Howto` in the JSON that the page never shows, and the 6 ★ entries have no Kineto how-to at all. The fix: add `howto` to `KinetoCatalog.Exercise`, read from `Seed.Howto`, and render it for every entry. `parse` already ignores `Howto` on ★ entries for library seeding, so it can't overwrite gym instructions.

## 4. Data model (additive, so no `VersionedSchema`)

**Migration impact:** every change is either a new optional or defaulted property or a JSON change, so SwiftData's lightweight migration covers it. There are no new `@Model` types. `ExerciseMedia` already relates to any `Exercise`, and `ExerciseLibrary.sync` never touches media, so built-ins get media without a schema change. Bumping the catalog to `version: 2` re-shows the physio gate once, on purpose, because new content needs physio review.

```swift
// Exercise: new stored properties
var kinetoLevelsData: Data?     // JSON [KinetoCatalog.Level]; nil = legacy row, read kinetoSets/Reps/DurationSeconds as one "Your dose" level
var kinetoSourcesData: Data?    // JSON [KinetoCatalog.Source]
var personalNotes: String = ""  // physio's cues on any exercise, built-in or custom

// KinetoCatalog
struct Level: Codable, Hashable { var label: String; var sets, reps, durationSeconds: Int?; var notes: String? }
struct Source: Codable, Hashable { var title: String; var url: String?; var kind: String }  // url optional: a physio prescription has none
enum Category { …; case strength = "Strength", nerveMobility = "Nerve mobility" }        // .walking keeps rawValue "Walking" (stored in custom rows); its title becomes "Aerobic"
struct Exercise { …; let howto: [String]; let prescribedOnly: Bool }                        // JSON: existing "Howto", new optional "PrescribedOnly"
```

Levels and sources are stored as JSON `Data` rather than an array of structs so that every stored property stays a primitive type, like the rest of the model. The cost is that you can't query inside them, and nothing needs to. The legacy `kinetoSets/Reps/DurationSeconds` stay as the fallback read. The first save from the new editor writes `kinetoLevelsData` and clears them.

## 5. UX

- **Editor** (Kineto section, top to bottom): name, muscle → secondary muscles, equipment → category, direction → **Levels** (rows like "L1 · 3 × 10 × 2 s", tap to edit, swipe to delete, Add level) → rest timer → mistakes, cautions → how-to steps → **Sources** (Add source: kind picker; URL validated as `https://` when present) → photos & videos. New `Problem` cases: `.noLevels` and `.invalidSourceURL`.
- **Custom detail label:** if a `physiotherapist` source exists, "Prescribed by <title>" replaces "Added by you — not from the cited catalog".
- **Built-in detail:** how-to (the bug fix), then a **My notes & media** card with an Edit button. That opens a sheet containing only the notes field and `ExerciseMediaSection`. `ExerciseInfoSheet` passes the `Exercise` row, so a logged exercise shows your media too.
- **Prescribed-only:** adding a `prescribedOnly` entry from the picker asks one confirmation, "Only add this if your physiotherapist prescribed it for you." It costs one tap when *building* a routine, and logging stays at 2 taps.
- **Split files to stay under ~200 lines:** `KinetoLevelsSection`, `KinetoLevelEditor`, `KinetoSourcesSection`, `KinetoSourcesList` (moved out of the 159-line detail view), `KinetoPersonalEditor`.

## 6. Risks

1. **Unverified content.** Every new source and every **?** dose. Blocking.
2. **The nerve slider is the one exercise that can directly irritate a compressed root.** Mitigations: prescribed-only confirmation, the existing `symptomsSpread` check-out question, and the red-flags screen. If the physio doesn't prescribe it, cut it.
3. **Hamstring Stretch (Lying) doubles as a sciatic nerve tensioner** for anyone with leg symptoms. It's tier C. Cut it unless the physio wants it.
4. **Name clash.** If you already made a custom exercise with one of the 13 new names, `sync` won't insert the built-in, and the catalog entry logs against your custom row. Check your custom Kineto names before shipping.
5. **★ rows are shared with gym.** Media you add to Kineto Plank is stored on the gym Plank row too. The gym detail page shows media only for custom exercises, so in practice it appears only on Kineto pages.
6. **Storage.** Videos are kept at 720p (about 30 MB per minute, per `ExerciseMediaStore`), so 20 one-minute clips take about 600 MB on the phone.

## 7. Roadmap

1. **Verify.** Open every URL in §1–§2 once the domains are allowed. Replace each **?** with the leaflet's exact wording or "physio", cut anything that fails, and paste quotes here the way `routine-library-research.md` does.
2. **Physio review.** Take the §2 table to your kinetotherapist and mark each row keep, cut or re-dose. Record the decisions here. They decide step 6's content.
3. **Model.** `Level`/`Source` become Codable with `var` fields and an optional `url`. Add the three `Exercise` properties, the two categories and the "Aerobic" title, and the legacy single-dose fallback. Tests: level and source round-trips through the draft; a legacy row reads as one level.
4. **Editor completeness.** Share the secondary-muscles and equipment rows, add the rest timer, and add the levels and sources editors with the new `Problem` cases. Tests: a Kineto `apply` writes equipment, secondary muscles and rest; a bad URL is rejected.
5. **Built-in detail page.** Kineto how-to for every entry (the bug fix), the My notes & media sheet, and the row passed through `ExerciseInfoSheet`.
6. **Content.** Add the approved exercises and new levels, write `Howto` for every entry (including the 6 existing ★ ones), add the `PrescribedOnly` confirmation, and set `version: 2`. Extend `KinetoCatalogTests` so every entry must have a how-to, and so the new categories and `PrescribedOnly` decode.

Steps 3–5 don't depend on clinical content and can start now. Step 6 waits on steps 1–2.
