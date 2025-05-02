-- Settings module
-- Contains all tunable values and settings for the game
-- No hard-coded values should exist outside this file

-- Global game settings
globals = {
  run_duration = 60,        -- Duration of a run in seconds before boss appears
  boss_hp = 1000,           -- Boss health points
  xp_levels = {10,20,30,40,50,60}, -- XP thresholds for leveling up (lower for testing)
  max_weapon_slots = 4      -- Maximum number of weapons player can hold
}

-- Arena settings
arena = {
  width = 2000,            -- Arena width in pixels (larger than screen)
  height = 1600,           -- Arena height in pixels (larger than screen)
  border_thickness = 20,    -- Border wall thickness
  border_color = {0.3, 0.3, 0.3, 1} -- Border wall color
}

-- Camera settings
camera = {
  lerp_speed = 4.0,        -- Camera follow smoothness (higher = faster)
  edge_buffer = 100,        -- Minimum distance from player to screen edge
  shake_intensity = 0.5,    -- Camera shake intensity on player damage
  shake_duration = 0.3      -- Camera shake duration on player damage
}

-- Player settings
player = {
  hp = 100,                -- Starting player health
  speed = 200,              -- Base movement speed
  size = 16,                -- Player size in pixels
  iframes = 0.5,            -- Invincibility frames after damage (seconds)
  damage_flash_duration = 0.2 -- Flash duration when taking damage
}

-- Weapon settings
weapons = {
  auto_fire = true,         -- Enable auto-firing
  -- Base weapon template for all weapons
  base_weapon = {
    damage = 30,
    fire_rate = 0.05,
    bullet_speed = 350,
    bullet_size = 6,
    bullet_lifetime = 2.0
  }
}

-- Enemy settings
enemies = {
  -- Basic enemy settings
  basic = {
    hp = 20,               -- Health points
    speed = 60,             -- Movement speed
    size = 12,              -- Enemy size
    damage = 10,            -- Damage dealt to player
    spawn_distance = 400,   -- Min spawn distance from player
    xp_value = 1            -- XP dropped when killed
  },
  -- Add more enemy types here as needed
}

-- Spawner settings
spawner = {
  min_spawn_distance = 350, -- Minimum distance from player to spawn
  max_spawn_distance = 600, -- Maximum distance from player to spawn
  min_spawn_interval = 0.5, -- Minimum time between enemy spawns
  max_spawn_interval = 1.5, -- Maximum time between enemy spawns
  wave_sizes = {5, 8, 12, 15, 20} -- Number of enemies per wave
}

-- Collision settings
collision = {
  enable_enemy_player = true, -- Enable enemy-player collisions
  enable_enemy_enemy = false, -- Allow enemies to overlap each other
  knockback_force = 100,     -- Knockback force when player is hit
  show_hitboxes = false      -- Show collision hitboxes for debugging
}

-- Debug display settings
debug_display = {
  max_rows = 20,            -- Maximum number of rows to show in debug overlay
  ttl_secs = 20,            -- Time to live for debug messages in seconds
  font_size = 8,            -- Font size for debug text
  font_color = {1,0,0,1},   -- Red text color (RGBA)
  bg_color = {0,0,0,0.4}    -- Semi-transparent black background (RGBA)
}

-- Debug tuning parameters
debug_tune = {
  enemy_spawn_rate = {value=1.0, min=0.1, max=3.0, step=0.1}, -- Multiplier for enemy spawn rate
  player_damage = {value=1.0, min=0.5, max=5.0, step=0.1},     -- Multiplier for player damage
  player_speed = {value=1.0, min=0.5, max=2.0, step=0.1},      -- Multiplier for player movement speed
  luck_multiplier = {value=0, min=-50, max=50, step=5}         -- Affects rarity drops and critical hits
}

-- Debug flags
debug_show_hitboxes = false -- Toggle for showing all hitboxes and collision shapes

-- Return module
return {
  globals = globals,
  arena = arena,
  camera = camera,
  player = player,
  weapons = weapons,
  enemies = enemies,
  spawner = spawner,
  collision = collision,
  debug_display = debug_display,
  debug_tune = debug_tune,
  debug_show_hitboxes = debug_show_hitboxes
}
