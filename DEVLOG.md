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

## v0.5 — Library Architecture + Save-to-Library
*Sub-recipe management*

**What shipped:**
- LibraryView rewritten with 4 sections: Recipes, Flour Blends, Processes, Preferments — each with swipe-delete and confirmation alerts
- `+` button triggers a `confirmationDialog` with options for all four asset types plus "Start New Session" at the bottom
- Standalone builders: `StandaloneBlendBuilderView`, `StandaloneProcessBuilderView`, `StandalonePrefermentBuilderView` — full editors accessible outside the wizard
- Save-to-library flows in wizard steps for Flour Blend, Method, and Process — name the asset inline, save it, reuse on future recipes
- Flour blend step: Next button disabled until flour percentages total exactly 100%
- TargetStepView: weight unit selector (g / oz / lb) with full conversion throughout all fields — consistent with PreFlightView's unit picker
- "Rise method" label in Prep view (previously generic "Method")
- "⌂ Home" toolbar button in Library and History to return to welcome screen

**Design decisions:**
- Standalone builders reuse the same `FlourComponentRow` and `AdditiveRow` subviews as the wizard — single source of truth for the editing UI
- Save-to-library is optional and deferred to after the user has built the asset — not a gate, just an offer at the bottom
- The `+` button covers all creation types from one place — "the + button looks like it should allow that even from library"

---

## Import Recipe — Queued (version TBD)

**Entry point:** The `↑ Import Recipe` button on the home screen (currently a no-op placeholder) opens a sheet with two paths: **Load Impasto File** and **Transcribe a Recipe**. The transcription path is detailed below.

---

**Transcribe a Recipe — manual entry flow**

Intent: allow users to enter a recipe they found online or in a book, including volume-based measurements, and convert it into Impasto's weight/percentage-based model. Deliberately simpler than the New Recipe wizard — anyone going through this flow is translating an existing recipe, not designing from scratch.

*Step 1 — Total dough*
- Single field: total dough quantity (fillable number + unit dropdown: g / oz / lb)
- This anchors the scaling math for everything that follows

*Step 2 — Flour & Water*
- Flour: fillable number + unit dropdown (g / oz / lb / cup)
- Water: fillable number + unit dropdown (g / oz / lb / ml / cup / fl oz)
- If either field uses a volume unit, show an inline warning:
  > "Volume measurements are converted using standard averages (flour ~125g/cup, water 240g/cup). Weigh your ingredients for an exact recipe."
- Flour type picker: same `FlourType` list used in the wizard (bread, 00, AP, whole wheat, etc.)
- If multiple flour types, user can add rows — same `FlourComponentRow` pattern, must sum to 100%

*Step 3 — Salt, Yeast, Additives*
- Salt: fillable number + unit dropdown (g / oz / tsp / tbsp)
- Yeast: fillable number + unit dropdown (g / oz / tsp / tbsp) + yeast type picker (active dry / instant / fresh)
- Additional additives: same additive list used in the wizard (vital wheat gluten, diastatic malt, ascorbic acid, etc.) — user can add rows, each with number + unit dropdown
- Same volume conversion warning if any non-weight unit is selected

*Step 4 — Process*
- Process picker using the same `ProcessScriptStepView` / process builder
- Kept intentionally lightweight: pick a saved process or build a simple one
- No bake setup, no preferment, no timeline in this flow — those can be added later via Edit Recipe in the wizard

*Completion*
- "Open in Wizard →" hands off to `WizardContainerView` with `.fork(recipe)` mode pre-populated from the transcription data
- User lands at ConfirmStep to review before saving — they can jump to any step to refine
- Alternatively, "Save Directly" skips the wizard review and saves to library as-is

**Volume conversion reference (use these constants):**
- Flour (all-purpose / bread / 00): 125g/cup
- Whole wheat flour: 120g/cup
- Water: 240g/cup (exact)
- Salt (fine sea / kosher): 6g/tsp
- Active dry yeast: 3g/tsp
- Instant yeast: 3g/tsp
- Fresh yeast: ~6g/tsp (roughly 2× instant by weight)
- 1 tbsp = 3 tsp

**Design constraints:**
- No rise method, hydration slider, or timeline — those belong in the wizard and can be added post-import
- Volume warning is informational only — user can proceed without weighing; the flag is logged so `ConfirmStep` can surface it
- Flour blend must still sum to 100% before proceeding (same locked-Next rule as wizard)
- Additives are always "on top of" flour weight — never part of the 100% anchor

---

## v0.8 — Queued

**Preferment depth in wizard (MethodStepView):**
- Preferment ratio slider (1–99%, default ~20–30%) — what percentage of total flour goes into the preferment
- Separate flour blend scoped to the preferment — own `FlourComponentRow` and `AdditiveRow` entries, independent from the main dough blend
- `SavedPreferment` model gains `flourBlend: FlourBlend` and `ratioPercent: Double` — saves and loads the full preferment spec including its blend
- Ratio slider follows the existing "slider for exploration, field for precision" pattern — tap the value to type an exact number
- Preferment flour blend collapsible — most users use the same flour throughout; blend picker only expands if they want to specify

**ConfirmStepView — preferment display fix:**
- "Preferment blend" label currently shows the main dough flour blend, not a preferment-specific one — cosmetic issue; once `SavedPreferment` gains `flourBlend`, display the correct blend breakdown and ratio alongside hydration

**IngredientsChecklistView (dependent on preferment flour blend):**
- Currently preferment flour section shows a single "Biga flour" row with no sub-components — reads from `recipe.flourBlend` because `SavedPreferment` has no blend of its own yet
- Once `SavedPreferment` gains `flourBlend`, expand the preferment section the same way final dough works: sub-rows per component with gram weights from blend percentages

**PizzaLogView — per-pizza bake time:**
- "Bake time so far" label → "Bake time"
- Snapshot `vm.bakeElapsed` at the moment "Log Pizza" is opened — records how long that specific pizza took, not a running total
- `vm.bakeElapsed` already resets on "Return to Baking" via `resetBakeTimer`, so the value at open time is already the correct per-pizza duration

**Timeline incompatibility warning in MethodStepView:**
- Currently the incompatibility warning only surfaces in the pre-flight conflict alert — it should also be shown in the wizard's Method step (Step 5) at recipe creation time, before the user even gets to Prep
- Show inline warning when selected method + hydration implies a fermentation window that exceeds the selected timeline

**Library folders:**
- Create, rename, delete folders per section (Recipes, Flour Blends, Processes, Preferments)
- Items move between folders via swipe or edit menu
- Items not assigned to a folder appear under "Unfiled"
- Folders collapsed/expanded in the List

**Standalone builder Save vs. Save As:**
- `StandaloneBlendBuilderView`, `StandaloneProcessBuilderView`, `StandalonePrefermentBuilderView` currently only support creating new items
- Add edit mode: when opened from an existing library item, pre-populate and offer "Save" (update in place) vs. "Save as New" — same `.edit` / `.fork` pattern used in the recipe wizard

**Clock-anchored session timing:**
- Step times stored as absolute `Date` values (`stepStartedAt: Date`) so sessions survive app close, device restart, and device switch
- `BakeLog` gains `stepStartedAt` per card and overtime per step
- No in-memory counters — elapsed time always computed from `Date.now - stepStartedAt`

**"As baked" / "Annotated" in session review (SessionLogView / PostBakeView):**
- Two modes in the post-bake review: **As baked** (raw, read-only snapshot) and **Annotated** (user-edited reflection)
- All logged fields editable in Annotated mode after the fact
- Both modes: "Save as Recipe →" creates a new library entry named `[Recipe name] — [Month Day]`

---

## v0.6 — Edit/Fork, Session Architecture, Bake Flow
*The big refinement pass*

**What shipped:**

*Edit/Fork recipe flow:*
- `WizardMode` enum: `.new` / `.edit(Recipe)` / `.fork(Recipe)` — wizard opens pre-populated in all three cases
- Custom `WizardContainerView` init that reads an existing recipe and seeds all `@State` vars via `_var = State(initialValue:)` pattern
- Fork mode appends date suffix to recipe name automatically
- Edit save: preserves original `id` and `bakeLogs`, calls `store.update` — recipe history stays intact
- Fork save: assigns new `UUID`, calls `store.add`
- RecipeDetailView: "Edit Recipe" and "Modify and Save as New" action buttons with appropriate callbacks
- Tap recipe name in RecipeDetailView to rename inline via alert

*Wizard UX fixes:*
- `flourBlendMode`, `prefEntryMode`, `processMode` lifted to `WizardContainerView` as `@State` + passed as `@Binding` — back navigation no longer resets the wizard steps to the empty pick card
- Edit/fork mode pre-selects `.create` mode on blend/preferment/process steps so the existing data is visible immediately
- Process builder: duration field available on all step types, not just timed ones — leave at 0 and it hides in both the row and summary
- ConfirmStepView: cards with 0 duration show "action" vs. duration label; bake setups now show temp range and preheat time
- TargetStepView: weight and diameter fully independent — weight no longer auto-fills diameter; estimated diameter shown as gray hint text only for style-supported types (Neapolitan, NY); buffer footer changed to "~2.5% of total dough weight" (unit-agnostic)

*Session architecture (SessionManager):*
- `SessionManager: ObservableObject` — owns all `SessionViewModel` instances; injected at app root
- `SessionViewModel` made `Identifiable`, no longer auto-advances on timer expiry
- `LiveSessionView` takes `vm: @ObservedObject` from outside (not `@StateObject`) — vm lifecycle independent of the view
- **Hide Session**: house icon pauses the session and dismisses the cover; `vm.isHidden = true` prevents cleanup on dismiss; session stays in `SessionManager.sessions`
- `PreFlightView` creates vm via `sessionManager.start(...)` and cleans up on normal end via `onDismiss`
- HomeView: orange "Session in progress" cards for each hidden session with step progress + "Resume Session" button that re-opens `LiveSessionView(vm:)` via `fullScreenCover(item:)`

*Live session improvements:*
- **Back navigation**: `← Back` button always visible past first card; calls `vm.goBack()` which restores `elapsed` from `actualDurations`
- **Overtime counter**: once countdown hits 0:00:00, flips to orange count-up from 0 with "+XX:XX:XX overtime" label; progress bar turns orange
- **Long-press timer reset**: 0.6s long-press on timer digits → heavy haptic + `vm.resetTimer()`
- **Per-step session notes**: pencil icon + editable `TextField` on every step, keyed by card UUID, persists across step changes within the session
- **View recipe button**: `doc.text` toolbar icon opens RecipeDetailView sheet without leaving the session

*Bake flow:*
- Last process card shows "Proceed to Bake →" instead of "Done Baking"
- Enters bake step showing oven setup details from the selected `BakeSetup`
- "Start Baking" → separate bake timer begins (`vm.bakeElapsed`)
- Once baking: "Log Pizza" sheet + "End Baking" long-press (0.8s haptic → PostBakeView)
- **PizzaLogView**: new sheet with photo, bake time readout, visual pickers, crust/crumb tag chips, notes — "Return to Baking" resets bake timer; "End Bake →" goes straight to PostBakeView

*Ingredients Prep checklist:*
- "Prep Ingredients" button in Prep view session overview section
- `IngredientsChecklistView`: checkable per-ingredient rows with strikethrough
- Preferment and main/final dough shown as separate sections
- Flour blend components expand into sub-rows with individual gram weights calculated from percentages
- Bassinage reserve shown as its own split row
- Progress counter at the bottom

**Key design decisions:**
- SessionManager is the right place for session ownership — not RecipeStore, not the view itself. Views are ephemeral; the session is not.
- "Hide session" isn't "pause" — the timer is paused but the session is intentionally in a liminal state. The orange indicator on the home screen makes that explicit.
- Bake flow is a new phase, not a process card — "Proceed to Bake" transitions the session into a different mode with its own timer and loop logic. Per-pizza logging respects that you might bake several before ending.
- Overtime counts up rather than blocking — "the timer should continue" was the user's explicit ask. You already know you're late; the app just shows you how late.
- Independent weight/diameter: the fields aren't linked anymore because "ball weight and diameter can be separately entered." The estimate hint serves the curious without locking the field.

---

## v0.8 — Preferment Depth, Folders, Edit Mode, Clock Timing, Bake Detail

**What shipped:**

*Preferment depth (wizard):*
- `MethodStepView` gains preferment ratio slider (1–99%, default 30%) — tap field for precision
- Preferment flour blend section: toggle "Same as main blend" (default on); if off, mini blend editor with `FlourComponentRow` + `AdditiveRow`
- `SavedPreferment` model gains `flourBlend: FlourBlend`, `ratioPercent: Double`, `folderName: String`
- Library picker now shows ratio and loads it into the wizard when a preferment is selected
- `buildRecipe()` uses `prefermentRatio` instead of hard-coded `style.defaultBigaRatio`
- Timeline incompatibility warning shown inline in `MethodStepView` when `method.minimumHours > timeline.minimumHours`

*ConfirmStepView fix:*
- "Preferment blend" label was showing the main flour blend — now shows preferment-specific blend or "Same as main" fallback
- "Biga percentage" row now shows `prefermentRatio` instead of style default

*IngredientsChecklistView:*
- Preferment section now reads from `recipe.prefermentFlourBlend` when set; falls back to main blend
- Single flour → shows type label (not generic "Biga flour"); multi-component → expands sub-rows with gram weights

*PizzaLogView:*
- "Bake time so far" → "Bake time"
- `vm.bakeElapsed` is snapshot on open (`.onAppear`) so each logged pizza records its own duration, not a running total

*Clock-anchored session timing:*
- `SessionViewModel` replaces accumulator with `stepStartDate: Date?` + `accumulatedSeconds` approach
- Timer now computes `elapsed = accumulatedSeconds + Date().timeIntervalSince(stepStartDate)` — correct after app backgrounding
- Same pattern for `bakeElapsed` via `bakeStartDate` + `accumulatedBakeSeconds`

*Library edit mode:*
- All three standalone builders (`StandaloneBlendBuilderView`, `StandaloneProcessBuilderView`, `StandalonePrefermentBuilderView`) accept optional `editing:` parameter
- When editing: pre-populated, "Save" calls `store.update*`; when new: "Save" calls `store.add*`
- `LibraryView` adds left-swipe "Edit" action for Blends, Processes, and Preferments
- Sheets open the builder with the tapped item pre-loaded

*Library folders:*
- `FlourBlend`, `SavedProcess`, `SavedPreferment` gain `folderName: String = ""`
- Each standalone builder includes a "Folder" text field
- `LibraryView` sections group items using `Dictionary(grouping:)` — unfoldered items first, then `DisclosureGroup` per folder

*Bake log detail + annotated reflection:*
- New `BakeLogDetailView` with "As Baked" / "Annotated" tab picker
- As Baked tab: full read-only snapshot (photo, rating, bake results, stage times, tags, notes)
- Annotated tab: editable reflection rating + notes; "Save Annotation" persists via `store.updateBakeLog`
- "Fork as New Recipe →" button opens `WizardContainerView(.fork(...))` with bake log overrides applied
- `BakeLog` model gains `annotatedNotes: String` and `annotatedRating: Int?`
- `RecipeStore` gains `updateBakeLog(_:recipeId:)`
- `HistoryView` rows are now `NavigationLink`s to `BakeLogDetailView`; rows show pencil icon when annotated rating exists

**Key design decisions:**
- Preferment flour blend defaults to "same as main" — most bakers don't split blends; the toggle only expands when needed
- Ratio slider uses the same "slider + field" pattern as all other continuous values in the app — consistent with the design principle
- Clock-anchored timing is transparent to the view layer — `elapsed` is still `@Published var`; only the update mechanism changed
- Annotated tab is additive — the "As Baked" snapshot is always read-only; reflections can only be added, not replacing the original log

---

## v0.9 — Volume Converter, Session Navigation Fixes, Folder Move
*Converter pipeline, race condition resolution, UX polish*

**What shipped:**

*Volume recipe converter:*
- `VolumeConverterView` — full conversion flow: multi-flour entries (type + unit per row), water, salt (with kind picker), yeast (with type picker); "Review →" disabled until flour + water have values
- `ConversionReviewView` — two-table display (ingredient grams + baker's % summary), inline warnings for unusual hydration/salt/yeast values, "Build This Recipe →" hands off a `ConvertedFormula` struct
- `VolumeConversionTable.swift` — density reference for all flour types, salt kinds, and yeast types; `parseAmount(_:)` handles fractions, mixed numbers, and decimals
- `SaltKind` enum renamed to remove brand references: Table Salt / Kosher (Coarse) / Kosher (Fine) / Sea Salt (Coarse) / Sea Salt (Fine)
- "Convert a Volume Recipe" entry point added to the New Recipe action sheet on the home screen

*Wizard auto-fill from conversion:*
- `ConvertedFormula` struct bridges `VolumeConverterView` → `WizardContainerView`; carries `finalHydration`, `saltPct`, `yeastPct`, `yeastType`, `flourBlend`
- `hasConvertedFormula: Bool` stored let property guards `onChange(of: style)` — selecting a style no longer overwrites converted hydration
- `flourBlendMode` initialises to `.create` when a converted formula is provided — lands directly in the blend editor pre-populated, skipping the pick card
- `WaterSaltYeastStepView` gains `isFromConversion: Bool` flag — footer text changes to "Pre-filled from your volume recipe" for all three fields (water, salt, yeast)
- Two-sheet chain via `onDismiss`: converter sheet closes → `pendingFormula` set → `onDismiss` fires → wizard sheet opens; avoids presenting two sheets simultaneously

*Library folder move fix:*
- `.contextMenu` on `NavigationLink` rows replaced with leading swipe actions — context menu was unreliable (long-press activated the link's press state instead)
- `FolderPickerSheet` added as a private struct presented at the `NavigationStack` level via `sheet(item:)` — safe for cross-section moves
- "Remove from [folder]" option shown when item is already in a folder; destination folder list otherwise; hint shown when no folders exist yet
- Leading swipe available on all four section types: Recipes, Flour Blends, Processes, Preferments

*Session navigation bug fixes:*

**HomeView always-active observer** — `shouldReturnHome` observer was on `HomeView.launch`, which is only in the hierarchy when `showMainApp = false`. Re-entering a session from `ActiveSessionsView` sets `showMainApp = true`, so the observer went inactive. Fixed by wrapping `body` in a persistent `ZStack` and attaching the observer there — it is now always active regardless of which child is shown.

**shouldReturnHome race condition** — `SessionLogView.goHome()` was calling `end(vm)` before setting `shouldReturnHome = true`. When `sessions.count` dropped, the `onChange` guard checked `shouldReturnHome` and saw `false` — the entire stack collapsed prematurely. Fixed by setting `shouldReturnHome = true` first so the guard is armed before `sessions.count` changes. Same ordering fix applied to `LiveSessionView`'s "End without Logging" action.

*Home button dialog:*
- Confirmation dialog options standardised: "Leave Session" / "Pause & Leave Session" (only shown when running) / "End and Log" / "End without Logging" (destructive) / "Go Back" (cancel)
- "Pause & Leave" only appears while the timer is running — keeps the dialog uncluttered for paused sessions

**Key design decisions:**
- Volume conversion is the entry point; the wizard is still the authority — the converter hands off a formula, not a finished recipe. All wizard steps remain editable after conversion.
- Brand names removed from salt kinds because the app ships to international markets and "Diamond Crystal" is meaningless outside North America. Generic descriptors (coarse/fine, table/kosher/sea) are universally understood.
- Folder move via leading swipe is less discoverable than a context menu but far more reliable on `NavigationLink` rows in a `List`. A "Move" label with a folder icon covers discoverability.
- The `shouldReturnHome` pattern depends on ordering — documentation of the fix is intentionally detailed in this log because the bug is subtle enough to reintroduce.

---

## Sourdough Starter Support — Queued (post-V1, pre-2.0)

A self-contained sourdough starter management layer that sits alongside the existing dough recipe system — shared session infrastructure, separate recipe type, no disruption to existing flows.

---

### Entry point rename + new action

- **"Begin Dough" button** on the home screen renamed to **"Begin Session"** — neutral enough to cover both dough sessions and starter feeding sessions
- A second button appears alongside it: **"Begin Dough"** and **"Feed Starter"** as the two explicit paths

*Design note:* "Begin Session" as the parent opens the picker; "Begin Dough" and "Feed Starter" are its two children. Or: the two named buttons replace the single "Begin Dough" button entirely — decide at implementation. Either way the original dough start flow is unchanged.

---

### Sourdough Starter recipe type

- New section in Library: **Sourdough Starters** — separate from Recipes, Flour Blends, Processes, Preferments
- A starter recipe is defined by:
  - **Flour blend** — uses the existing flour blending tool (same `FlourBlend` model + `FlourComponentRow` UI)
  - **Hydration** — single slider/field, same "slider for exploration, field for precision" pattern
  - Name, optional notes
- Built via a dedicated builder accessible from the **home screen** and the **Library** only
- **Starters cannot be created inline** anywhere else in the app (see Preferment / Method step below)

---

### "Feed Starter" live session mode

- Tapping "Feed Starter" on the home screen opens a starter picker (existing starter recipes), then launches a live session in **fermentation-only mode**
- The session uses the existing `SessionManager` / `SessionViewModel` infrastructure — starter sessions appear alongside dough sessions in the active sessions list, fully concurrent
- **New default Process Steps for a starter feed session:**
  - Discard
  - Weigh flour
  - Add water
  - Mix
  - Rest / Ferment (timed, countdown)
  - (Optional) Refrigerate
- These steps follow the same ProcessCard system — user can reorder, add, remove, and set durations per their routine

---

### Sourdough Starter as a preferment option (wizard Method step)

- In the "Use preferment" section of the wizard's Method step, **Sourdough Starter** appears as a new preferment type option alongside Biga, Poolish, etc.
- When selected:
  - The existing starter recipes are listed for the user to pick from
  - No "create one now" option — starters must be built through the home screen or Library first
  - This is a deliberate contrast to flour blends and processes, where "create on the spot" is offered inline
  - *Rationale:* a sourdough starter has a life of its own outside any single recipe; it belongs in the library as a first-class managed asset, not something created in passing
- Once a starter is selected, its hydration and flour blend are read into the recipe's preferment calculations the same way a Biga or Poolish would be

---

**Deferred until:** V1 ships. No implementation work needed now.

---

## Social Photo Builder — Queued (version TBD)

A photo-based share tool. The user selects a pizza photo (from a logged bake) as the background, then superimposes toggleable recipe info blocks over it. Output is a shareable image via the iOS share sheet.

---

### Entry points

- **History view** — "Share" buttons pinned at the top of the view, always visible
- **Logged pizza detail** — share option on any individual logged pizza entry

---

### Background image

- The pizza photo from the selected bake log entry is the canvas
- If no photo was logged, offer a plain cream (`F5F1E8`) background as fallback

---

### Overlay blocks

The user toggles which blocks appear. Each block is white solid text on a grey box with opacity (think: frosted label, not a card). Available blocks:

| Block | Content | Emoji |
|---|---|---|
| Style & method | e.g. "Neapolitan · Biga" | — |
| Formula | Hydration %, ball count × weight, salt %, yeast type | — |
| Flour blend | Name of saved flour blend | 🌾 |
| Preferment | Name of preferment | relevant to type (e.g. 🫧 for poolish, 🍞 for biga) |
| Process | Name of saved process | 📋 |
| Session notes | Star rating, bake time, oven temp, user notes from the log | — |

- **Exception: the Formula block must NOT show the buffer (dough loss factor)** — buffer is a production detail. The social card shows the clean formula only.
- Blocks that have no data (e.g. no preferment on a direct method recipe) are hidden from the toggle list entirely

---

### Arrangement

- Default layout: blocks stack in the lower third of the image
- **Bonus (if feasible):** user can drag each block freely over the photo to reposition; last position remembered within the session

---

### Visual style

- Block background: `Color(.systemGray).opacity(0.55)` or similar — visible but not overwhelming
- Text: white, monospaced, same font family as the rest of the app
- Block corners: `cornerRadius(6)` — consistent with app chip style
- No gold accent in the share image — keep it neutral so it reads on any photo

---

### Output

- "Share →" renders the composed image and opens the iOS share sheet (`ShareLink` / `UIActivityViewController`)
- User can save to Photos, share to Instagram, Messages, copy to clipboard, etc.
- The rendered image is not saved inside the app — it's a one-time export

---

**Deferred until:** social/sharing feature is actively scoped for development.

---

## Design Principles (established through the build)

- **Plain word up top, descriptor below** — "Buffer" / "dough loss factor", "Kneading" / "gluten development"
- **Educational, not prescriptive** — the app teaches through labels and prompts, not locked rules
- **Sliders for exploration, fields for precision** — sliders show the range and concept; tappable fields let you be exact
- **Warnings, not blocks** — the app surfaces ordering issues and timing conflicts but lets you proceed
- **Session is a guest, recipe is the host** — pre-flight overrides are session-only; the recipe stays clean
- **Post-bake is a landing, not a debrief** — photo, quick visual, done. The log captures the reflection.
- **Light = welcoming, mono = technical** — home screen is warm; session and recipe screens are precise
