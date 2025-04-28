-- Configuration settings for Groove Bound
local PATHS = require("config.paths")

-- Global configuration tables
local Config = {
    -- Game settings
    GAME = {
        TITLE = "Groove Bound",
        VERSION = "0.1.0",
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
            LERP_FACTOR = 0.1,
            SHAKE_DURATION = 0.2,
            SHAKE_INTENSITY = 5
        }
    },
    
    -- Development settings
    DEV = {
        DEBUG_MASTER = false,      -- Global debug toggle (F3)
        DEBUG_PLAYER = false,      -- Player-specific debug toggle (Shift+F3)
        DEBUG_PHYSICS = false,     -- Physics debug toggle
        DEBUG_FPS = true,          -- Show FPS counter
        INVINCIBLE = false,        -- Player invincibility for testing
        LOG_LEVEL = "info"         -- log, info, warn, error
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
                TOGGLE_PLAYER = "f3" -- With shift modifier
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
