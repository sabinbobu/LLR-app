Enter plan mode. Do not write code yet.

## Context
I want to imporve the gym tracking app further. I want a new section on the Workout tab called "Kineto" section where users build gym sessions from a curated, evidence-based set of exercises for chronic low-back / lumbar disc pain. Goal: build back and core strength and endurance to reduce pain. I have lumbar disc pain and am seeing a kinetotherapist, so the content must be conservative and defensible.

## Step 1: Inspect the codebase
Read the existing structure: stack, data model for exercises/sessions/workouts, and UI patterns. Reuse them. Report what you found in 5 lines max.

## Step 2: Research (web search, mandatory)
Find exercises recommended for lumbar disc pain / chronic low-back pain by:
- Peer-reviewed sources: nih.gov (PubMed, PMC), Cochrane reviews.
- Clinical guidelines: NICE, APTA, ACP, WHO.
- Reputable physiotherapy sources: professional bodies, university hospital/clinic patient-education pages, and spine researchers' published protocols (e.g. stabilization/endurance and directional-preference approaches).
Also identify which sites are best to source from and rank them by credibility.

Rules:
- Every exercise must have at least one source URL you actually opened. Never invent a URL, study, or author.
- Mark anything you could not verify as UNVERIFIED: and exclude it from the catalog.
- Where sources disagree (e.g. flexion vs extension exercises for disc issues), show the disagreement instead of picking silently.
- Record contraindications and red flags (e.g. pain radiating below the knee, numbness, weakness, bladder/bowel changes = stop and seek a doctor).

## Step 3: Deliver
1. Ranked source list with a credibility note each.
2. Exercise catalog table: name, target muscles, progression levels, sets/reps/hold guidance, common mistakes, contraindications, source URLs.
3. Proposed data model and schema changes for the app (exercise catalog with citations, session templates, pain log before/after per session).
4. Proposed UX: session builder from the catalog, progression, pain tracking, a persistent medical disclaimer, and a "clear this with your physiotherapist" gate before first use.
5. Risks and what to cut from v1.

## Output format
- The set of exercises will follow the same format as the main exercises that already exists in database ( e.g Chest Press (Barbell))
- Roadmap: at most 10 steps, no obvious ones, no padding.
- Create the implementation plan. 