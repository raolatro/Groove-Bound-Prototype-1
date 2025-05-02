# Groove Bound – Prototype Framework Rules

This file is the single authority for building **Groove Bound** in its first playable form.  
Every agent must follow these rules exactly and log their actions.

---

## 1. Purpose & Scope
1.1 Define how Groove Bound’s prototype is organised, coded, tested, and debugged.  
1.2 Cover workflow, folder layout, coding style, data files, debug tools, and gameplay systems.  
1.3 Lock down every current requirement while leaving hooks for future features.

---

## 2. Core Principles
2.1 Ask first, change after – propose improvements, wait for approval.  
2.2 No hard‑coding – every tunable number or string lives in `settings.lua`; every file location lives in `paths.lua`.  
2.3 Desktop‑first – resize gracefully but ignore mobile specifics for now.  
2.4 Fail‑fast, fix‑fast – surface errors early; correct them unless told otherwise.  
2.5 Patch, don’t push – agents output diff files or clear instructions; the owner runs Git and tests the game.  
2.6 Readable code – comment why, not just what; keep functions small.  
2.7 One switch for every debug visual – global booleans drive all hit‑boxes, radiuses, and overlays.  
2.8 Continuous logging – write all run‑time events to `logs/runtime_<date>.txt` as described in §15.

---

## 3. Roles & Responsibilities
| Role | Groove‑Bound Duties | Output Folders |
|------|--------------------|----------------|
| Coding Agent | core gameplay modules, systems, unit tests | `src/core`, `src/systems`, `tests` |
| UI Agent | HUD, menus, debug overlays | `src/ui` |
| Data Agent | weapon/enemy/power‑up tables | `src/data` |
| Docs Agent | keep this framework, produce docs | `docs` |

---

## 4. Workflow
4.1 Ticket or prompt created.  
4.2 Agent reviews this framework, asks clarifying questions.  
4.3 Draft solution; seek approval for behaviour changes.  
4.4 Provide patch diff or numbered file edits.  
4.5 Self‑test with asserts, debug display, and log output.  
4.6 Owner applies patch, launches Groove Bound manually, and merges.

---

## 5. Folder Layout (Groove‑Bound Specific)
groovebound/  
&nbsp;&nbsp;src/  
&nbsp;&nbsp;&nbsp;&nbsp;core/        state_stack.lua, event_bus.lua, settings.lua, paths.lua  
&nbsp;&nbsp;&nbsp;&nbsp;systems/     spawner.lua, damage_system.lua, xp_system.lua, upgrade_manager.lua, boss_manager.lua  
&nbsp;&nbsp;&nbsp;&nbsp;ui/          block_grid.lua, hud_widgets.lua, levelup_modal.lua, pause_menu.lua,  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;debug_display.lua, tuning_panel.lua  
&nbsp;&nbsp;&nbsp;&nbsp;data/        weapons.lua, enemies.lua, rarities.lua, globals.lua  
&nbsp;&nbsp;&nbsp;&nbsp;save/        build_state.lua  
&nbsp;&nbsp;assets/  
&nbsp;&nbsp;&nbsp;&nbsp;placeholders/  (dummy PNGs, sounds, test font)  
&nbsp;&nbsp;logs/          runtime_YYYY‑MM‑DD.txt, error_YYYY‑MM‑DD.txt  
&nbsp;&nbsp;tests/  
&nbsp;&nbsp;docs/  
&nbsp;&nbsp;web-build/

---

## 6. Coding Standards
6.1 Two‑space indent, 120‑char line length.  
6.2 Module hooks: `init`, `update(dt)`, `draw()`, `debug()`.  
6.3 Wrap risky IO in `pcall` or `assert`.  
6.4 No global variables outside `settings`, `paths`, or explicit singletons.  
6.5 Call `Debug.log(tag, message)` for every significant state change.

---

## 7. Data‑Driven Config
### 7.1 settings.lua (excerpt)
globals = {  
&nbsp;&nbsp;run_duration      = 60,  
&nbsp;&nbsp;boss_hp           = 1000,  
&nbsp;&nbsp;xp_levels         = {50,150,300,500,800,1200},  
&nbsp;&nbsp;max_weapon_slots  = 4  
}

debug_display = {  
&nbsp;&nbsp;max_rows   = 20,  
&nbsp;&nbsp;ttl_secs   = 20,  
&nbsp;&nbsp;font_size  = 8,  
&nbsp;&nbsp;font_color = {1,0,0,1},  
&nbsp;&nbsp;bg_color   = {0,0,0,0.4}  
}

debug_tune = {  
&nbsp;&nbsp;enemy_spawn_rate = {value=1.0,min=0.1,max=3.0,step=0.1},  
&nbsp;&nbsp;player_damage    = {value=1.0,min=0.5,max=5.0,step=0.1},  
&nbsp;&nbsp;player_speed     = {value=1.0,min=0.5,max=2.0,step=0.1},  
&nbsp;&nbsp;luck_multiplier  = {value=0,min=-50,max=50,step=5}  
}

### 7.2 paths.lua (excerpt)
root     = love.filesystem.getSourceBaseDirectory()  
sprites  = root.."/assets/sprites/"  
audio    = root.."/assets/audio/"  
fonts    = root.."/assets/fonts/"

### 7.3 data tables
* weapons.lua – ten levels per weapon with damage, fire_rate, etc.  
* enemies.lua – hp, speed, damage, xp, coins, colour.  
* rarities.lua – tier, weight, colour.  
* globals.lua – mirrors `settings.globals` for hot‑reload.

---

## 8. UI & Grid Rules
8.1 Use `BlockGrid.unit` (default 16 px) for all placement.  
8.2 Recalculate unit on resize: ≥1280 → 16, 800‑1279 → 12, <800 → 8.  
8.3 Screens use grid positions only; no magic pixel offsets.

---

## 9. Debug Display
9.1 Fixed top‑left overlay; shows the last `debug_display.max_rows` events.  
9.2 Background colour and font pulled from `settings.debug_display`.  
9.3 Messages fade after `debug_display.ttl_secs`.  
9.4 API: `Debug.log(tag, message)`, `Debug.update(dt)`, `Debug.draw()`.  
9.5 Never log per‑frame events; only state changes.

---

## 10. Gameplay Systems
| System | Purpose | Key Events |
|--------|---------|------------|
| XPSystem | Track XP, emit `PLAYER_LEVEL_UP` | `PLAYER_LEVEL_UP` |
| UpgradeManager | Pause world, show Level‑Up Panel, apply card | `CARD_PICKED` |
| Spawner | Spawn waves until boss time; pauses during boss | `WAVE_START`, `ENEMY_SPAWNED` |
| BossManager | Spawn boss at `run_duration` | `BOSS_SPAWN`, `BOSS_DOWN` |
| DamageSystem | Handle hits, deaths, XP/coin drop | `ENEMY_KILLED`, `PLAYER_HIT` |
| StatusEffects | Handle buffs/debuffs | `STATUS_APPLIED`, `STATUS_EXPIRED` |

---

## 11. Level‑Up Panel
11.1 Opens only when `PLAYER_LEVEL_UP` fires.  
11.2 Shows three upgrade cards.  
11.3 Rarity weights come from `rarities.lua`.  
11.4 Buttons: Choose, Reroll (costs coins), Skip.  
11.5 Log choice with `Debug.log("LEVEL", "Picked "..cardName)`.

---

## 12. Hit‑Box & Placeholder Rules
12.1 Collisions use invisible shapes; placeholders draw on top.  
12.2 Colours: Blue = XP, Gold = coins, Red/Orange = enemies, Grey = hit‑boxes.  
12.3 Toggle all with `settings.debug_show_hitboxes`.

---

## 13. Testing & QA
13.1 Unit tests in `tests/`; each new system needs one.  
13.2 Headless run mode optional later.  
13.3 Screenshots of debug display plus log file entries form bug reports.

---

## 14. Future Hooks (Stub Only)
* Meta‑shop (`meta_shop.lua`) – locked.  
* Beat‑sync mechanics (`beat_timer.lua`) – disabled.  
* Save/Load beyond run snapshot.

---

## 15. Continuous Log Files
* **runtime_YYYY‑MM‑DD.txt** – append text lines from `Debug.log(tag, message)` at runtime.  
* **error_YYYY‑MM‑DD.txt** – write uncaught errors and stack traces.  
* Coding Agent must create a new `debug_log.txt` with the Debug log text from the game run.
* Save it in the `logs` folder with the name `debug_YYYY‑MM‑DD-HHMMSS.txt`.

---

Last updated 2025‑05‑03.  
All Groove Bound agents must read this file fully, confirm understanding, and obtain consent before editing code.