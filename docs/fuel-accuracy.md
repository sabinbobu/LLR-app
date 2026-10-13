# Fuel accuracy

Harness: `LLRTests/FoodAccuracyTests.swift`, fixtures: `LLRTests/Fixtures/fuel-meals.json` (20 meals, ground truth = grams × USDA per-100 g values, each food names its USDA FoodData Central entry).

**Caveat:** the per-100 g numbers were entered from memory of the named SR Legacy entries and are UNVERIFIED against the live database. Spot-check before blaming the model for a small error.

## Run

```
OPENROUTER_KEY=sk-or-... OPENROUTER_MODEL=openai/gpt-5.6-terra \
  xcodebuild -scheme LLR -destination 'platform=iOS Simulator,name=iPhone 17' \
  test -only-testing:LLRTests/FoodAccuracyTests/testLiveAccuracyReport
```

Without `OPENROUTER_KEY` the live test is skipped; `testFixtureIsComplete` and the error-math test still run offline.

Two passes per run: **stated grams** (tests food-composition recall and arithmetic) and **vague portions** (tests portion guessing, the F2 hypothesis). Error is mean absolute percentage error per meal; macros under 1 g are skipped.

## Baselines

| Date | Model | Pass | kcal | P | C | F |
|---|---|---|---|---|---|---|
| not yet recorded | default free model | stated grams | — | — | — | — |
| not yet recorded | default free model | vague portions | — | — | — | — |
| not yet recorded | one paid model | both | — | — | — | — |

Baselines need the owner's OpenRouter key and a build machine; neither exists in the environment this harness was written in. Fill the table from the printed `MEAN` lines.
