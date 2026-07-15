# Smoke & Fire: The BBQ Master

> A realistic BBQ management simulation — from backyard hobbyist to restaurateur.

Built with **Godot 4** (GDScript). Single-player, simulation-first, data-driven.

---

## Game Overview

Start with a rusty offset smoker in your backyard. Smoke brisket for the neighbors. Win a local competition. Buy a food truck. Build a restaurant empire. Every step introduces new systems to master.

**Core Loop:** Prep → Fire Management → Cook → Serve → Evaluate → Upgrade

---

## Three Acts

### Act 1: Backyard Legend
- Rusty offset smoker, hand tools, family recipes
- Neighborhood cookouts → local competitions
- Prove yourself, earn your first real equipment
- **Win condition:** Win a local competition or build steady catering demand

### Act 2: Food Truck
- Trailer with mounted smoker, propane assist, warming station
- Roaming events — breweries, festivals, fairs
- Crew management (1-2 employees), inventory restocking, health inspections
- **Win condition:** Reputation score high enough to attract a restaurant investor

### Act 3: Brick & Mortar
- Real storefront — location matters (downtown, strip mall, gentrifying side street)
- Full restaurant ops — menus, staffing, supply chain, vendor contracts
- Compete for BBQ championships, James Beard recognition
- **Endgame:** Multiple locations, grand champion titles

---

## Core Systems

### 🔥 Fire & Smoke Simulation
Every smoker is a physics-like system:
- **Temperature curve** — Real-time heat management via vent positions and fuel
- **Fuel types** — Charcoal (briquettes vs lump), wood splits (hickory/oak/pecan/mesquite)
- **Airflow** — Intake/exhaust dampers control burn rate and smoke quality
- **Water pan** — Humidity affects bark and cook time
- **The Stall** — Every large cut hits 150-160°F plateau. Wrap (paper vs foil), spritz, or ride it out?

### 🥩 Meat & Cooking
- **Types:** Brisket, pork butt, ribs (spare/St. Louis/baby back), chicken, sausage, turkey
- **Prep:** Trimming (silverskin, fat cap), brine vs dry brine, rub application
- **Cook metrics:** Internal temp, bark formation, smoke ring, carryover heat on rest
- **Quality grades:** Select → Choice → Prime → Wagyu — affects price and ceiling

### 🏆 Scoring & Evaluation
- **Competitions:** KCBS-style — Appearance (20%), Taste (40%), Tenderness (40%)
- **Customers:** Satisfaction = Cook Quality × Wait Time × Price × Atmosphere
- **Critics:** Unlock in Act 3, affect regional reputation

### 💰 Economy

| Phase | Income | Expenses | Key Upgrade |
|-------|--------|----------|-------------|
| Backyard | Tips, comp winnings | Meat, charcoal, rubs | Better smoker, thermometer |
| Food Truck | Per-plate, gig fees | Meat, fuel, staff, permits | Trailer, 2nd smoker, POS |
| Restaurant | Menu, catering | Lease, payroll, waste | Walk-in, high-end smokers |

### 🧑‍🍳 Skill Tree
**Craft:** Fire Mastery, Trimming, Rub Blending, Sauce Making, Plating, Knife Work
**Business:** Menu Optimization, Staffing, Marketing, Vendor Negotiation, Health Code

---

## Cooker Attribute Ratings

| Cooker Type | Skill Needed | Smoke Flavor | Capacity | Stability | Speed | Prestige |
|-------------|:-----------:|:------------:|:--------:|:---------:|:-----:|:--------:|
| Offset Smoker | 5 | 5 | 4 | 2 | 2 | 5 |
| Pellet Smoker | 2 | 3 | 4 | 5 | 3 | 3 |
| Charcoal Kettle | 3 | 4 | 2 | 3 | 3 | 4 |
| Gas Grill | 1 | 1 | 3 | 5 | 5 | 2 |
| Kamado | 4 | 4 | 2 | 5 | 3 | 4 |
| Drum Smoker | 3 | 4 | 3 | 3 | 3 | 4 |
| Electric Smoker | 1 | 2 | 2 | 5 | 2 | 1 |
| Brick Pit | 5 | 5 | 5 | 1 | 1 | 5 |
| Rotisserie Smoker | 2 | 3 | 5 | 5 | 4 | 3 |

---

## Upgrade Slot System

Each cooker has upgrade slots that modify its behavior:

- **Airflow Slot:** Better vents, chimney extension, fan controller, firebox damper
- **Heat Control Slot:** Gasket kit, insulation blanket, tuning plates, ceramic deflector
- **Monitoring Slot:** Single/multi-probe thermometer, wireless probes, Wi-Fi controller
- **Capacity Slot:** Rib rack, second shelf, hanging hooks, commercial rack system
- **Fuel Slot:** Charcoal basket, pellet hopper upgrade, propane assist, larger firebox
- **Maintenance Slot:** Ash catcher, grease drain, easy-clean grates, weather cover

---

## Modular Content Design

All game content is data-driven via JSON files in `data/`. Add new meats, cookers, fuels, recipes, or events without touching code. Content modules planned:

- **Cooker Packs:** Pellet smoker pack, competition offset pack, regional pit pack
- **Meat Packs:** Whole hog, lamb, fish, game meats
- **Fuel Packs:** Specialty wood varieties, charcoal brands
- **Recipe Packs:** Regional BBQ styles, international grilling
- **Event Packs:** Championship series, holiday specials, catering contracts
- **Location Packs:** Destination maps, international BBQ tour

---

## Architecture

```
bbq-hero/
├── project.godot
├── README.md
├── data/
│   ├── meats.json
│   ├── recipes.json
│   ├── smokers.json
│   ├── fuels.json
│   ├── upgrades.json
│   └── events.json
├── scripts/
│   ├── systems/
│   │   ├── GameManager.gd
│   │   ├── EconomyManager.gd
│   │   ├── ReputationManager.gd
│   │   ├── TimeManager.gd
│   │   ├── FireSystem.gd
│   │   ├── MeatSystem.gd
│   │   ├── InventoryManager.gd
│   │   ├── UpgradeManager.gd
│   │   ├── EventManager.gd
│   │   └── CookerManager.gd
│   ├── data/
│   │   ├── RecipeManager.gd
│   │   └── FuelManager.gd
│   └── ui/
│       ├── MainMenuUI.gd
│       ├── GameUI.gd
│       ├── SmokerControlUI.gd
│       ├── CompetitionUI.gd
│       ├── DaySummaryUI.gd
│       ├── UpgradeUI.gd
│       └── InventoryUI.gd
├── scenes/
│   ├── main_menu.tscn
│   ├── game.tscn
│   └── ui_components/
└── assets/
    └── icons/
        └── game_icon.svg
```

---

## Current Playable State

As of 2026-07-15, the MVP has an end-to-end Act 1 loop:

```text
main menu -> hub -> gig select -> cook -> gig scoring/day summary -> hub
```

What works:
- Fire management: vents, fuel, wood, water pan, smoke quality, temperature trend
- Meat simulation: all meats from `data/meats.json` can be selected/cooked, with internal temp, stall, bark, smoke ring, moisture, and rest
- Gig flow: events from `data/events.json`, active gig context, economy payout, reputation gain, event history
- Visual feedback: fire/flame visualization, smoke and fuel indicators, thermometer widget, meat progress labels
- Scoring: KCBS-style competition scoring and gig/customer satisfaction scoring
- Progression shell: hub, save/load, upgrade shop, phase/reputation tracking

Known next work:
- Add placeholder audio for fire crackle, sizzle, and ambient yard sound
- Add true multi-item cook sequencing for gigs that require several meat categories
- Run in Godot 4 locally; this server does not currently have a Godot binary for headless validation

---

## Phase 1 — MVP (Act 1 Backyard Only)

**Scope:**
- Offset smoker with fire management (vents, fuel, water pan)
- 3 meats: brisket, pork butt, St. Louis ribs
- Rub/sauce crafting from ingredients
- 5 generated neighborhood gigs + 1 local competition
- Basic economy (buy meat at store, sell plates, comp entry fees)
- Clean 2D UI, no crew, no food truck

**Milestones:**
1. ✅ Project scaffold + data definitions
2. ✅ Fire simulation (temp curve, fuel burn, vent mechanics)
3. ✅ Meat cook simulation (internal temp, stall, bark)
4. ⬜ Recipe system (rub blending, sauce making)
5. ✅ Economy + inventory + shop
6. ✅ Gigs (events, difficulty, payout)
7. ✅ Competition system (KCBS scoring)
8. ✅ UI: smoker panel, gig scoring, day summary
9. ⬜ Progression: upgrades + skill tree (Act 1 scope)
10. ⬜ Polish: sound, tutorials, local Godot QA

---

## Development

```bash
# Clone
git clone git@github.com:brandongraves08/bbq-hero.git
cd bbq-hero

# Open in Godot 4
godot project.godot
```

---

## Credits

- **Design:** Brandon / Buckaroo Banzai
- **Engine:** Godot 4
- **Vibe:** Low-fi jazz, golden hour light, sweet smoke
