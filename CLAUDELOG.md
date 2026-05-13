# Impasto — Claude Collaboration Log

A record of how this project has been built with Claude: what communication patterns work, what doesn't, and notes for getting the most out of future sessions.

---

## How We Work

**The loop:**
1. User describes a change, question, or idea
2. Claude implements, clarifies, or queues
3. User confirms, redirects, or says "queue it"
4. Claude tracks queued items in conversation memory

**The queue system** is the most important pattern in this project. Rather than implementing everything immediately — which would create conflicts, rework, and untested code — we separate *deciding* from *doing*. Queue first, batch later.

---

## What Works Well

### "Queue this" as a first-class command
Saying "queue up" or "just queue this for now" signals that Claude should document the intent without touching any code. This prevents premature implementation and keeps sessions focused. The queue summary at any point gives a clean backlog.

**Example:**
> "queue locking 'next' in flour blend view so that it must equal 100% before leaving view"

Claude writes the spec, not the code. Fast, zero risk.

---

### Confirming recommendations with one word
When Claude offers options and makes a recommendation, a single confirmation word is enough to lock it in and move on. No need to restate the choice.

**Example:**
> Claude: "Recommendation: Option A — mandatory locked Combine opener"
> User: "confirm recommend A"

This keeps momentum without losing specificity.

---

### Dumping unorganized feedback all at once
Large batches of raw notes, even if unstructured, work well. Claude organizes them into phases, identifies dependencies, and flags what needs to happen first to avoid rework. The messier the input, the more useful the organization pass.

**Example:**
> "gonna drop a load of feedback in a moment, please summarize into action items:"
> [40 unorganized bullet points]

Claude sorted these into 5 phases ordered by dependency risk.

---

### Asking for suggestions before committing
When unsure of the right direction, asking "what do you suggest?" gets a short table of options with tradeoffs, followed by a recommendation. User picks, Claude implements. Faster than debating in the abstract.

**Example:**
> "for the timer, what's the right approach?" → Claude proposed 3 options → user picked one → scoped immediately.

---

### "Same treatment as X" shorthand
Once a pattern is established, referencing it by name is enough to apply the full pattern to a new context. Claude inherits all the nuance.

**Example:**
> "just like how we made flour blend and process separate recipe types… lets do this same treatment for preferment"

No need to re-explain the save/load/library/wizard-integration pattern. Claude applied all four parts automatically.

---

### Pushing back on terminology / naming
When the user flags that a label "isn't intuitive" or "sounds too technical," Claude offers a table of alternatives with a recommendation and the reasoning. User picks. This has produced cleaner copy than either party would have landed on alone.

**Examples:**
- "Pre-flight" → "Prep / Begin Prep"
- "Method" → "Rise method"
- "v2 suffix" → "— [date]"
- "As baked / edited" → "As baked / Annotated"

---

### Phasing before executing
Before touching any code on large multi-file changes, Claude proposes a phase order based on dependency risk. This has prevented rework on every major pass so far.

**Example:**
> Phase 1 (structural skeleton) must precede Phase 3 (screen by screen) because the wizard step renumbering would have required touching every view twice.

---

### Brief directional inputs
The user's most effective messages are often the shortest. A clear intent + optional constraint is enough.

**Example:**
> "make it so that process steps are locked from ever being moved above it"

One sentence. Full scope derived from context.

---

## What Creates Friction

### Vague open-ended questions without a decision target
"What do you think about X?" without a specific decision to make tends to produce long exploratory answers. More useful: "Should we do X or Y?" or "What's your recommendation on X?"

---

### Revisiting already-decided things mid-session
When a design decision made earlier in a session gets re-opened without new information, it slows things down. The queue system helps here — if something is already queued, flagging it as "update the queue" is faster than re-litigating.

---

### Asking Claude to verify external things it can't see
Asking "does this compile?" or "does this look right in Xcode?" without a screenshot or error message gives Claude nothing to work with. The browser automation tools help when connected, but the Chrome extension has been unreliable in this project.

---

### Very long sessions without a summary checkpoint
Context compresses over very long sessions. Occasionally asking "summarize the queue" or "what have we decided?" keeps the shared understanding fresh and surfaces anything that got muddied.

---

## Communication Patterns by Task Type

| Task type | Most effective input format |
|---|---|
| New feature | One sentence intent + "queue it" or "do it" |
| Bug fix | Describe what you see + what you expected |
| Naming / copy | "Any suggestions?" → pick from table |
| Architecture | "What's the right approach?" → pick from options |
| Large feedback pass | Dump everything, ask Claude to sort it |
| Confirming a recommendation | One word: "confirm", "do it", "sounds good" |
| Deferring | "Queue this", "note for later", "just queue" |
| Phasing | "What order should we tackle these?" |

---

## Session Rhythm That Works

1. **Open** with the most important thing to ship
2. **Dump** any accumulated notes/feedback early — sorting them costs nothing
3. **Queue** everything that isn't today's focus
4. **Confirm** recommendations with a single word when possible
5. **Close** with "summarize the queue" to verify nothing slipped

### Cross-session queue processing
When sessions end mid-queue, the summary system carries the backlog forward cleanly. The next session opens with a full technical briefing — file names, line numbers, what was written vs. what was only planned. No re-explaining needed. The queue just picks up where it left off.

**Example:**
> "keep processing the queue!"

That one message resumed a 15-item backlog spanning 10+ files across 3 different feature areas. Claude recovered full context from the compaction summary and executed without prompting.

---

### Architecture questions get real answers, not deferred answers
When a new feature requires rethinking the architecture (e.g. "how do we keep a session alive after the view is dismissed?"), asking "what's the right approach?" gets a concrete architectural answer with tradeoffs, not a "there are several ways to do this." Claude commits to a recommendation and explains why.

**Example:**
> "how would the hiding and return to home work?"

Claude evaluated 3 approaches (store vm in RecipeStore / SessionManager / view state flag), picked SessionManager as the right separation of concerns, and explained why. Decision made in one message; coded in the same session.

---

### Batching notes and letting Claude organize them
Large unstructured feedback dumps — even mid-session — work better than trying to prioritize yourself. Claude sorts by dependency, identifies what breaks what, and returns a sequenced implementation plan.

**Example from v0.6:**
> "got some notes from this first part i want to share: [14 unstructured observations across 8 different views]"

Claude sorted these into bugs (state persistence), UX fixes (diameter independence), medium features (bake flow per-step notes), and complex features (bake flow, ingredient checklist, session architecture) — with implicit sequencing based on what each thing depended on.

---

### "Notes for future" as a pattern for architecture
When an idea is good but the scope is too large for the current session, saying "note for future" or "queue this" explicitly gets it into the devlog's "Design Principles" or queued section without slowing the current pass. Nothing gets lost; everything gets its time.

---

## Wins: What Claude Made Possible

**Impasto at v0.7 — built in ~6–8 weeks of intermittent sessions**

---

### Things that would have taken weeks at an agency, done in one session:

**SessionManager architecture** — "sessions survive view dismissal" is a non-trivial iOS architecture problem. The right solution (ObservableObject with a sessions array, injected at root, vm ownership separated from the view) was designed, implemented, and shipped in a single session. A typical agency sprint cycle would be: requirements (day 1), architecture review (day 2), implementation (days 3–5), QA (days 6–8). Here: one session.

**WizardMode / Edit/Fork flow** — Pre-populating a 20-field wizard from an existing recipe using Swift's `@State` initialization pattern, with three distinct save behaviors (update in place / save as new / fork), is exactly the kind of feature that creates weeks of back-and-forth on requirements at an agency. Written in one pass.

**Process card system** — Drag-to-reorder, per-card expansion, per-type settings (autolyse mode, bassinage %), order warnings, locked positions, custom titles — this is a full custom UI system. Shipped in v0.3 with no prior spec, driven entirely by conversation.

**Bake flow state machine** — The "Proceed to Bake → Start Baking → Log Pizza loop → End Baking" flow is a mini state machine layered on top of an already running session. Designed from a paragraph of user notes and implemented the same day.

---

### Things that got better because iteration is free:

- "25g per kg" → "~2.5% of total dough weight" (unit-agnostic in one edit)
- Weight/diameter coupling → independence, with estimate hint (two removed bindings + one new computed label)
- Mode state lifting for wizard back-nav: four files, surgical change, no regressions
- Every naming decision (Rise method, Dough loss factor, Proceed to Bake, Proceed →) iterated in conversation, not in a ticket

---

### The compounding effect:

By v0.7, Claude carries the full context of design decisions made in v0.1 — why the monospaced font was chosen, why additives aren't treated as hydration, why the session has two modes, why the Combine card is locked. New features land consistently with what came before because the design principles are embedded in the context, not in a separate document that gets out of date.

That's the real multiplier: not just speed, but coherence across a long build.

---

## What Claude Doesn't Replace (still true)

- Xcode setup, target membership, signing
- Real device testing — the app needs to be launched and clicked through
- App Store submission
- The product instincts that decide *what* to build — every feature decision above came from the user

---

*Updated May 2026 through v0.9.*

---

## Patterns Added in v0.8–v0.9

### Terse bug descriptions that enable surgical fixes
The most efficient bug reports in this project are a single sentence describing what you see + what you expected, with no speculation about cause. Claude diagnoses and implements without needing the user to know why it's broken.

**Examples from v0.9:**
> "when a live session has been left and reentered from the active sessions view, the home button to leave session no longer works"
> "from the 'how'd it go' view, neither save to history or exit session let me leave"

Both bugs were unrelated (one was an observer lifecycle issue, one was a race condition). One-sentence descriptions → diagnosed and fixed without back-and-forth.

---

### "Fix:" as a commit-grade signal
Prefixing a message with "fix:" signals that this is a regression or broken behaviour, not a design request. It scopes the response to diagnosis + repair rather than exploration. Claude treats it as a targeted patch, not a redesign prompt.

---

### Ordering bugs are timing bugs
Race conditions in SwiftUI tend to manifest as "buttons do nothing" or "the wrong thing happens after dismiss." When a button's action includes two state mutations that both have observers, the order matters — `shouldReturnHome = true` must come before anything that drops `sessions.count`, or the guard fires too early. This pattern will recur; the fix is always: arm the guard first, then trigger the drop.

---

### SwiftUI gesture conflicts on NavigationLink rows
`.contextMenu` on a `NavigationLink(destination:)` inside a `List` is not reliable — long-press activates the link's internal press animation and the context menu never fires consistently. The reliable pattern is a leading swipe action (`.swipeActions(edge: .leading)`) which does not conflict with the navigation tap gesture. If a context menu is needed on a non-navigating row, it works fine.

---

### Always-active observers via persistent ZStack wrapper
SwiftUI `onChange` observers only run while the view they're attached to is in the hierarchy. If an observer is on a view that conditionally shows/hides (like a `launch` view that only renders when `showMainApp = false`), it won't fire when the condition is false. Fix: attach the observer to a parent that is always rendered. A top-level `ZStack` wrapping both branches — with the observer on the ZStack itself — is the canonical form for this in SwiftUI.

---

### Two-sheet sequencing via onDismiss
iOS won't present two sheets simultaneously — trying to programmatically set two `isPresented` flags in the same call silently drops one of them. When one sheet must close and a second must open, the correct pattern is:
1. Store the value in a `@State` variable
2. Set `showFirstSheet = false`
3. Use `sheet(isPresented:onDismiss:)` — the `onDismiss` closure fires after the first sheet's dismiss animation completes
4. Set `showSecondSheet = true` inside `onDismiss`

This is now the established pattern for any "close converter → open wizard" type of flow.

---

## Notes on Claude's Tendencies

- Claude will suggest rather than assume on naming, copy, and architecture — expect tables with options
- Claude defaults to queuing when in doubt about scope
- Claude tracks design principles established through the build and applies them to new decisions
- Claude will flag when a new request conflicts with a prior decision
- Claude does not re-explain decisions already made unless asked — previous context is carried

---

*This log was started in May 2026 during the v0.4 build pass.*
