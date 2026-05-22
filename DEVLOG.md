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

## v0.9.2 — Font Setup + Build Fixes
*Fonts registered, build errors resolved*

**What shipped:**

*Fonts added to project:*
- 5 font files placed in `Fonts/` group in the Xcode project:
  - `Fraunces_72pt-Regular.ttf` (PostScript: `Fraunces72pt-Regular`)
  - `PlusJakartaSans-Light.ttf`, `PlusJakartaSans-Regular.ttf`, `PlusJakartaSans-Medium.ttf`, `PlusJakartaSans-SemiBold.ttf`
- All registered in `Impasto.xcodeproj/project.pbxproj` — PBXFileReference, PBXBuildFile, PBXResourcesBuildPhase, Fonts group
- `INFOPLIST_KEY_UIAppFonts` added to both Debug and Release build configs (space-separated filenames)
- Font ledger added to `Shared/ImpastoStyle.swift`:
  - `Font.fraunces(_ size:)` — Fraunces72pt-Regular (display/headline serif)
  - `Font.jakarta(_ size:, weight:)` — accepts `.light / .regular / .medium / .semibold`

*Build errors fixed:*
- `Shared/FillerPaper.swift` was on disk but missing from the Xcode project — added via pbxproj (PBXFileReference, PBXBuildFile, Sources phase, Shared group)
- `Views/ImportRecipeView.swift` — added to project via Xcode Add Files dialog
- `Views/LiveSessionView.swift` — `.onChange(of: vm.currentIndex)` was dangling after the closing `}` of an `if` block inside a `@ViewBuilder`, causing "instance member 'onChange' cannot be used on type 'View'". Moved to the outer `VStack` in `timerBlock`
- `Views/StandaloneBuilders.swift` — `ProcessCardRow` call was missing `onInsertBefore:` and `onInsertAfter:` parameters added in v0.9.1. Both added with the same insert-and-reindex pattern used in `ProcessScriptStepView`

**Still to do:**
- Apply font ledger across the app — swap `.system(design: .monospaced)` and `.system(design: .serif)` calls for `.jakarta()` and `.fraunces()` respectively
- Delete `ViewModels/PostBakeView.swift` stale duplicate from disk (not in the project, just clutter)

---

## v0.9.1 — Polish & Power-User Features
*Keyboard done button, step alarms, timestamps, filler paper in wizard, import/export, session process editor*

**What shipped:**

*Keyboard Done button:*
- `keyboardDoneButton()` View extension in `ImpastoStyle.swift` — adds a "Done" button to the keyboard toolbar across all numeric inputs; dismisses first responder via `UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), ...)`
- Applied to `PreFlightView` and `WizardContainerView` (covers all wizard steps)

*Live session step alarm:*
- Bell icon on timed steps — tap to schedule a `UNUserNotificationCenter` local notification at the moment the step countdown hits 0
- Requests `.alert`, `.sound`, `.badge` permissions on first tap; gracefully no-ops if denied
- Bell fill / bell outline toggles scheduled state; auto-resets on step advance
- Cancel notification on tap-to-dismiss or step advance via `removePendingNotificationRequests`

*Step wall-clock timestamps in session log:*
- `SessionViewModel` gains `sessionStartDate: Date?` (set on first `start()` call) and `stepCompletionDates: [UUID: Date]` (set on each `completeCard()`)
- `SessionLogView` shows wall-clock start time per step: step 0 uses `sessionStartDate`; step N uses completion date of step N-1
- Both fields added to `SessionSnapshot` — survive app kills and restores

*Filler paper theme — wizard:*
- `WizardContainerView` wraps all step content in `ZStack` with `RuledPaperBackground()`; nav bar tinted `#8AAEC8`; `FillerPaperHeaderBand` via `.safeAreaInset(edge: .top)`
- All 10 wizard step views: `.scrollContentBackground(.hidden)` + `.listRowBackground(Color.clear)` on standard sections
- Special-tinted rows (D2B96A status rows, orange/yellow warnings) retain their existing backgrounds

*Import Recipe:*
- `ImportRecipeView` — two-screen flow: paste JSON text or browse `.json` file → preview (Overview, Formula, Process sections) → "Save to Library →"
- `JSONDocumentPicker` wraps `UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: true)`
- Always assigns fresh `UUID` and clears `bakeLogs` on import — no ID collisions, no history bleed
- `↑ Import Recipe` button on home screen wired up (was a no-op placeholder)

*Recipe export:*
- `ShareLink` in `RecipeDetailView` toolbar — encodes recipe as JSON string, strips `bakeLogs` before export
- Export + Import are the symmetric pair: export from Recipe Detail, import from Home Screen

*Review & Edit Process in PreFlight:*
- "Review & Edit Process" button in `summarySection` opens `SessionProcessEditorSheet`
- Shows all enabled/filtered process cards with editable duration fields; overridden values highlighted gold
- "Reset all to recipe defaults" clears overrides
- Overrides stored as `[String: TimeInterval]` in `PreFlightData.sessionStepDurationOverrides` — session-only, recipe untouched
- Applied in `SessionViewModel.init()` after card filtering

*Fork carry actual times:*
- `BakeLogDetailView.forkedRecipe()` iterates process cards, looks up matching title in `log.actualStageDurations`, applies `max(10, actual)` as `customDuration` — 10s floor prevents zero-duration cards

*Seed v6:*
- Default bulk fermentation changed from 12h → 8h (more realistic home schedule)
- Seed key bumped v5 → v6; old key cleaned up on launch

*Dev tooling:*
- `Views/Dev/FontPreviewView.swift` — SwiftUI preview for Plus Jakarta Sans + Fraunces across weights in Stesura colors (delete before shipping)
- `Views/Dev/font-preview.html` — browser-based font preview with live text input and In Context tab; loads fonts from local paths via `@font-face` (delete before shipping)

**Key design decisions:**
- Import uses the existing `Recipe: Codable` struct as the wire format — no separate schema to maintain. "Export = encode; Import = decode" is the entire protocol.
- Step alarm is opt-in per step, not a setting — you decide at the moment the step starts whether you need a nudge. Auto-scheduling would be presumptuous on long steps like bulk ferment.
- Session overrides live in `PreFlightData`, not in the recipe — consistent with the "session is a guest, recipe is the host" principle already in the design language.
- Timestamps are derived from completion dates, not recorded at start — avoids complexity around pauses and restores; step N's start is definitionally step N-1's end.

---

## Import Recipe — Queued (version TBD)

*Note: JSON export/import shipped in v0.9.1 above. The section below describes a separate manual transcription flow for recipes found online or in books — still queued.*

**Entry point:** From the `↑ Import Recipe` sheet, a second path: **Transcribe a Recipe**. The JSON import path is already live.

---

**Transcribe a Recipe — manual entry flow**

Intent: allow users to enter a recipe they found online or in a book, including volume-based measurements, and convert it into Impasto's weight/percentage-based model. Deliberately simpler than the New Recipe wizard — anyone going through this flow is translating an existing recipe, not designing from scratch.

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

## Session-in-Progress Countdown Preview — Queued (next build)

The `ActiveSessionRow` on the Welcome screen (the "Sessions in progress" card) currently always shows a count-up timer (`vm.elapsed` formatted as `HH:MM:SS`). This should switch behavior based on the current step's duration.

**New behavior — applies regardless of Automatic vs. Manual mode:**

- **If the current process step has an assigned duration** (`vm.currentCard?.duration > 0`)
  - Show **countdown to 0** from the assigned duration: `remaining = duration - elapsed`
  - Format: `MM:SS` while remaining > 0; clamp to `00:00` once reached
  - **If overtime** (`elapsed > duration`): show `+MM:SS` in amber/orange (same overtime treatment as the live session view) — the row already shows "overtime" subtext when `vm.isOvertime`; keep that
  - Rationale: when the live session is minimized, "time until the next thing happens" is more actionable than "time since this thing started"

- **If the current process step has no duration** (`duration == 0`, action-only steps)
  - Keep current behavior: count up from `00:00:00`
  - Action-only steps have no target, so a countdown is meaningless

**Implementation location:** `Views/HomeView.swift` → `ActiveSessionRow.timeString(_:)` and the `Text(vm.isInBakeStep ? timeString(vm.bakeElapsed) : timeString(vm.elapsed))` line.

**Implementation sketch:**
```swift
private var previewTime: String {
    if vm.isInBakeStep {
        return timeString(vm.bakeElapsed)   // unchanged: bake step always counts up
    }
    let target = vm.currentCard?.duration ?? 0
    if target > 0 {
        let remaining = target - vm.elapsed
        if remaining >= 0 {
            return countdownString(remaining)        // "MM:SS"
        } else {
            return "+" + countdownString(-remaining) // "+MM:SS" overtime
        }
    }
    return timeString(vm.elapsed)           // no-duration step → count up
}
```

The color logic (`vm.isOvertime ? .orange : Color(hex: "D2B96A")`) already exists and will continue to work since `vm.isOvertime` is computed the same way (`elapsed > duration`).

**Out of scope for this change:** the in-session LiveSessionView already does countdown-vs-count-up correctly per mode; that stays as-is. This only touches the minimized "Session in progress" preview on Home.

**Testing notes:**
- Start a session, navigate to home → preview should show countdown from step duration
- Let the step go past its duration → preview should flip to `+MM:SS` orange
- Advance to an action-only step (e.g. "Combine") → preview should count up from `00:00:00`
- Enter bake step → preview should count up bake time as it does today

---

## Seed Recipe Tweak — "Perfectly good process" — Queued (next build)

Bump the first kneading step's duration to **10 minutes** (up from current 9 min).

**Location:** `ViewModels/RecipeStore.swift` → `makeSeedProcess()` — the first `.kneading` card (immediately after `.bassinage`).

```swift
// Current
card(.kneading, duration: 9 * 60, note: "This is part 1 of kneading; …")

// Change to
card(.kneading, duration: 10 * 60, note: "This is part 1 of kneading; …")
```

The follow-on `.kneading` (post-salt, 1 min) is unchanged.

**Note on user phrasing:** the request said "10 minutes instead of 8" but the current value in code is 9 minutes (likely the user was remembering an earlier version). Final value is unambiguously 10 — applying the literal target.

**Seed re-application:** because `seedKey` gates re-seeding by version (`impasto_seeded_v5`, etc.), bumping this requires either (a) incrementing the seedKey version so existing users get the new value, or (b) accepting that only fresh installs see the change. Mention which path is preferred when scoping.

---

## Performance — Queued (post-feature-freeze, before v1.0)

The app isn't slow, but it has noticeable jitter on photo-heavy paths
(galleries, full-screen viewer, share editor, history scrolling). Three
concrete bottlenecks compound:

1. **Photos live inline in UserDefaults JSON.** Every `store.update`,
   `addBakeLog`, `updatePizzaEntry`, etc. calls `saveRecipes()` which
   runs `JSONEncoder().encode(recipes)` on the main thread and writes
   the result to UserDefaults. `BakeLog.photos` and `PizzaEntry.photos`
   are `[Data]` stored inline. JSON Base64-encodes each photo (1 MB
   JPEG → ~1.4 MB of Base64 text). A user with 10 bakes × 4 photos
   stuffs 40–60 MB inside one UserDefaults blob. Each save stalls the
   main thread for hundreds of ms.

2. **Image decoding has no cache.** `UIImage(data: photoData)` runs
   inside every `ForEach` of every gallery / row / viewer / canvas, on
   every body re-evaluation. Decode is main-thread.

3. **`RecipeStore` publishes too coarsely.** `@Published var recipes`
   notifies every observer (HomeView, LibraryView, HistoryView,
   BakeLogDetailView, PhotoShareView) when *any* property of *any*
   recipe changes. Combined with #2 → a single tap cascades dozens of
   decodes.

Smaller stuff:
- Saves aren't debounced — typing in a notes field triggers
  persistenceHook → encode-everything per keystroke.
- Encoding + UserDefaults.set is fully synchronous on the main thread.

### The plan (ordered by impact / effort)

#### Pass 1 — Photo extraction (biggest single lever)

Move photos out of the JSON blob and onto disk as individual JPEG files,
referenced by UUID. Existing inline `Data` arrays remain on the models
for backward-compat decoding; new code reads/writes through a
`PhotoStore`.

**New file:** `ViewModels/PhotoStore.swift`
```swift
class PhotoStore {
    static let shared = PhotoStore()
    private let dir: URL  // Documents/photos/

    /// Save a Data blob → return the UUID filename it was stored as.
    func save(_ data: Data) -> UUID
    /// Load a photo by UUID. Returns nil if missing.
    func load(_ id: UUID) -> Data?
    /// Delete by UUID (called from BakeLog/PizzaEntry deletion paths).
    func delete(_ id: UUID)
}
```

**Model changes:**
- Add `var photoIDs: [UUID] = []` to `BakeLog` and `PizzaEntry`
- Keep `var photos: [Data] = []` for backward-compat decoding only
- `displayPhotos` computed property changes to resolve from `photoIDs`
  via PhotoStore, falling back to `photos` for legacy entries

**Migration (run once on app launch):**
- On first launch after this lands, walk every recipe's bakeLogs and
  pizzaEntries. For each entry where `photoIDs.isEmpty && !photos.isEmpty`:
  - Save each `Data` to disk → collect UUIDs
  - Replace `photos = []`, set `photoIDs = [those UUIDs]`
  - Persist once at the end
- Mark `impasto_photos_migrated_v1` = true in UserDefaults to skip
  on subsequent launches

**Write paths to update** (all PhotoStore.shared.save then store UUIDs):
- `PizzaLogView.savePizzaEntry`
- `SessionLogView.save` (aggregatedPhotos → UUIDs → BakeLog.photoIDs)
- `BakeLogDetailView` photo reorder/Make-main (no longer rewrites
  photo data, just reorders UUIDs)
- `PhotoShareView` no-op (read-only consumer)

**Read paths to update:**
- Every callsite that does `entry.photos` or `entry.displayPhotos`
  switches to a helper `entry.photoData(at:)` or `entry.allPhotoData()`
  that resolves from PhotoStore. Returns lightweight `[Data?]` or
  `[UUID]` depending on need.

**Result:** saves drop from 50ms–1s to <5ms because the JSON is now
~1 KB per recipe instead of ~10 MB. UserDefaults stops being abused.
Photos load on demand, not all-at-once at app launch.

#### Pass 2 — Image decode cache

**New file:** `Shared/ImageCache.swift`
```swift
final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSUUID, UIImage>()

    init() {
        cache.countLimit = 200
        cache.totalCostLimit = 50 * 1024 * 1024  // 50 MB
    }

    func image(for id: UUID, loader: () -> Data?) -> UIImage? {
        if let cached = cache.object(forKey: id as NSUUID) { return cached }
        guard let data = loader(),
              let img = UIImage(data: data) else { return nil }
        cache.setObject(img, forKey: id as NSUUID,
                        cost: data.count)
        return img
    }

    func invalidate(_ id: UUID) {
        cache.removeObject(forKey: id as NSUUID)
    }
}
```

After Pass 1 lands, every `UIImage(data: ...)` site switches to
`ImageCache.shared.image(for: photoID) { PhotoStore.shared.load(photoID) }`.

PhotoGalleryView, FullScreenPhotoViewer, ShareCanvasView, BakeLogDetail
photo row, History row thumbnails — all become near-instant on re-render
because the decoded UIImage is reused.

NSCache auto-evicts under memory pressure, so we don't need manual
lifecycle management.

#### Pass 3 — Debounce saves

Add a debouncer to RecipeStore:
```swift
private var savePending: DispatchWorkItem?
private func scheduleRecipesSave() {
    savePending?.cancel()
    let work = DispatchWorkItem { [weak self] in self?.saveRecipesNow() }
    savePending = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
}
private func saveRecipesNow() {
    DispatchQueue.global(qos: .utility).async { [weak self] in
        guard let self else { return }
        if let d = try? JSONEncoder().encode(self.recipes) {
            UserDefaults.standard.set(d, forKey: self.recipeKey)
        }
    }
}
```

Replace every existing `saveRecipes()` call internally with
`scheduleRecipesSave()`. The 250ms quiet-period coalesces bursts (typing,
rapid reorders, slider drags) into one save.

Critical writes (`addBakeLog`, `delete`) should call `saveRecipesNow()`
synchronously after the mutation to guarantee durability.

#### Pass 4 — Background encoding (bundled with Pass 3)

`saveRecipesNow` already moves the encode + UserDefaults.set to a
background queue in the snippet above. Done as part of Pass 3.

#### Pass 5 — Split RecipeStore (lower priority)

Currently one ObservableObject holds recipes, blends, processes,
preferments, folder lists, custom tags, etc. Editing any blend
re-renders any view observing the store.

Split into:
- `RecipeStore` (recipes only)
- `BlendStore` (blends + blendFolders)
- `ProcessStore` (processes + processFolders)
- `PrefermentStore` (preferments + prefermentFolders)
- `LibraryUIStore` (sectionOrder, custom tags — UI-state-only)

Each becomes its own `@StateObject` at the app root, injected via
`.environmentObject` per view's actual dependency.

Largest scope of all the passes (touches every environment injection
site) and the smallest felt impact relative to Pass 1+2. Save for last
or skip entirely if the earlier passes are enough.

### Order of execution

1. Land all queued features first (per-pizza share button if added,
   any remaining v0.9.x polish, etc.).
2. Pass 1 in its own commit + manual test on a populated database
   (verify migration runs once, photos still appear everywhere).
3. Pass 2 in its own commit.
4. Pass 3+4 combined in one commit.
5. Pass 5 only if perf still feels lacking — otherwise defer.

### Testing notes

- Test on a real device, not the simulator. The simulator hides
  UserDefaults perf issues because it's running on a Mac with fast disk.
- Profile with Instruments → Time Profiler at least once during each
  pass to confirm main-thread time on the photo-heavy screens drops.
- Verify the migration is idempotent — run the app twice in a row, the
  second launch should skip migration entirely.
- Verify photo deletion path: when a BakeLog is deleted, its photo
  files should be deleted from disk. (PhotoStore.delete on each UUID
  before removing the BakeLog.)
- Verify legacy users (people running the build before Pass 1) get
  their photos migrated without losing any.

### What "felt fast" looks like

- Tapping into a recipe → BakeLogDetailView appears in one frame, no
  hitch as photos load
- Scrolling history with 50+ logs is buttery — currently it stutters
  every few rows as it decodes thumbnails
- Toggling a share block updates the canvas immediately, no decode
  flash
- Typing in a notes field has zero noticeable lag (currently each
  keystroke triggers a 50–200ms save)

---

## Social Photo Builder — Queued for next session (v0.9.x polish)

Three small additions to the now-working share editor:

### 1. Tap a text block to cycle its text alignment

Currently every block's body text is `.multilineTextAlignment(.center)`. User wants to cycle: **center → left → right → center** by tapping the block (not the drag handle).

**Implementation:**
- Add `var alignment: TextAlignment = .center` to `ShareBlock` (model)
- Apply via `.multilineTextAlignment(block.alignment)` in the tile's body Text
- Add a `.onTapGesture` to the tile body (not the resize handle). Must NOT conflict with the existing DragGesture — `.onTapGesture` and `DragGesture` already coexist in SwiftUI without help, but if there are issues, use `.simultaneousGesture(TapGesture()...)`.
- Tap → bump alignment to the next value:
  ```swift
  switch editor.blocks[index].alignment {
  case .center:  editor.blocks[index].alignment = .leading
  case .leading: editor.blocks[index].alignment = .trailing
  case .trailing: editor.blocks[index].alignment = .center
  default:        editor.blocks[index].alignment = .center
  }
  ```

**Note on hAlign:** when alignment is leading/trailing, the title HStack ("FLOUR BLEND") should also align accordingly so the block reads consistent. Use a `var hAlignment: HorizontalAlignment` derived from `block.alignment`.

### 2. Pinch / spread to zoom the photo inside the canvas

The background photo currently uses `.scaledToFill().frame(canvasSize).clipped()` — fills the canvas, crops the overflow. User wants to **pinch in** to zoom out (see more of the photo, possibly letterboxed in cream), and **spread (pinch out)** to zoom in (crop tighter). The photo must stay within the canvas frame (no exposed edges).

**Implementation:**
- Add `@Published var photoZoom: CGFloat = 1.0` to `ShareEditorModel`
- Optional: `@Published var photoOffset: CGSize = .zero` if we also want pan-to-position (probably yes — at high zoom the user wants to choose what's centered)
- In `ShareCanvasView.background`, apply `.scaleEffect(editor.photoZoom).offset(editor.photoOffset)` to the Image
- Add `MagnificationGesture` to the canvas (NOT to the block tiles — they need their own drag handling). Combine via `.simultaneousGesture` so it coexists with block drags.
  ```swift
  MagnificationGesture()
      .onChanged { value in
          editor.photoZoom = max(1.0, min(3.0, value))
      }
      .onEnded { _ in
          // No-op or persist
      }
  ```
- Clamp zoom to `1.0...3.0` so the user can't zoom out past the frame's edges (1.0 = .scaledToFill which fills the canvas, less than 1.0 would leave gaps).
- Add a "Reset zoom" button below the canvas, in the controls section.

**Edge clamping for offset:** at zoom > 1.0, the photo extends beyond the canvas. We want the user to pan within the visible area but not see past the photo's edges. Math:
```swift
let overflowX = (canvasW * zoom - canvasW) / 2
let overflowY = (canvasH * zoom - canvasH) / 2
photoOffset.x = clamp(photoOffset.x, -overflowX, overflowX)
photoOffset.y = clamp(photoOffset.y, -overflowY, overflowY)
```

### 3. Add a "Recipe name" block

Currently there's no block for the recipe's name itself (Style & Method shows `"Neapolitan · Biga"` but not `"My Best Margherita"` or whatever the user named it).

**Implementation:**
- Add `.recipeName` case to `ShareBlockType` (with `nil` emoji, like all others)
- In `ShareBlockExtractor.blocks(for:recipe:scope:)`, prepend or append a block:
  ```swift
  out.append(ShareBlock(
      type: .recipeName,
      title: "Recipe",                  // small caps title above
      body: recipe.name,                // the recipe's name
      enabled: false,                    // default OFF; user toggles on
      position: CGPoint(x: 0.5, y: y)
  ))
  ```
- Consider: should the recipe-name block default to ENABLED? The user implied they want it as a toggle, suggesting OFF by default. Confirm at implementation time.
- Decide ordering — probably first in the block list so it appears prominently in the toggle list (and visually at the top of the default stack on canvas).

### Trigger conditions for next session

All three are small (each ~30-50 lines). Land them as separate commits so each can be tested independently. No DEVLOG / scope changes needed — just code.

---

## Social Photo Builder — Shipped (v0.9.x)

Initial build wired across three entry points: SessionLogView (mid-session
"How'd it go?" — uses a preview BakeLog built from current in-memory
state), BakeLogDetailView (saved history, toolbar gear), and HistoryView
(per-log "Share this session →" link under each section).

Implementation lives in `Views/Sharing/PhotoShareView.swift`:
- `ShareAspect` enum (1:1, 4:5, 9:16, native) — segmented picker in editor;
  360pt preview × 3× scale = 1080px on long side for IG-friendly export
- `ShareBlock` + `ShareBlockExtractor` — derives content from
  BakeLog/Recipe/scope. Blocks with no underlying data are omitted;
  Formula block excludes buffer per spec
- `ShareCanvasView` — composable view used for both editor preview AND
  ImageRenderer rasterization. Watermark "Baked with **Stesura**"
  ("Baked with" de-emphasized, "Stesura" bold) pinned bottom-right
- `DraggableShareBlock` — DragGesture with dragOrigin snapshot, clamped to
  6%–94% of canvas. Position remembered for the session
- `PhotoShareView` — full editor with aspect picker, scope picker
  (whole-session vs per-pizza), block toggles, drag-to-reposition,
  PhotoPicker fallback for no-photo bakes, ImageRenderer + iOS share
  sheet export via UIActivityViewController

Per the v1 decisions:
- Stars render as ★★★★☆ glyphs (no numeric)
- Preferment block has no emoji (other emoji blocks: 🌾 flour, 📋 process)
- Save-to-Photos path skipped; iOS share sheet handles it natively
- No-photo bake: PhotosPicker prompt, photo not persisted back to bake

Per-pizza scope: PhotoShareView accepts `scope: ShareScope` at init; if
the BakeLog has pizzaEntries, an in-editor segmented picker lets the
user re-scope between whole-session and any specific bake. Block content
re-derives via `.onChange(of: scope)`.

Not yet wired:
- PizzaDetailView's own Share button (sharing a single pizza directly
  from its detail sheet). Users can currently achieve the same result
  via session share + "Bake #X" scope picker. Trivial to add later by
  threading `log` + `recipe` through PizzaDetailView's init.

---

## Original Spec (kept for reference)

A photo-based share tool. The user selects a pizza photo (from a logged bake) as the background, then superimposes toggleable recipe info blocks over it. Output is a shareable image via the iOS share sheet.

---

### Entry points

Three ways to reach the photo builder:

1. **Session end ("How'd it go?" view)** — a third button sits alongside "Save to History" and "↩ Exit Session": **"Share this session →"**
2. **History view** — "Share" buttons pinned at the top of the view, always visible
3. **Logged pizza detail** — share option on any individual logged pizza entry

---

### "Share this session" flow (from session end)

When tapped from the session end view, the user is presented with two paths:

**Share to device (save locally)**
- Automatically selects the background photo: main session photo if one was taken; otherwise the first logged pizza photo; otherwise cream fallback
- Pre-toggles default overlay blocks on: Style & method + Formula
- Opens the photo builder with defaults already applied — user can adjust blocks or arrange before exporting
- Export saves directly to the Photos app (no share sheet required for this path)

**Share to social**
- Same auto-photo selection and default block pre-toggle as above
- Export opens the full iOS share sheet — Instagram, Messages, copy to clipboard, etc.

The user can also go into the full editor from either path to toggle/arrange blocks before exporting.

---

### Background image

- The pizza photo from the selected bake log entry is the canvas
- Auto-selection priority (for session-end share): main session photo → first logged pizza photo → cream (`F5F1E8`) fallback
- In History / logged pizza entry flows, the photo from that specific log entry is pre-selected

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

### Branding watermark

**Always present on every exported image — not toggleable, not removable.**

- Impasto name + logo mark in one corner (bottom-right default)
- Font: obvious but non-intrusive — small enough to not compete with the photo or overlay blocks, large enough to be clearly legible
- Style: white text, same monospaced font as the rest of the app, no background box (floats directly over the image)
- Applies to all images produced by the photo builder regardless of entry point

---

### Output

- "Share →" renders the composed image and opens the iOS share sheet (`ShareLink` / `UIActivityViewController`)
- "Save to Photos" saves directly without the share sheet (device-local path)
- The rendered image is not saved inside the app — it's a one-time export
- Implementation note: use `ImageRenderer` (iOS 16+) to rasterize the composed `SwiftUI.View` to a `UIImage`

---

### Tap-to-fullscreen + "Make main?" cover picker (Queued, ships with social sharing)

A lightweight cover-picker UX to pair with the social photo builder, so users can curate which photo represents a bake / session before exporting.

**Two contexts, same interaction:**

1. **Bake history detail** (`BakeLogDetailView` "As Baked" tab — and any per-bake photo gallery, e.g. `PizzaDetailView`)
   - Tap any photo in the gallery → opens a full-screen viewer
   - Off to the side (corner button or trailing toolbar): **"Make main?"**
   - Tap → that photo becomes the bake's main thumbnail (moves to index 0 in `BakeLog.photos`, with legacy `photoData` kept in sync via the same pattern already used by drag-reorder)

2. **Session review** (`SessionLogView` "How'd it go?" — the aggregated session gallery added in the multi-photo pass)
   - Tap any photo → full-screen viewer
   - **"Make main?"** button → that photo becomes the session cover (moves to index 0 in `aggregatedPhotos`, which then flows into `BakeLog.photos` on save)

**Why "Make main?" and not "Set as cover":**
- Reads as a question — matches the Stesura voice (educational, not prescriptive)
- The drag-to-reorder gallery already lets power users drag to position 0 — this tap-flow is the discoverable alternative for users who don't think to drag

**Implementation sketch:**
- Reuse `PhotoGalleryView` thumbnails as tap targets — wrap each tile in a `Button` action that opens a `FullScreenPhotoViewer` sheet, passing the photo and current index
- `FullScreenPhotoViewer`:
  - Image fills the screen (aspect-fit, black background)
  - Top-trailing toolbar: **Done** to dismiss
  - One side button (probably trailing toolbar or floating bottom-right): **"Make main?"** — disabled when index == 0
  - Optional swipe-between-photos (TabView with `.tabViewStyle(.page)`)
- On confirm: mutate the binding (`photos.move(fromOffsets: [idx], toOffset: 0)`) — the existing PhotoGalleryView binding setter already handles persistence (store.updateBakeLog for history, aggregatedPhotos for session)

**Ties into:** the Social Photo Builder above — once a user has picked a "main" via this flow, the share feature's auto-photo selection (main session photo → first pizza photo → cream fallback) uses that explicit choice as the highest-priority source.

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
