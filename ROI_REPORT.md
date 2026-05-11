# Impasto — Build Cost & ROI Report
*Claude vs. Traditional iOS Development Agency*
*As of May 2026*

---

## What Has Been Built

### Shipped (v0.1 → v0.4 in progress)

**Data models (11):**
Recipe, FlourBlend, ProcessCard, BakeSetup, BakeLog, SessionViewModel, PrefermentRecipe, FlourComponent, FlourAdditive, PreFlightData, Timeline

**Views (18+):**
HomeView, LibraryView, RecipeDetailView, PreFlightView, LiveSessionView, PostBakeView, SessionLogView, WizardContainerView + 10 wizard step views, supporting sub-views and sheets

**Features:**
- 10-step recipe wizard with validation, linked fields, bidirectional sync, review mode, jump-to-step editing
- Flour blend builder with 14 flour types, additives, live % validation
- Process card system with drag-to-reorder, per-card settings, order warnings, locked cards
- Bake method setup with multiple concurrent methods, temperature units, surface temps
- Live session: clock-anchored timers, auto/manual modes, stage prompts, ingredient reference, pause logging
- Pre-flight with session mode selection, last-minute overrides, preferment status check
- Post-bake capture: photo, crust/crumb visual pickers, oven temp, bake time
- Session log with planned vs. actual time comparisons, pause log, bake results
- Library with recipe rows, tested/untested badges, style labels
- Custom "My Style" pizza style with free-form naming and balanced defaults
- Full dark → light theme with gold accent branding
- GitHub version control with structured commit history
- Copy audit (90+ strings catalogued in Excel)

**Queued (designed, not yet coded):**
Concurrent sessions, clock-based timing, folder system, standalone blend/process/preferment builders, library sections for sub-recipes, edit from library, session review with As Baked / Annotated tabs, save session as recipe, live session notes, Combine locked opener, "Begin Prep" rename pass, and ~25 additional scoped features

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
| Architecture, models, data layer | 25 | 6 | 4 |
| 10-step wizard (all interactions) | 55 | 10 | 10 |
| Library, RecipeDetail, HomeView | 18 | 4 | 4 |
| Pre-flight + Live Session + Post-bake | 38 | 8 | 8 |
| Bug fix iterations (Phase 2 equivalent) | 16 | 4 | 4 |
| Design iteration cycles | 12 | 6 | 2 |
| Specification writing | — | 20 | — |
| Testing + device QA | — | — | 16 |
| **Subtotal** | **164** | **58** | **48** |

**Raw labor cost:**
- Dev: 164 × $175 = $28,700
- PM: 58 × $110 = $6,380
- QA: 48 × $85 = $4,080
- **Raw total: $39,160**

**With 35% overhead (email chains, revision rounds, status calls, sprint ceremonies):**
- **$52,866**

**Realistic range: $40,000 – $60,000**
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
| Bug fix cycles | 1–2 weeks | Same session |
| **Total** | **14–21 weeks** | **~2–3 weeks elapsed** |

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
- **Sessions used to build v0.1–v0.4:** estimated 8–12 substantial sessions
- **Estimated total spend:** **$20–200** depending on plan tier and usage

**Conservative savings vs. agency: ~$40,000 – $60,000**
**Time saved: ~12–18 weeks**

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

*Report generated May 2026. Estimates based on US market rates for mid-size iOS development agencies. Your mileage may vary — some agencies are faster, most are slower.*
