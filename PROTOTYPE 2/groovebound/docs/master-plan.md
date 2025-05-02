# Groove Bound – Prototype Master Plan

This document explains, in everyday language, what the first playable version of **Groove Bound** should include and how it should feel.  
It is meant for anyone on the project—designers, artists, or helpers—to understand the goal without digging into code details.

---

## 1. Quick Story (Lore)

**Joe**, a burned-out office worker, stumbles upon the mysterious **Wizard of Groove** busking on the street after a draining day. Chosen to restore rhythm to the universe, Joe is thrust into a cosmic quest across genre-themed planets, each ruled by a legendary musician like **Bob Marley**, **Snoop Dogg**, **Michael Jackson**, and **Jimi Hendrix**. Battling bizarre rhythmless creatures and unlocking powerful musical artifacts, Joe gradually evolves from a rhythmless everyman into a true musician. His mission isn’t fame, but to reignite the universal groove and rediscover the joy that music brings to life.

---

## 2. How a Play Session Works (Prototype Slice)

1. **Start‑up**  
   • Game logo shows briefly while things load.  
   • The title screen appears with three buttons: Play, Options, Quit.  
   • A hidden “Debug” button shows only if debug mode is turned on.

2. **Options**  
   • Players can change multiple options, sound volume, and music volume.  
   • Changes apply right away and are saved.

3. **Character Pick**  
   • Only Joe is available now (others will come later).  
   • Selecting Joe starts the level.

4. **The Run**  
   • Joe drops into a simple landscape arena made of plain tiles.  
   • He moves with the keyboard or a controller stick and shoots in any direction with the mouse or right stick.  
   • Small noise monsters appear in waves and chase him.
   • Each monster killed drops XP gems, which give Joe experience points to level up (XP).

5. **Level‑up Moments**  
   • When Joe’s XP reaches certain milestones (50, 150, 300, 500, etc.), the game freezes and a **Level‑Up Panel** pops up.  
   • The panel shows three upgrade cards in bright colours: new weapons, current owned weapons (leveled up), or passive power-ups. The panel also has a Reroll button, which costs coins, and a Skip button.
   • If a new weapon is selected, it is added to the inventory.
   • If a owned weapon is selected, it levels up.
   • If a passive power-up is selected, it is added to the inventory (separate inventory).
   • Player chooses an option and the game resumes.

6. **Goal of the Run**  
   • After a set run time (start with 1 minute by default for quick testing) the big boss appears.  
   • Joe must defeat the boss to win.
   • If Joe dies first, the run ends in failure and a Game Over menu appears with a Restart button and a Return to Menu button.

7. **After the Run**  
   • A results screen lists time survived, monsters defeated, XP gained, and coins earned.
   • Coins are stored for future permanent upgrades (not built yet).

---

## 3. Weapons and Upgrades (First Batch)

Four weapon categories will exist right away:

| Category | Starter Example | How It Behaves |
|-------|-----------------|----------------|
| Straight‑Shooter | **Power Chord** | Fires quick notes forward. |
| Area Blast | **Bass Drop** | Sends a round shockwave around Joe. |
| Self‑Running | **Drone Tambourine** | A little tambourine circles Joe and hits enemies on its own. |
| Spread Shot | **Snare Scatter** | Fires several notes in different directions at once. |

*Rules*  
• Joe can hold 4 different weapons in the inventory, but never two copies of the same one.  
• Picking a card you already own simply levels that weapon up (stronger damage, larger blast, etc. following the weapon's data table).  
• Each weapon has 10 levels in the prototype, each level adds one type of stat (damage, range, fire-rate, reduce cooldown, number of projectiles, etc.)

---

## 4. Monster Line‑Up

* Small **Static Sprites** – slow, weak, appear in large groups.  
* Small **Feedback Bees** – fast, low damage, keep pressure on Joe.  
* One Boss **Feedback Fiend** – spawns after the run time mark with a big health bar. The boss also drops a special non-common item and extra XP gems.

Each monster type has its own health, speed, damage, XP, and coin reward set in an easy‑to‑edit table.

---

## 5. The Hidden Debug Tools

### 5.1 On‑Screen Logger  
A small translucent box stays in the top‑left corner:

* Shows recent events such as *Level Up reached*, *Boss spawned*, *Player hit*, *Boss defeated*, and so on.  
* Maximum of 20 lines at one time.  
* Each message fades out after 20 seconds. 
* No “every‑frame” spam, only meaningful events.
* Small font size, red colour, and simple layout. These will be used to screenshot and feedback to the dev.
* The values must be editable in the settings file.

### 5.2 Pause‑Menu and Tuning Panel (Debug Only)  
Inside the pause menu, a “Dev Tuning” button appears if debug is on.  
This opens sliders to live‑tweak things like:  

* Enemy spawn rate (0.1× to 3×)  
* Player base damage (0.5× to 5×)  
* Player speed (0.5× to 2×)  
* Luck multiplier (controls overall rarity as well as critical hits)

Changes apply instantly so testers can feel the difference without restarting.

---

## 6. What Can Be Tweaked Easily

All numbers, values, and names live in two simple files:

* **settings.lua** – every tunable value (XP steps, boss health, slider ranges, etc.) is listed here.  
* **paths.lua** – one place that lists where sounds, sprites, and fonts will live later.

Rules: For the entire game building process, we will use the settings file to store all tunable values and the paths file to store all file paths. Do NOT hard code any values at any stage.

---

## 7. Art Placeholders and Hit‑Boxes

* Everything is drawn with basic shapes: rectangles, circles, outlines, simple colours.
* Colour guide:  
  – Blue tones for experience items.  
  – Gold or yellow for coins.  
  – Reds and oranges for enemy shapes.  
  – Grey outlines for hit‑boxes and debug visuals.

* A single switch can show or hide ALL hit‑boxes and radiuses.
* Keep it easy to implement sprite art and sound effects later for all elements of the game.
* When later adding sprites, keep the placeholder shapes for hitboxes and radiuses intact, only add the new sprite on top of it.

---

## 8. Future‑Ready Hooks (but not built yet)

* Permanent upgrade shop between runs.  
* Music‑beat‑synced perks and attacks.  
* Extra characters with unique starting weapons.  
* Longer stages with several bosses.  
* Saving and loading of player progress to disk.