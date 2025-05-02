# Framework.md  
*A single reference for every AI‑assistant (“agent”) working on this project.*

---

## 1. Purpose & Scope  
Provide one authoritative, generic workflow and style guide for any Lua / LÖVE (or similar) game project.  
Agents must obey all items in this list before writing, changing, or suggesting code.

## 2. Core Principles  
2.1 Fail‑fast, fix‑fast – correct errors immediately unless explicitly told otherwise.  
2.2 Readable code – every new script or substantial edit must include inline comments explaining **why**, not just **what**.  
2.3 Suggest, don’t surprise – propose improvements first, **ask for consent**, wait for approval, then edit.  
2.4 Hands off runtime – agents never launch or hot‑run the engine; the project owner does that manually.  
2.5 No auto‑commits – output patches or instructions only; the owner applies them.  
2.6 Big‑change safeguard – audit and replace obsolete or broken functions/events before merging.  
2.7 Minimum viable footprint – keep changes modular, lean, and testable.  
2.8 Consistency over cleverness – follow existing conventions unless told to evolve them.

## 3. Roles & Responsibilities  
3.1 **Coding Agent** – gameplay code, utilities, debug hooks; outputs under `scripts/` and `tests/`.  
3.2 **Docs Agent** – maintains this framework; outputs Markdown files.  
3.3 **Log Agent** – maintains runtime logs and error traces; outputs under `logs/` as `.txt`.

## 4. Workflow Lifecycle  
4.1 Ticket / prompt created.  
4.2 Agent reviews this framework and **asks clarifying questions** if needed.  
4.3 Draft solution prepared; request approval when code alters existing behaviour.  
4.4 Implement in a **feature branch** patch or diff.  
4.5 Self‑test with debug prints and asserts.  
4.6 Submit patch with concise, template‑based description.  
4.7 Project owner manually runs and reviews build; merges if satisfied.

## 5. Folder & File Architecture (template)  
5.1 `project_root/main.lua`  
5.2 `project_root/conf.lua`  
5.3 `project_root/scripts/` – gameplay modules  
5.4 `project_root/assets/sprites/` – graphics  
5.5 `project_root/assets/audio/` – sound  
5.6 `project_root/assets/fonts/` – typography  
5.7 `project_root/tools/` – helper scripts, shaders  
5.8 `project_root/tests/` – automated checks  
5.9 `project_root/web-build/` – love.js output  
5.10 `project_root/docs/` – design docs (this file, specs, etc.)  
5.11 Use **snake_case** for filenames; **PascalCase** for Lua tables/classes.  
5.12 Legacy or experimental code lives in `scripts/_archive/`.

## 6. Coding Standards  
6.1 Two‑space indent; 120‑character line width.  
6.2 Standard module hooks: `init`, `update(dt)`, `draw()`, `debug()`.  
6.3 Mandatory debug print at game start, level load, and state change.  
6.4 Pure Lua helpers preferred; add LuaJIT/FFI only after profiling.  
6.5 Each new file includes `DEBUG_*` constant and optional `Debug.log()` calls (avoid per‑frame spam).  
6.6 `settings.lua` holds global debug toggles; new debug flags must be registered there.

## 7. Error Handling & Refactoring  
7.1 Wrap risky calls in `pcall` or `assert` with descriptive messages.  
7.2 Log stack traces to `logs/error_<date>.txt`.  
7.3 Before major renames, run a repo‑wide impact scan.  
7.4 Provide backward‑compatibility shims for at least one minor version.

## 8. Asset Pipeline  
8.1 Sprites – PNG, power‑of‑two dims preferred, trim padding, anchor top‑left.  
8.2 Audio – OGG by default; XM/MOD allowed; normalise to –14 LUFS; append BPM in filename.  
8.3 Shaders – `.glsl` files with commented uniforms and hot‑reload flag.

## 9. Logging & Telemetry  
9.1 `logger.lua` with levels `INFO`, `WARN`, `ERROR`; toggle file logging.  
9.2 Optional telemetry: session duration, item picks (no personal data).

## 10. Documentation Style  
10.1 All docs are Markdown in `docs/`.  
10.2 Every doc starts with an “At a glance” summary.  
10.3 Use inline links: `[text](../path/to/file.md#section)`.

---

## 11. Data‑Driven Configuration (Design Knobs)  
11.1 `data/weapons.lua`, `data/passives.lua`, `data/enemies.lua` – static per‑level stats, loaded at boot.  
11.2 `data/rarities.lua` – defines rarity tiers (see §12).  
11.3 `data/globals.lua` – tunable constants (XP curve, base speed, base fire‑rate, etc.); hot‑reload when changed via debug menu.  
11.4 `save/build_state.lua` – runtime snapshot of the current run: owned items, aggregated buffs, RNG state; updated at checkpoints.  
11.5 Agents must **never** hard‑code numerical values; always read from these tables.

## 12. Rarity System  
12.1 Tiers: `common`, `rare`, `epic`, `legendary`; each has `weight`, `color`. 
12.2 Helper API:  
&nbsp;&nbsp;– `Rarity.pick(weighted)` returns tier string.  
&nbsp;&nbsp;– `Rarity.get(tier)` returns colour/fx table.  
12.3 Every item table carries a `rarity` key; UI and drop FX look up via `Rarity.get`.  
12.4 Per‑weapon or per‑drop overrides allowed by adding `rarity_override` in data tables.

## 13. Grid‑First UI & Layout  
13.1 `BlockGrid.lua` manages snap‑to‑grid layout.  
13.2 `unit` defaults to 16 px; recalculated on window resize (desktop > 1280 → 16, tablet 800‑1279 → 12, phone < 800 → 8).  
13.3 Helper functions:  
&nbsp;&nbsp;– `Grid.pos(col,row)` → pixel coords.  
&nbsp;&nbsp;– `Grid.rect(col,row,w,h,anchor)` → bounding box.  
13.4 All HUD and menu widgets must place themselves using `BlockGrid`; no magic numbers.

## 14. Tween Manager  
14.1 API: `Tween.to(obj, {x=100}, 0.3, "outQuad")`.  
14.2 Supported easings: linear, quad, cubic, back, bounce, plus custom curve tables.  
14.3 Sequencing: `Tween.seq( Tween.to(...), Tween.wait(0.1), Tween.call(cb) )`.  
14.4 Group tags let agents cancel related tweens (e.g., `"ui"` group) in one call.  
14.5 Optional dev overlay graphs active tweens when `dev_tuning` is on.  
14.6 Tweens are pooled internally to avoid garbage churn.

## 15. Gameplay‑Logic Modules (current phase)  
15.1 **Spawner** – reads `waves.lua` rows `{time=5, type="bassZombie", count=8, pattern="circle"}`; supports beat‑aligned `beat=` keys.  
15.2 **DamageSystem** – single `applyDamage(target, amount, dmgType, source)`; handles resistance lookup and returns overkill flag.

## 16. In‑Game Debug Tuning Panel  
16.1 Enabled only when `G.globals.dev_tuning == true`.  
16.2 Accessed from Pause → “Dev Tuning”.  
16.3 Scroll‑box lists whitelisted controls:  
&nbsp;&nbsp;– `Enemy.spawn_rate` slider (0.1× – 3×)  
&nbsp;&nbsp;– `Player.base_damage` slider (0.5× – 5×)  
&nbsp;&nbsp;– `Player.speed` slider (0.5× – 2×)  
&nbsp;&nbsp;– `Loot.rarity_bias` slider (‑50 % – +50 %)  
16.4 “Apply & Resume” writes changed values to `data/globals.lua` (optional) and broadcasts `DEBUG_SETTINGS_CHANGED`.  
16.5 UI obeys grid system (§13); appears in its own modal layer.

---

Last updated 2025‑05‑02.  
All agents must read, ask questions for clarity, and obtain consent before editing code.