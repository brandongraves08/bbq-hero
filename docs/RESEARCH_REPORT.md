# Smoke & Fire: Technical Research & Architecture Report
*June 2026 — Prepared for Brandon*

---

## 1. Executive Summary

Godot 4 with GDScript is the right engine. Our JSON-driven modular autoload architecture is already following community best practices. The BBQ management sim market has a clear gap: nobody does *serious, realistic* BBQ management — everything is either party chaos or food-service rush. We're building something that doesn't exist.

---

## 2. Engine Decision: Godot 4 + GDScript ✓

### Performance Analysis

| Scenario | GDScript | C# | Verdict |
|----------|----------|----|---------|
| Single engine call (instancing nodes) | Comparable | Slightly slower (marshalling) | GDScript fine |
| Heavy compute (A*, large sorts) | 5-20x slower | Much faster | Not our bottleneck |
| Real-world game script mix | Adequate | Overkill | GDScript wins for simplicity |
| Export size | Small | +30-60MB (.NET runtime) | GDScript wins |
| Editor integration | Native, seamless | Good but occasional friction | GDScript wins |

**Bottom line:** Godot 4.6 bytecode optimizations shrunk the GDScript/C# gap for typical game scripts. Our compute profile is light: thermodynamic curves, simple scoring math, event generation. No pathfinding, no thousands of entities per frame. GDScript is the right call.

**Source**: Godot 4.6 release benchmarks, StraySpark 2026 comparison, academic JCSI paper (2024), community benchmark repos.

### Key Architecture Patterns (Community-Vetted)

1. **Autoload Singletons** — Exactly what we're doing. `GameManager`, `EconomyManager`, etc. Industry standard for management sims.
2. **Tick Manager** — Batch entity updates, don't process in `_process`. Use `WorkerThreadPool` for heavy calculations.
3. **EventBus / SystemBus** — Signals between autoloads for loose coupling. Don't call across managers directly.
4. **Data-Driven JSON** — All game content in `data/*.json`. Confirmed best practice. Enables modding, rapid iteration, no-code design workflow.
5. **State Machine for Game Phases** — Bootstrap → Menu → Gameplay → Summary. Every phase transition is a state change.

**Source**: `godot-genre-simulation/SKILL.md`, Godot official best practices, `sha5b/Godot-ECS-Starter`, `cc4221/GDPackagesv2`.

---

## 3. Management Sim Design Principles (Research Synthesis)

### The Golden Rules

1. **Multiple interconnected resources forcing trade-offs** — Time, fuel, money, reputation, meat inventory. Never a single knob.
2. **Front-load interesting decisions** — Don't make the player wait 4 hours before their first meaningful choice. Early game should be fast, rewarding.
3. **Progressive disclosure** — Don't dump all systems at once. Unlock complexity as reputation/clout grows.
4. **Automation unlocks combat tedium** — Manual fire management is fun at first, but by Act 3 you should have staff and controllers handling it.
5. **Clear milestones** — "First brisket", "First comp win", "Bought the trailer", "First restaurant critic review."
6. **Feedback loops everywhere** — Visual (smoke plume changes with quality), audio (sizzle intensity), UI (temp trend arrows).

### The Phase Transition Pattern (From "Escape Velocity" GDD)

This maps perfectly to our 3 Acts:

```
Act 1: CRAFT SIM   — Resource management, skill mastery
  ↓ PHASE TRANSITION (buy food truck)
Act 2: BUSINESS SIM — Crew, logistics, mobile operations
  ↓ PHASE TRANSITION (buy restaurant)
Act 3: ENTERPRISE SIM — Staff, supply chain, menus, critics
```

At each transition, the *genre* of game you're playing fundamentally changes. Act 1 is about how well YOU cook. Act 2 is about managing a small team. Act 3 is about running a business where you barely touch a smoker anymore.

---

## 4. Market Analysis: BBQ Games Gap

### What Exists

| Game | Type | Rating | Notes |
|------|------|--------|-------|
| BBQ Simulator: The Squad | Party chaos co-op | 81% / 881 reviews | Physics goofiness, not management |
| Cooking Simulator BBQ DLC | First-person cooking | 74% / 43 reviews | Tiny player base. Criticized: repetitive, stressful, shallow |
| Korean BBQ Simulator | Arcade score-attack | Early Access | Physics-based, no management |
| BBQ It (Roblox) | Idle tycoon | 10.7M visits | Offline grinding, no depth |
| Barbecue (Steam) | Co-op party | New | Chaos cooking, not simulation |

### The Gap

**Nobody is making a serious, realistic BBQ management simulation.** Every BBQ game on Steam is either:
- Party chaos (Overcooked-with-meat)
- Arcade cooking (time-attack, score attack)
- Idle clicker / tycoon-lite

No game has:
- Realistic fire management with thermodynamics
- Real BBQ science (stall, bark, smoke ring, wrapping decisions)
- Progressive career from backyard to restaurant
- Actual pitmaster skill expression
- Different cooker types with meaningfully different gameplay

### What Players Complain About

From negative reviews of existing BBQ/cooking games:
- "Repetitive tasks, no variety"
- "Too stressful, no relaxed mode"
- "Shallow mechanics, nothing to master"
- "Limited menu, gets boring fast"

### What Players Want

- Relaxed/casual mode option
- Deeper mechanics, real mastery curve
- More variety in recipes and equipment
- Clear progression with meaningful rewards
- Better tutorials

**Our game addresses every single one of these gaps.**

---

## 5. Architecture Recommendations

### Current Architecture: Already Strong

Our scaffold already has the right patterns:
- 10 autoload singletons for core systems
- JSON data files for all game content
- Signal-based communication between managers
- Phase-based progression (GameManager state machine)
- Data-driven content (add meat/cooker/recipe without code changes)

### Specific Architectural Refinements

#### 5.1 Tick Manager Pattern
Instead of `FireSystem._process()` running every frame, use a centralized tick:

```gdscript
# TickManager (new autoload)
func _process(delta):
    if TimeManager.is_paused:
        return
    tick_time += delta
    while tick_time >= TICK_INTERVAL:  # e.g. 0.5 seconds for simulation ticks
        tick_time -= TICK_INTERVAL
        _simulation_tick(TICK_INTERVAL / 60.0)  # Convert to minutes

func _simulation_tick(delta_min):
    # Fire system updates
    # Meat system updates  
    # Customer satisfaction decay
    # Event checks
```

This prevents scattered `_process` calls and gives deterministic simulation that's easy to debug and replay.

#### 5.2 EventBus for Cross-System Communication

Replace direct cross-manager calls with an event bus:

```gdscript
# Events.gd (new autoload)
var bus: Dictionary = {}

func emit(event_name: String, data = null):
    if not bus.has(event_name): return
    for callback in bus[event_name]:
        callback.call(data)

func on(event_name: String, callback: Callable):
    if not bus.has(event_name): bus[event_name] = []
    bus[event_name].append(callback)
```

Benefits: Systems don't import each other. Adding a new system that responds to "meat_cooked" doesn't touch MeatSystem at all.

#### 5.3 Data Manager with Async Loading

For Phase 3+ when data gets large:

```gdscript
# DataManager (new autoload)
var cache: Dictionary = {}

func load_json_async(path: String) -> Array:
    if cache.has(path):
        return cache[path]
    var result = await _threaded_load(path)
    cache[path] = result
    return result
```

Currently fine with sync loading (our JSON files are small), but architect it for the future.

#### 5.4 Save/Load Enhancement

Our current GameManager.save_game() only saves GameManager state. Extend to:
- EconomyManager: money, daily records, income/expense history
- InventoryManager: all ingredients and equipment
- UpgradeManager: purchased upgrades, skill levels
- ReputationManager: competition history, reviews
- CookerManager: owned cookers, equipped cooker

```gdscript
func save_full_game(path: String = "user://savegame.json"):
    var full_state = {
        "game": GameManager.get_state_dict(),
        "economy": EconomyManager.get_state_dict(),
        "inventory": InventoryManager.get_state_dict(),
        "upgrades": UpgradeManager.get_state_dict(),
        "reputation": ReputationManager.get_state_dict(),
        "cookers": CookerManager.get_state_dict(),
        "version": "1.0",
        "timestamp": Time.get_unix_time_from_system()
    }
    # Write as formatted JSON
```

---

## 6. Development Roadmap (Research-Informed)

### Phase 1: Playable Fire Management (2-3 weeks)

**Goal:** FireSystem + MeatSystem in a loop. No economy yet. Just the feeling of managing a fire.

- FireSystem visualization (thermometer, smoke quality indicator, fuel gauge)
- MeatSystem with one meat (brisket) 
- Simple SmokerControlUI wired to a real FireSystem
- Keyboard controls for vents, fuel, water
- End condition: cook a brisket to proper temp

**Why first:** This is the core differentiator. If the fire management mini-game isn't satisfying, the rest doesn't matter.

### Phase 2: First Full Day (3-4 weeks)

- Economy + inventory + shop
- One gig (neighborhood cookout)
- Day cycle (Prep → Cook → Serve → Evaluate → Downtime)
- Rub crafting from ingredients
- Simple DaySummaryUI

### Phase 3: Progression Loop (2-3 weeks)

- Upgrade system working
- Multiple gigs available, select from a list
- First competition (KCBS scoring)
- Save/load working
- Act 1 complete (backyard phase)

### Phase 4: Food Truck (Act 2)

- Phase transition at reputation threshold
- New cooker types unlock (pellet, gas, drum)
- Crew system (1 employee)
- Mobile events (brewery pop-up, food truck festival)
- Inventory restocking, health inspection events

### Phase 5: Restaurant (Act 3)

- Storefront location
- Full staffing (kitchen, front of house)
- Menu design, pricing strategy
- Supply chain, vendor relationships
- Critic reviews

### Phase 6: Polish & Ship

- Audio (low-fi jazz, sizzle, smoke, crowd)
- Particle effects (smoke quality changes)
- Tutorial system
- Steam integration (achievements, cloud saves)
- Localization

---

## 7. Key Technical Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| Fire simulation feels fake/random | High | Build and test the FireSystem prototype FIRST, before any other systems |
| Economy becomes trivial/grindy | Medium | Spreadsheet-model the economy before coding. Define desired day-to-upgrade ratios. |
| UI complexity explosion in Act 3 | Medium | Progressive disclosure. Each phase only shows relevant UI. |
| Content burnout (making all meat data) | Low | JSON-driven. Community modding possible. Start with 3 meats, expand. |
| Save file corruption on version update | Low | Version-tag saves. Migration functions. |

---

## 8. Design Philosophy: "Hollywood Cooking"

From the Fruitbus dev deep-dive: **"It is the feeling of cooking that is important, not the preciseness of the simulation."**

- The fire doesn't need to run a real thermodynamic equation every frame
- It needs to *feel* like fire management: responsive to vent changes, punishing when neglected, rewarding when mastered
- The stall mechanic doesn't need real evaporative cooling physics — it needs to create that "do I wrap or ride it out?" tension
- Smoke quality should be visually and audibly apparent

**Our FireSystem already follows this principle** — simplified temperature curves with enough variables (intake, exhaust, fuel, water, coal bed health, wood splits) to create meaningful player decisions without being a PhD thesis.

---

## 9. Immediate Next Actions

1. **Prototype the FireSystem** — Create a standalone scene with a FireSystem + SmokerControlUI. Get the feel right.
2. **Wire MeatSystem to FireSystem** — Cook one brisket from cold to done. Does the stall feel right? Is wrapping satisfying?
3. **First playable** — FireSystem + MeatSystem + one gig. Can you cook for a neighborhood event?
4. **Economy spreadsheet** — Before coding dollar amounts, model the Act 1 economy in a spreadsheet.

---

**Sources:** Official Godot docs, `godot-genre-simulation` skill, StraySpark Godot 4.6 analysis, academic JCSI paper (2024), Steam market data via Exa, Fruitbus/Gamedeveloper.com architecture deep-dive, Overcooked design retrospective, GDPackages architecture, multiple community Github benchmark repos.
