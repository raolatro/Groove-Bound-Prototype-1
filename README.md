# Groove Bound

A twin-stick survivor roguelike game built with LÖVE framework.

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
- Toggle Weapons Debug: F4 (shows weapon hitboxes and stats)
- Toggle Projectiles Debug: Shift+F4 (shows projectile hitboxes and pool stats)

## Development Notes

- All game settings are centralized in `config/settings.lua`
- The modular architecture allows for easy expansion
- Debug flags in each module are gated by the master debug flag
- During prototype phase debug overlay is always on; remove `_G.Debug.enabled` default or reintroduce keybind later.
- Camera.lag setting (0-1): 0 = instant snap, 1 = no movement. Default 0.15 provides smooth following.
- Collider size is triple-height (3 × GRID.base) with 1× width; change grid base, collider auto-scales.
- Player aiming uses right stick (gamepad) or mouse position (keyboard); red crosshair is temporary placeholder for projectile spawn.
- Debug overlay now uses system font in red; change size via Debug.font = love.graphics.newFont(size).

## Weapon System

### Adding New Weapons

To add a new weapon, simply add a new entry to `config/weapons.lua`. Each weapon definition requires:

```lua
newWeapon = {
    id = "unique_id",         -- Unique identifier
    name = "Display Name",     -- Shown in UI
    slot = "sidearm",          -- Equip slot (sidearm, primary, special, etc.)
    category = CATEGORIES.PISTOL, -- Weapon category for evolution
    damage = 10,                 -- Base damage
    cooldown = 0.4,              -- Seconds between shots
    projectileSpeed = 600,       -- Projectile velocity
    projectileCount = 1,         -- Bullets per shot
    spread = 0.05,               -- Shot dispersion in radians
    area = 5,                    -- Projectile hitbox radius
    sprite = PATHS.ASSETS.SPRITES.WEAPONS.PISTOL, -- Weapon sprite path
    projectileSprite = PATHS.ASSETS.SPRITES.PROJECTILES.BULLET, -- Projectile sprite
    sfx = PATHS.ASSETS.AUDIO.SFX.WEAPONS.PISTOL,  -- Sound effect
    
    -- Category-specific attributes (optional)
    catAttrib = {
        clipSize = 8,           -- Example: pistol-specific
        reloadTime = 1.0
    },
    
    -- Weapon-specific attributes (optional)
    weaponAttrib = {
        accuracy = 0.9,         -- Example: this specific gun
        critChance = 0.05       -- 5% critical hit chance
    }
}
```

### Projectile Pooling

The game uses object pooling for projectiles to improve performance:

- Projectiles are recycled when they go off-screen or exceed their lifetime
- The pool size is controlled by `TUNING.PROJECTILES.POOL_MAX_PROJECTILES` in settings.lua
- When a projectile is "destroyed", it's simply deactivated (`isActive = false`) and returned to the pool
- If the pool is full, the oldest active projectile is recycled

### Test Controls

- Press SPACE to add a test pistol weapon
- F4 to toggle weapon debug visualization
- Shift+F4 to toggle projectile debug visualization
