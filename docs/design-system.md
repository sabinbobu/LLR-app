# LLR design system

Tokens and building blocks live in `LLR/Components/` (`Theme.swift`, `Theme+Roles.swift`, `RoleButtonStyle.swift`, `CardStyle.swift`). New screens use these by default. Contrast of the label/fill pairs is asserted in `LLRTests/ThemeContrastTests.swift` (4.5:1, light and dark).

## Radius scale

| Token | Value | Use |
|---|---|---|
| `Theme.Radius.chip` | 8 | chips, small controls |
| `Theme.Radius.field` | 12 | fields, rows |
| `Theme.Radius.card` | 16 | cards, buttons |
| `Theme.Radius.hero` | 24 | hero cards, sheets |

Capsules stay capsules.

## Cards

`.card()` applies `CardStyle`: filled `Theme.card`, `Theme.border` hairline, radius 16, `Theme.cardPadding` (16). `.card(emphasised: true)` is the hero variant (radius 24, accent border).

## Button roles

Apply with `.buttonStyle(.primaryRole)` etc. All share height 52 (quiet: 44), `.headline` font, a 0.8 pressed opacity and a grey disabled look.

| Role | Style | Use |
|---|---|---|
| primary | `.primaryRole` | the one main action on a screen (fill `Theme.primaryFill`, white label) |
| secondary | `.secondaryRole` | second action, tinted accent fill |
| quiet | `.quietRole` | text only |
| destructive | `.destructiveRole` | red fill (`Theme.destructiveFill`); always paired with a confirmation or Undo |

`PrimaryButtonStyle` and `SheetButtonStyle` still exist and now render the primary role, so existing screens converge without edits.

## Colour tokens added

- `Theme.repeatAction` / `Theme.repeatActionLabel`: amber fill (#F59E0B dark, #D97706 light) with a #1C1300 label, used by the Workout tab's Repeat button (U2). Keep it away from `Theme.carbs` and the Push category colour.
- `Theme.primaryFill`: #2563EB in both modes. White on the dark-mode accent (#3B82F6) is only 3.7:1, so filled buttons do not use `Theme.accent`.
- `Theme.destructiveFill`: #C62828; system red with white text is 3.6:1.
- Each adaptive token has a `...UI` UIColor twin so tests can resolve it per appearance.

## Still to migrate (one PR per area, with before/after simulator screenshots)

Nothing outside `WorkoutTabView`'s Repeat button uses the new tokens yet.
1. Workout (cards, `.borderedProminent` uses, radius 14 and 10)
2. Profile
3. Fuel
4. Home / History
5. Sheets and pickers (`SheetButtonStyle` call sites)
6. Kineto
7. Onboarding

Per area: replace `.borderedProminent`, `.bordered`, `CardButtonStyle`, `PrimaryButtonStyle`, `SheetButtonStyle` and `cardStyle(cornerRadius:)` with roles and `.card()`; replace literal radii with `Theme.Radius`. Finish with the lint-style test from the D1 spec that fails on a banned style or off-scale radius (not added yet, since it would fail until every area is migrated).
