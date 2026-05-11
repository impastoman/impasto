# Impasto — Development Log

A record of what's been built, why, and the decisions that shaped it.

---

## v0.1 — Initial Scaffold
*First build*

**What shipped:**
- Core data models: Recipe, BakeLog, SessionStage
- RecipeStore (UserDefaults persistence)
- 5-step recipe wizard: Style → Method → Flour → Timeline → Confirm
- Live session view driven by SessionStage enum
- Session log with star rating, crust/crumb tags, notes
- Library and History tabs
- Dark theme with gold accent (D2B96A)

**Foundational calls made here:**
- Monospaced font throughout for a technical/artisan feel
- Gold accent as the single brand color
- UserDefaults over CoreData — keeps the app lightweight and portable

---

## v0.2 — Wizard Depth + Session Intelligence
*Method step, technique step, pre-flight, live session, post-bake*

**What shipped:**
- Wizard expanded to 7 steps, adding Method and Technique steps
- PreFlightView: preferment status, kitchen conditions (room temp, pH meter, thermometer)
- LiveSessionView: real-time timer, stage progress, ingredient reference panel, stage prompts
- SessionLogView: stage time comparisons (planned vs. actual), pause log, crust/crumb tag chips
- Time-aware timeline warnings (e.g. Biga needs 16h — only 8h available)
- Two-step navigation fix: PreFlightView launches LiveSessionView directly as fullScreenCover

**Key design decisions:**
- Pre-flight exists so every session starts with a check-in, not a cold launch
- Stage prompts are instructional, not prescriptive — they explain the *why* of each step
- Pause times are logged, not just paused — accountability over convenience

**Bug resolved:**
- Xcode project was on Desktop, source files in Documents — consolidated everything to Documents/Impasto so GitHub pulls land in the right place
- Target membership: established the workflow for adding externally-created files to the Xcode build target

---

## v0.3 — Flour Blend, Process Script, Bake Method, Post-Bake Report
*The big one*

**What shipped:**

*Models (all new):*
- FlourBlend: multi-component flour types (14 types) with percentages + additives (olive oil, milk, butter, malt, etc.)
- ProcessCard: replaces rigid SessionStage enum — cards are orderable, enable/disable-able, carry notes and per-card settings
- BakeSetup: multiple bake methods per recipe (home oven, pizza oven, portable oven, grill, other) selected at pre-flight
- PrefermentRecipe: standalone sub-recipe model for preferments (model built, wizard deferred to v0.4)

*Wizard expanded to 9 steps:*
- Flour Blend step: multi-component percentages, additives, rye warning, live total validation
- Process Script step: drag-to-reorder cards, per-card notes, bassinage reserve % slider, autolyse mode (standard / fermentolyse / saltolyse), order warnings
- Bake Method step: multi-select checkboxes, per-method setup detail

*Session flow:*
- SessionViewModel now drives from ProcessCard array instead of SessionStage enum
- Auto vs. Manual session mode — auto advances timer, manual waits for "Next Step"
- Pause durations logged individually and totalled
- PostBakeView: photo capture (PhotosPicker), bake time, oven temp, visual pickers (crust color, bottom, top)
- SessionLogView updated: pause log section, bake results section, generic FlowTagRow

*HomeView:*
- Light cream background (F5F1E8) — "dark doesn't feel welcoming"
- Version number display
- "Start Dough →" button with recipe picker

*PreFlightView:*
- Session mode selector (Auto / Manual)
- Last-minute overrides: ball count, ball weight, buffer — highlighted gold when overridden
- Bake method selector (from recipe's saved setups)

**Key design decisions driven by user input:**
- Preferment hydration is a *slider with reactive labels* (Dry Biga → Wet Poolish) rather than a named picker — "more educational, less biblical"
- Preferment recipes kept separate from dough recipes — "vibe tells me there's possibility users can take this to complex levels"
- Flour types as selectable percentages, not fixed — allows blends like 80% 00 + 20% semolina
- Additives (olive oil, milk, butter) treated as non-hydration liquid additives — "people don't usually think of those as changing hydration level"
- Buffer called "Buffer" / subtitle "dough loss factor" — matches the naming pattern of the app (plain word up top, descriptor below)
- Process cards are orderable with warnings — "drag and drop steps in a column, with clear warnings if way out of order"
- Autolyse prompted with 3 modes (standard / fermentolyse / saltolyse) — user asked how autolyse is actually used online; this came from that research
- Bake is a recipe-level attribute, not an afterthought — "at recipe creation, the user gets to add bake method"
- Post-bake is a separate gentle view — "it might be weird to have to manage an app" during the bake itself

---

## v0.3.1 — Custom Style
*Small but meaningful*

**What shipped:**
- "My Style" as a 5th pizza style option — free-form name, no preset guardrails
- Inline text field in the Style step when custom is selected
- Balanced defaults (65% hydration, 30% biga ratio) with explicit note that no style presets apply
- Confirm screen shows custom name and labels defaults section "Balanced defaults (no style preset)"
- Auto-generated recipe name uses custom style name as prefix

**Design decision:**
- Style as a slider (Neapolitan → NY → Detroit → Sicilian) was considered and rejected — the styles aren't on a linear spectrum
- Style note (description of intent) deferred: will be editable in Recipe Detail at any time rather than prompted at creation or post-bake

---

## v0.4 — In Progress
*40-item feedback pass from first real use session*

**Structural change (Phase 1 — do first):**
- Wizard reorder + new step count (9 → 10): balls and timeline move earlier, new Water/Salt/Yeast step added, "Process Script" renamed to "Process"

**Bug fixes queued (Phase 2):**
- "My Style" and Library "Style" badge: dark text on dark background
- "Tonight" timeline shows past time if already evening — renamed "Less than a day", time logic fixed
- Version shows v1.0 instead of v0.3 — needs Xcode target version set correctly
- Progress bar drops to 7 lines on certain steps
- "Reset to default order" does nothing
- Pre-flight buffer shows double unit (2% %)
- Flour additives not displaying in recipe view
- "(2)Final Dough Add-ins" section title/content incorrect

**Wizard improvements queued (Phase 3 — screen by screen):**
- Balls: linked weight/diameter fields, style-aware diameter estimate, unit selection (g / oz / lb)
- Timeline: rename, fix bug, add timing explanation icon
- Flour blend: load saved blend from library
- Water/Salt/Yeast: new dedicated step for hydration %, salt %, yeast type + quantity
- Preferment: tap-to-enter hydration % alongside slider
- Technique: notes field, "Other" mixer fill-in, autolyse time entry, autolyse/bassinage gates process defaults
- Process: drag handles + row numbers, remove button, add-a-step button, bake card locked, order warnings as review prompt
- Bake method: fillable sub-method field, temperature unit dropdown
- Confirm: jump-to-step links with "save and return to review"

**New screens queued (Phase 4):**
- Bench prep view (post-pre-flight checklist: materials + measured ingredients)
- Standalone Flour Blend builder (saveable to library, loadable in recipe creation)
- Standalone Process builder (saveable to library, loadable in recipe creation)

**Library & post-wizard queued (Phase 5):**
- `+` button: "New Dough Recipe" / "New Flour Blend" / "New Process"
- Recipe name expansion on tap
- RecipeDetailView: Edit Recipe button, flour blend tappable, hide biga row if ratio is 0%
- Session mode: remove Automatic, Manual only
- "Mis en place" → better baking-specific word (bench prep / setup — TBD)

---

## Design Principles (established through the build)

- **Plain word up top, descriptor below** — "Buffer" / "dough loss factor", "Kneading" / "gluten development"
- **Educational, not prescriptive** — the app teaches through labels and prompts, not locked rules
- **Sliders for exploration, fields for precision** — sliders show the range and concept; tappable fields let you be exact
- **Warnings, not blocks** — the app surfaces ordering issues and timing conflicts but lets you proceed
- **Session is a guest, recipe is the host** — pre-flight overrides are session-only; the recipe stays clean
- **Post-bake is a landing, not a debrief** — photo, quick visual, done. The log captures the reflection.
- **Light = welcoming, mono = technical** — home screen is warm; session and recipe screens are precise
