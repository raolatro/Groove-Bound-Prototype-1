# Groove Bound

A twin-stick survivor roguelike game built with LÖVE framework.

## Project Structure

```
/
├── assets/
│   ├── fonts/
│   │   └── press_start.ttf
│   └── sprites/
│       └── player_walk.png
├── config/
│   ├── paths.lua     - Centralized file path references
│   └── settings.lua  - Game configuration (GAME, TUNING, DEV, CONTROLS)
├── lib/
│   ├── anim8/        - Animation library
│   ├── hump/         - Helper Utilities for Massive Productivity
│   ├── windfield/    - Physics wrapper
│   └── loader.lua    - Centralized library management
├── src/
│   ├── game_play.lua - Main game state
│   └── player.lua    - Player entity with twin-stick movement
├── main.lua          - Entry point, wires everything together
└── README.md         - This file
```

## How to Run

1. Ensure you have LÖVE framework installed (https://love2d.org/)
2. Navigate to the project directory
3. Run the game with:
   ```
   love .
   ```

## Controls

### Keyboard + Mouse
- Movement: WASD keys
- Aim: Mouse cursor
- Fire: Spacebar
- Pause: Escape

### Gamepad
- Movement: Left analog stick
- Aim: Right analog stick
- Fire: Right shoulder button
- Pause: Start button

## Debug Features

- Toggle Master Debug: F3 (shows hitboxes, enables console logs)
- Toggle Player-only Debug: Shift+F3 (only works when master debug is on)

## Development Notes

- All game settings are centralized in `config/settings.lua`
- The modular architecture allows for easy expansion
- Debug flags in each module are gated by the master debug flag
