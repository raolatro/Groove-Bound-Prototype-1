-- Settings module
-- Contains all tunable values and settings for the game
-- No hard-coded values should exist outside this file

local Settings = {}

-- Global game settings
Settings.globals = {
  run_duration = 60,        -- Duration of a run in seconds before boss appears
  boss_hp = 1000,           -- Boss health points
  xp_levels = {10,20,30,40,50,60}, -- XP thresholds for leveling up (lower for testing)
  max_weapon_slots = 4      -- Maximum number of weapons player can hold
}

-- Arena settings
Settings.arena = {
  width = 2000,            -- Arena width in pixels (larger than screen)
  height = 1600,           -- Arena height in pixels (larger than screen)
  border_thickness = 20,    -- Border wall thickness
  border_color = {0.3, 0.3, 0.3, 1} -- Border wall color
}

-- Camera settings
Settings.camera = {
  lerp_speed = 4.0,        -- Camera follow smoothness (higher = faster)
  edge_buffer = 100,        -- Minimum distance from player to screen edge
  shake_intensity = 0.5,    -- Camera shake intensity on player damage
  shake_duration = 0.3      -- Camera shake duration on player damage
}

-- Player settings
Settings.player = {
  hp = 100,                -- Starting player health
  speed = 200,              -- Base movement speed
  size = 16,                -- Player size in pixels
  iframes = 0.5,            -- Invincibility frames after damage (seconds)
  damage_flash_duration = 0.2 -- Flash duration when taking damage
}

-- Weapon settings
Settings.weapons = {
  auto_fire = true,         -- Enable auto-firing
  -- Base weapon template for all weapons
  base_weapon = {
    name = "Pistol",
    damage = 30,
    fire_rate = 0.1,
    bullet_speed = 300,     -- Increased for better gameplay
    bullet_size = 10,
    bullet_lifetime = 3.0,
    bullet_color = {1, 0, 0, 1}
  },
  -- Named weapons with proper level progression
  power_chord = {
    name = "Power Chord",
    damage = 15,
    fire_rate = 0.4,
    bullet_speed = 450,
    bullet_size = 6,
    bullet_lifetime = 1.2,
    bullet_color = {1, 0, 1, 1}
  },
  bass_drop = {
    name = "Bass Drop",
    damage = 25,
    fire_rate = 0.8,
    bullet_speed = 300,
    bullet_size = 20,
    bullet_lifetime = 0.8,
    bullet_color = {0, 1, 1, 1}
  },
  omnigun = {
    name = "OmniGun",
    damage = 50,
    fire_rate = 0.2,
    bullet_speed = 600,
    bullet_size = 16,
    bullet_lifetime = 0.5,
    bullet_color = {1, 1, 0, 1},
  }
}

-- Enemy settings
Settings.enemies = {
  -- Basic enemy settings
  basic = {
    hp = 20,               -- Health points
    speed = 60,             -- Movement speed
    size = 12,              -- Enemy size
    damage = 10,            -- Damage dealt to player
    spawn_distance = 400,   -- Min spawn distance from player
    xp_value = 10,          -- XP dropped when killed
    color = {1, 1, 1, 1},   -- Enemy color
  },
  intermediate = {
    hp = 50,               -- Health points
    speed = 120,            -- Movement speed
    size = 24,              -- Enemy size
    damage = 20,            -- Damage dealt to player
    spawn_distance = 600,   -- Min spawn distance from player
    xp_value = 20,          -- XP dropped when killed
    color = {0, 1, 1, 1},   -- Enemy color
  },
  advanced = {
    hp = 100,               -- Health points
    speed = 180,            -- Movement speed
    size = 36,              -- Enemy size
    damage = 30,            -- Damage dealt to player
    spawn_distance = 800,   -- Min spawn distance from player
    xp_value = 30,          -- XP dropped when killed
    color = {1, 0, 1, 1},   -- Enemy color
  }
  -- Add more enemy types here as needed
}

-- Spawner settings
Settings.spawner = {
  min_spawn_distance = 350, -- Minimum distance from player to spawn
  max_spawn_distance = 600, -- Maximum distance from player to spawn
  min_spawn_interval = 0.5, -- Minimum time between enemy spawns
  max_spawn_interval = 1.5, -- Maximum time between enemy spawns
  wave_sizes = {5, 8, 12, 15, 20} -- Number of enemies per wave
}

-- Collision settings
Settings.collision = {
  enable_enemy_player = true, -- Enable enemy-player collisions
  enable_enemy_enemy = false, -- Allow enemies to overlap each other
  knockback_force = 100,     -- Knockback force when player is hit
  show_hitboxes = false      -- Show collision hitboxes for debugging
}

-- Debug settings
Settings.debug = {
  -- Master debug control
  enabled = true,            -- Master switch to enable/disable debugging
  show_hitboxes = true,      -- Toggle for showing all hitboxes and collision shapes
  
  -- Per-file debug flags
  files = {
    player = true,           -- Debug output for player.lua
    enemy = false,            -- Debug output for enemy.lua
    bullet = false,           -- Debug output for bullet.lua
    arena = false,            -- Debug output for arena.lua
    camera = false,           -- Debug output for camera.lua
    collision = false,        -- Debug output for collision_system.lua
    spawner = false,          -- Debug output for spawner.lua
    xp = false,               -- Debug output for xp_system.lua
    weapon = false,           -- Debug output for weapons
    input = false,            -- Debug output for input.lua
    state = false,            -- Debug output for states
    levelup = true,          -- Debug output for level up system
    dev_tuning = true        -- Debug output for dev tuning panel
  },
  
  -- Debug display settings
  display = {
    max_rows = 20,            -- Maximum number of rows to show in debug overlay
    ttl_secs = 20,            -- Time to live for debug messages in seconds
    font_size = 8,            -- Font size for debug text
    font_color = {1,0.5,0,1}, -- Orange text color (RGBA)
    bg_color = {0,0,0,0.4},   -- Semi-transparent black background (RGBA)
    enabled = true,           -- Whether debug display is enabled
    position = {x = 10, y = 10} -- Position of debug overlay
  },
  
  -- Debug tuning parameters
  tune = {
    enemy_spawn_rate = {value=1.0, min=0.1, max=3.0, step=0.1}, -- Multiplier for enemy spawn rate
    player_damage = {value=1.0, min=0.5, max=5.0, step=0.1},     -- Multiplier for player damage
    player_speed = {value=1.0, min=0.5, max=2.0, step=0.1},      -- Multiplier for player movement speed
    luck_multiplier = {value=0, min=-50, max=50, step=5}         -- Affects rarity drops and critical hits
  }
}

-- Return the Settings module
return Settings
