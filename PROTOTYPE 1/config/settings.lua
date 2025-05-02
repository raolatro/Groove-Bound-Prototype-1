-- Configuration settings for Groove Bound
local PATHS = require("config.paths")

-- Global configuration tables
local Config = {
    -- Game settings
    GAME = {
        TITLE = "Groove Bound (Prototype)",
        VERSION = "0.2.0",
        WINDOW = {
            WIDTH = 1280,
            HEIGHT = 720,
            RESIZABLE = true,
            VSYNC = true,
            FULLSCREEN = false
        },
        DEFAULT_FONT = PATHS.ASSETS.FONTS.PRESS_START,
        FONT_SIZES = {
            SMALL = 12,
            MEDIUM = 18,
            LARGE = 24
        }
    },
    
    -- Tuning parameters
    TUNING = {
        PLAYER = {
            MOVE_SPEED = 200,
            ACCELERATION = 2000,
            FRICTION = 10,
            SPRITE_SIZE = 128,
            HITBOX_RADIUS = 12,
            FIRE_COOLDOWN = 0.25  -- seconds between shots
        },
        CAMERA = {
            LERP_FACTOR = 1, -- Linear interpolation factor for smooth following
            SHAKE_DURATION = 0.2, -- Duration of screen shake in seconds
            SHAKE_INTENSITY = 5 -- Intensity of screen shake
        },
        PROJECTILES = {
            POOL_MAX_PROJECTILES = 200,  -- Maximum number of projectiles in the pool
            SCREEN_MARGIN = 100,         -- Extra pixels beyond screen to despawn projectiles
            DEFAULT_LIFETIME = 5          -- Default lifetime in seconds if not otherwise specified
        },
        WEAPONS = {
            MAX_PLAYER_WEAPONS = 6,      -- Maximum number of weapons a player can have
            ACQUIRE_COOLDOWN = 0.5,       -- Cooldown before another weapon can be acquired
            DEFAULT_COOLDOWN = 0.5        -- Default cooldown if not specified in weapon def
        },
        ENEMIES = {
            SAFE_SPAWN_RADIUS = 300,     -- px from player centre
            BASE_SPAWN_RATE = 0.8,       -- enemies/sec (can be overridden per enemy)
            RANDOM_RANGE_PCT = 0.20,     -- ±20% size & colour shift
            DEFAULT_CONTACT = 20,        -- Default damage on contact if not specified
            MAX_HP = 50,                -- Maximum enemy health
            INVINCIBLE_TIME = 0.1        -- Seconds of invincibility after being hit
        },
        GEMS = {
            BASE_XP = 20,                -- XP per gem before multiplier
            ATTRACT_RADIUS = 150,        -- px; dashed circle debug
            ATTRACT_SPEED = 300          -- px/s toward player
        },
        
        -- Luck and rarity settings
        LUCK = {
            BASE = { common = 0.70, rare = 0.20, epic = 0.08, legendary = 0.02 },  -- Base rarity weights
            SHIFT = { common = -0.004, rare = 0.0025, epic = 0.0012, legendary = 0.0003 }, -- Per +1 luck
            MIN_COMMON = 0.20,         -- Common items will never drop below this threshold
            MAX_LEGENDARY = 0.25       -- Legendary items will never exceed this threshold
        },
        
        -- Level-up shop settings
        SHOP = {
            NUM_CARDS = 3,              -- Number of cards to display in the level-up shop
            REROLL_COST = 0,            -- Coin cost to reroll shop options (placeholder for future)
            FLASH_TIME = 1.0            -- Duration of the white flash when leveling up in seconds
        }
    },
    
    -- Development settings
    DEV = {
        DEBUG_MASTER = true,      -- Always on during prototype phase
        DEBUG_PLAYER = false,      -- Player-specific debug toggle (Shift+F3)
        DEBUG_PHYSICS = false,     -- Physics debug toggle
        DEBUG_ASSETS = false,      -- Asset debug toggle
        DEBUG_WEAPONS = true,     -- Weapons debug toggle (F4)
        DEBUG_PROJECTILES = false, -- Projectiles debug toggle (Shift+F4)
        DEBUG_AIM = true,        -- Aim debug toggle (shows aim vector and target)
        DEBUG_UI = true,         -- UI debug toggle (shows cooldown times, names, etc.)
        DEBUG_ENEMIES = false,    -- Enemy debug toggle (shows hitboxes, HP, stats)
        DEBUG_GEMS = true,       -- XP gem debug toggle (shows attraction radius)
        DEBUG_HP = true,         -- HP system debug (shows damage numbers, hitbox flashes)
        DEBUG_GRID = true,        -- Grid debug toggle
        DEBUG_WALLS = false,       -- Walls debug toggle
        DEBUG_CAMERA = false,      -- Camera debug (always on)
        DEBUG_COLLISION = false,   -- Collision debug (always on)
        DEBUG_FPS = false,         -- Show FPS counter
        DEBUG_LEVEL_UP = true,    -- Level-up debug toggle

        RANDOMIZE_ENEMIES = true, -- Randomize enemy size and color within range
        INVINCIBLE = false,        -- Player invincibility for testing
        LOG_LEVEL = "info",       -- log, info, warn, error
        HP_DEBUG = {
            DAMAGE_FLASH_TIME = 0.2,  -- Time to flash hitbox after damage
            DAMAGE_FLASH_COLOR = {1, 0, 0, 1}  -- Color to flash hitbox after damage
        }
    },
    
    -- Control mapping
    CONTROLS = {
        KEYBOARD = {
            MOVE = {
                UP = "w",
                DOWN = "s",
                LEFT = "a",
                RIGHT = "d"
            },
            FIRE = "space",
            PAUSE = "escape",
            DEBUG = {
                TOGGLE_MASTER = "f3",
                TOGGLE_PLAYER = "f3", -- With shift modifier
                TOGGLE_ASSETS = "f5",
                TOGGLE_GRID = "f5",   -- Without shift modifier
                TOGGLE_WALLS = "f6",
                TOGGLE_DEBUG_CLEAR = "f9", -- Clear debug messages
                TOGGLE_WEAPONS = "f4",
                TOGGLE_PROJECTILES = "f4" -- With shift modifier
            }
        },
        GAMEPAD = {
            MOVE_AXIS = {
                HORIZONTAL = "leftx",
                VERTICAL = "lefty"
            },
            AIM_AXIS = {
                HORIZONTAL = "rightx", 
                VERTICAL = "righty"
            },
            FIRE = "rightshoulder",
            PAUSE = "start"
        },
        DEADZONE = 0.25            -- Joystick deadzone
    }
}

return Config
