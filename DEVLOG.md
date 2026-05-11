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

## v0.4 — Shipped + Queued
*40-item feedback pass from first real use session, plus continued design sessions*

### Phase 1 — Structural skeleton (shipped)
- Wizard reordered and expanded: 9 → 10 steps
- New step order: Style → Target → Timeline → Flour Blend → Water/Salt/Yeast → Method → Technique → Process → Bake Method → Confirm
- New Water/Salt/Yeast step: hydration slider with zone labels, salt %, yeast type picker + quantity
- "Process Script" renamed to "Process"
- `.interactiveDismissDisabled` prevents accidental wizard dismiss after step 0

### Phase 2 — Bug fixes (shipped)
- "My Style" field and Library Style badge: dark-on-dark fixed → adaptive `secondarySystemFill` background
- "Tonight" timeline showed past time after 11pm → renamed "Less than a day", logic fixed to `now + 8h`
- Version showing v1.0 → hardcoded v0.4 (Xcode MARKETING_VERSION was stale)
- `incorporateSalt.warningIfPlacedAfter` was triggering on default order → fixed to `[]`
- Pre-flight buffer double unit (2% %) → stripped % from placeholder
- Flour additives not displaying in recipe view → fixed
- "(2) Final Dough Add-ins" → renamed correctly per method

### Phase 3 — Wizard screen by screen (shipped)
- **Target:** linked ball weight ↔ diameter fields, WeightUnit selector (g/oz/lb), style-aware diameter (Neapolitan/NY only)
- **Timeline:** timing info sheet explaining ready-by logic and timeline descriptions
- **Method:** tap-to-enter preferment hydration % (TextField synced with slider)
- **Technique:** Other mixer fill-in, autolyse time entry with style-suggested default, mixing notes section
- **Process:** always-visible drag handles, trash per card, locked Bake card (🔒), freeform step title, AddStepSheet
- **Bake Method:** portable oven free-text sub-method, temperature unit Picker (°F/°C)
- **Confirm:** jump-to Edit links on each section, onJumpTo callback, review mode with "Return to Review →"
- **WizardContainer:** reviewMode, process order warning alert, new state wired through

### v0.4.1 — Buffer → Dough loss factor (shipped)
- Buffer field changed from % to absolute grams
- Default prefill: 25g per kg of target dough (= 2.5%)
- Renamed "Buffer" → "Dough loss factor", subtitle "stuck to bowl, hands, scraper"
- Footer: "~25g per kg is a good starting point · the more you make, the less you need"
- "Total with buffer" → "Total to mix"
- ConfirmStepView shows grams not %

---

## v0.5 — Queued

### Wizard
- **Timeline (Step 2):** remove biga warning from "Less than a day"; move incompatibility warning to Method step
- **Flour Blend (Step 3):** lock Next until components = 100%; clamp additives to 0.1–99.9% / 1 decimal; load saved blend; save to library inline
- **Method (Step 5):** timeline incompatibility warning; load saved preferment; save to library inline
- **Process (Step 7):** remove locked Bake card entirely; add locked "Combine" card at position 1 (title: "Combine", subtitle: "mix flour and water"); no card moveable above it; load saved process; save to library inline
- **Bake Method (Step 8):** rename section header "Select all that apply" → "Baking method"
- **Confirm (Step 9):** show linked sub-recipe names (blend/preferment/process) as tappable secondary rows

### Library
- Edit and Delete (with confirmation) per item via swipe
- Folders per section — create, rename, delete (items return to Unfiled)
- Move items between folders
- Edit recipe opens wizard pre-populated; rename supported in edit flow
- New sections: Flour Blends, Processes, Preferments — each with folders, Edit, Delete, rename
- Sub-recipe badges on recipe rows

### Welcome screen
- "New Recipe" button → action sheet: New Recipe / New Flour Blend / New Process / New Preferment
- Standalone builders for Flour Blend, Process, Preferment (reuse wizard views, wrapped with Save)

### Prep screen (formerly Pre-flight)
- Rename all "pre-flight" mentions → "Prep" / "Begin Prep"
- "Method" label under preferment → "Rise method"
- Show linked sub-recipe names
- Automatic mode caption updated to clarify time-keeping purpose

### Live session
- Clock-anchored timing — all step times stored as absolute `Date` values, no in-memory counters
- Accurate through app close, device restart, device switch
- **Automatic mode:** countdown from step duration; flips to `+MM:SS` (amber/red) when overtime; overtime logged
- **Manual mode:** count-up from 00:00:00; target duration shown as soft reference label
- "Next Step →" always tappable — no step ever blocked by timer
- Notes field on every step — pre-filled from recipe note, editable per session, saved to BakeLog
- "Combine" always first step (locked, from process queue above)
- Concurrent sessions supported — `activeSessions: [SessionViewModel]`
- Navigate away without ending session; persistent home screen indicator for active sessions
- Ending always explicit from within the session view

### Post-bake / Session review
- All logged fields editable after the bake
- Two tabs: **"As baked"** (raw, read-only) / **"Annotated"** (user-edited)
- Both tabs: "Save as Recipe" → new library entry named `[Recipe name] — [Month Day]`

### Models
- `FlourBlend.name: String`
- `SavedProcess(name, cards)`
- `SavedPreferment(id, name, method, hydration, notes)`
- `Folder(id, name, type, itemIDs)`
- `RecipeStore` gains `savedBlends`, `savedProcesses`, `savedPreferments`, `activeSessions`, `folders`
- `BakeLog` gains `stepStartedAt: Date`, overtime per step, annotated fields, per-step notes
- `ProcessCardType.combine` (locked position 1)
- `ProcessCardType.bake` removed from wizard list (retained for session logic)

### Copy / Labels
- "Pre-flight" → "Prep" / "Begin Prep" everywhere
- "Rise method" for preferment label in Prep and session overview
- "As baked" / "Annotated" in session review
- Session-saved recipe suffix: `— [Month Day]`
- Automatic mode caption updated
- Light mode enforced app-wide (`.preferredColorScheme(.light)` at root + hardcoded dark color audit)

---

## Design Principles (established through the build)

- **Plain word up top, descriptor below** — "Buffer" / "dough loss factor", "Kneading" / "gluten development"
- **Educational, not prescriptive** — the app teaches through labels and prompts, not locked rules
- **Sliders for exploration, fields for precision** — sliders show the range and concept; tappable fields let you be exact
- **Warnings, not blocks** — the app surfaces ordering issues and timing conflicts but lets you proceed
- **Session is a guest, recipe is the host** — pre-flight overrides are session-only; the recipe stays clean
- **Post-bake is a landing, not a debrief** — photo, quick visual, done. The log captures the reflection.
- **Light = welcoming, mono = technical** — home screen is warm; session and recipe screens are precise
