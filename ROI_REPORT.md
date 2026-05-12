# Impasto — Build Cost & ROI Report
*Claude vs. Traditional iOS Development Agency*
*Updated May 2026 — v0.7*

---

## What Has Been Built

### Shipped (v0.1 → v0.7)

**Data models (15+):**
Recipe, FlourBlend (with FlourComponent, Additive), ProcessCard, BakeSetup, BakeLog, SessionViewModel, SessionManager, PrefermentRecipe, PreFlightData, Timeline, SavedProcess, SavedPreferment

**Views (30+):**
HomeView, MainTabView, LibraryView, HistoryView, RecipeDetailView, PreFlightView, IngredientsChecklistView, LiveSessionView, PostBakeView, PizzaLogView, SessionLogView, WizardContainerView + 10 wizard step views + 3 standalone builders + 3 library pickers + supporting sub-views and sheets

**Features:**
- 10-step recipe wizard: validation, review mode, jump-to-step editing, edit/fork pre-population with `WizardMode`
- Flour blend builder: 14 flour types, additives, live % validation, locked Next until 100%
- Process card system: drag-to-reorder, per-card duration (all types), per-card settings, order warnings, locked cards
- Bake method setup: multiple concurrent methods, temperature units, surface temps, electric pizza oven
- **Session architecture**: `SessionManager` owns live `SessionViewModel` instances; sessions survive view dismissal; hide and resume from home screen
- Live session: back navigation (restores prior elapsed), overtime counter (orange count-up), long-press timer reset, per-step notes, view recipe button
- **Bake flow**: Proceed to Bake → Start Baking → per-pizza log loop → End Baking
- **PizzaLogView**: per-pizza photo, visuals, crust/crumb tags, notes — Return to Baking or End Bake
- Pre-flight (Prep): session mode, preferment status, room temp, weight unit + temp unit selectors, last-minute overrides, ingredient prep checklist
- **IngredientsChecklistView**: checkable per-ingredient rows, flour blend sub-rows, bassinage split, progress counter
- Post-bake: photo, visual pickers, bake time, oven temp
- Session log: rating, crust/crumb tags, notes, planned vs. actual comparison
- Library: 4 sections (Recipes, Blends, Processes, Preferments), swipe delete, edit/fork from recipe detail
- Standalone builders for Flour Blend, Process, and Preferment accessible from home and library
- Save-to-library flows embedded in wizard steps for all three sub-recipe types
- Rename recipe by tapping navigation title
- Splash screen with 3-second hold before UI loads
- GitHub version control with structured commit history

---

## Agency Cost Estimate

### Assumptions
- Mid-size US iOS development shop
- Senior iOS developer: **$175/hour**
- Project manager: **$110/hour**
- QA / testing: **$85/hour**
- Overhead ratio (meetings, emails, sprint planning, documentation): **35%**

### Hours breakdown

| Area | Dev hours | PM hours | QA hours |
|---|---|---|---|
| Architecture, models, data layer | 35 | 8 | 5 |
| 10-step wizard (all interactions + edit/fork) | 65 | 12 | 12 |
| Library, RecipeDetail, standalone builders | 28 | 6 | 6 |
| Pre-flight + IngredientsChecklist | 14 | 3 | 3 |
| Live Session + SessionManager architecture | 50 | 10 | 10 |
| Bake flow + PizzaLogView | 18 | 4 | 4 |
| Post-bake + Session log | 12 | 3 | 3 |
| Bug fix + UX refinement passes | 22 | 5 | 5 |
| Design iteration cycles | 14 | 8 | 2 |
| Specification writing | — | 25 | — |
| Testing + device QA | — | — | 20 |
| **Subtotal** | **258** | **84** | **70** |

**Raw labor cost:**
- Dev: 258 × $175 = $45,150
- PM: 84 × $110 = $9,240
- QA: 70 × $85 = $5,950
- **Raw total: $60,340**

**With 35% overhead (email chains, revision rounds, status calls, sprint ceremonies):**
- **$81,459**

**Realistic range: $65,000 – $95,000**
depending on agency tier, revision cycles, and how well requirements were captured upfront (they rarely are).

---

## Time Estimate

| Phase | Agency timeline | This project |
|---|---|---|
| Requirements gathering | 2–3 weeks | 0 (done in conversation) |
| v0.1 scaffold | 2–3 weeks | ~1 session |
| v0.2 wizard + session | 3–4 weeks | ~2 sessions |
| v0.3 major feature pass | 4–6 weeks | ~3 sessions |
| v0.4 feedback + refinement | 2–3 weeks | ~2 sessions |
| v0.5 library + save-to-library | 2–3 weeks | ~1 session |
| v0.6 edit/fork + session architecture | 3–5 weeks | ~2 sessions |
| v0.7 bake flow + overtime + hide/resume | 2–4 weeks | ~1 session |
| Bug fix cycles | 1–2 weeks | Same session |
| **Total** | **21–33 weeks** | **~4–6 weeks elapsed** |

The agency timeline assumes business-hours-only work, email turnaround (typically 24–48h per round-trip), and the standard compression that happens when requirements change mid-sprint — which they always do.

---

## What You Didn't Pay For

| Line item | Agency cost | Claude cost |
|---|---|---|
| Requirements document | $2,000–5,000 | $0 |
| Each revision round | $500–2,000 | $0 |
| "That wasn't in scope" conversations | priceless | $0 |
| Waiting for business hours | lost time | $0 |
| Sprint planning overhead | baked into rate | $0 |
| PM as translation layer | baked into rate | $0 |
| Design spec ambiguity tax | baked into rate | $0 |

---

## Actual Cost

Claude Code is available as part of Anthropic's subscription plans. At the time of this build:

- **Claude Pro / Max:** ~$20–100/month depending on plan
- **Sessions used to build v0.1–v0.7:** estimated 14–20 substantial sessions
- **Estimated total spend:** **$40–400** depending on plan tier and usage

**Conservative savings vs. agency: ~$65,000 – $95,000**
**Time saved: ~17–27 weeks**

---

## What Claude Doesn't Replace

To be fair:

- **Xcode project setup** — target membership, build settings, signing — still requires a Mac and developer account
- **Device testing** — real hardware testing is still on you
- **App Store submission** — certificates, provisioning, review process
- **Design assets** — icons, splash screens, marketing imagery
- **Human judgment on product direction** — the decisions about *what* to build came from you

These would add cost at an agency too, but they're not zero here either.

---

## The Real Multiplier

The most underrated advantage isn't the cost — it's **iteration speed and fidelity**.

At an agency, changing "Buffer" to "Dough loss factor" and switching it from a % field to a grams field would involve:
- A change request
- A ticket in a backlog
- A sprint slot
- A dev picking it up 3–5 days later
- A review cycle
- A build
- You testing it

Here, it took one conversation message and was shipped in the same session.

That compression — from idea to shipped in minutes rather than days — changes how you design. You stop pre-planning everything because iteration is cheap. You explore more. The product gets better faster.

---

## The Compounding Effect

Something the hourly table doesn't capture: the value compounds as the build gets longer.

By v0.7, Claude carries the design decisions made in v0.1 — why the monospaced font, why additives aren't treated as hydration, why the bake card is separate from process cards, why the session has two modes. Every new feature lands consistently with what came before because the design principles are embedded in the working context, not in a spec doc that went stale in week two.

At an agency, that context lives in people. People leave. Handoffs happen. The spec gets out of date. By v0.7, an agency build would have touched 3–4 developers across the feature history. Here, it's one conversation.

---

*Updated May 2026 — v0.7. Estimates based on US market rates for mid-size iOS development agencies. Your mileage may vary — some agencies are faster, most are slower.*
