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

---

## Notes on Claude's Tendencies

- Claude will suggest rather than assume on naming, copy, and architecture — expect tables with options
- Claude defaults to queuing when in doubt about scope
- Claude tracks design principles established through the build and applies them to new decisions
- Claude will flag when a new request conflicts with a prior decision
- Claude does not re-explain decisions already made unless asked — previous context is carried

---

*This log was started in May 2026 during the v0.4 build pass.*
