# Phase 3 Status

## Technical Overview

- **Framework & Core Systems**: LÖVE2D engine, state manager, event bus, logger, debug overlay, and centralized settings.
- **Game States**: Boot, Title, Character Select, Run (main loop), Pause, and Level-Up modal.
- **World & Arena**: Large 2000×1600 arena with visible borders and constrained movement; smooth camera follow and shake.
- **Player Entity**: WASD movement, mouse aiming, auto-firing weapons, health bar, invincibility frames, knockback, and damage flash.
- **Enemy Entity**: Homing AI, health and damage stats, collision knockback, fade-out on death, and XP gem drops.
- **Spawner System**: Time-based waves, gradual individual enemy spawn at random positions, data-driven wave sizes and intervals.
- **Collision System**: Handles player-enemy, bullet-enemy, and player-gem collisions; applies damage, knockback, and optional debug hitboxes.
- **XP & Leveling**: XP collection, thresholds, `addXP` and `checkLevelUp` methods, level-up events, and upgrade modal.
- **UI / HUD**: Health bar, XP progress bar, timer display, pause menu, and level-up choices.
- **Debug & Tuning**: All parameters in a single settings file; debug overlay shows real-time logs and hitboxes.
- **Outstanding & Next Steps**: Balance testing, UI/UX polish, add sound & visuals, then Phase 4 (boss, advanced features).

## Detailed Summaries

**Framework & Core Systems:**
Under the hood, the game runs on LÖVE2D with a small but powerful framework of tools. A state manager cleanly switches between boot, menus, gameplay, and pause. An event bus lets systems communicate without direct dependencies, and a safe logger with on-screen debug overlays keeps you informed of every internal action. Every tunable value lives in one central settings file for easy adjustments.

**Game States:**
Players progress through a well-defined flow: the Boot state initializes everything, the Title screen presents a Play option, and Character Select lets you choose your avatar. Once you start, RunState takes over, driving the main gameplay loop. Pause and level-up modals interrupt seamlessly, letting you step away or pick upgrades before diving back in.

**World & Arena:**
The playfield is much larger than the visible window (default 2000×1600), enclosed by borders that keep you inside. A camera smoothly follows your character, ensuring you’re always centered while never showing empty space outside the walls. It even adds a shake effect when you take damage to intensify the action.

**Player Entity:**
Your character moves with WASD and aims with the mouse. Weapons fire automatically, so you focus on positioning and strategy. You have hit points and a visible health bar, brief invincibility frames after taking damage, and a subtle flash effect when hit. All aspects—speed, health, fire rate, knockback—are configurable in the settings file.

**Enemy Entity:**
Enemies spawn around you and home in on your position. Each has its own health, speed, and damage stats pulled from settings. On collision, they deal damage, apply knockback, and cause a brief screen shake. When defeated, they fade out and drop an XP gem that floats toward you.

**Spawner System:**
Enemies arrive in timed waves, but instead of overwhelming you all at once, they trickle in one by one at random locations around your character. This keeps the tension high without chaos. Wave sizes and spawn timing are data-driven for instant difficulty adjustments.

**Collision System:**
A dedicated module checks overlaps between players and enemies, bullets and enemies, and player and XP gems. It calculates damage and knockback vectors, fires off camera shakes, and—if debug mode is on—draws color-coded hitboxes so you can see exactly where collisions occur.

**XP & Leveling:**
Collect XP gems to earn points. Once you hit the next threshold, you level up. All XP thresholds, progression curves, and callbacks are defined in settings. Level-up events pause gameplay and open a modal for choosing upgrades before returning you to the fight.

**UI / HUD:**
A clean HUD displays your health, XP progress, and elapsed time. Pausing brings up a simple overlay, and leveling up triggers a centered modal with upgrade choices, keeping the interface minimal and intuitive.

**Debug & Tuning:**
Every key parameter lives in one settings file—arena size, enemy speed, camera smoothness, and more—so you can tweak everything without touching code. A corner debug overlay shows log messages and optional hitboxes, making it easy to verify behavior in real time.

**Outstanding & Next Steps:**
Phase 3’s core systems are complete and fully data-driven. Next steps include thorough playtesting to balance wave timing and damage, polishing UI/UX, adding sound and visual effects, and then moving on to Phase 4 features like a boss encounter or advanced weapon upgrades.
