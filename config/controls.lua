-- Controls configuration for Groove Bound
-- Defines control-related settings and parameters

local Controls = {
    -- Analog stick deadzone (0.0 to 1.0)
    DEADZONE = 0.25,
    -- Input mode (pad, mouse)
    inputMode = "pad",
    
    -- Movement keys
    KEYBOARD = {
        UP = "w",
        DOWN = "s",
        LEFT = "a",
        RIGHT = "d",
        FIRE = "space"
    },
    
    -- Gamepad mappings
    GAMEPAD = {
        -- Movement axes
        MOVE_AXES = {
            HORIZONTAL = "leftx",
            VERTICAL = "lefty"
        },
        
        -- Aiming axes
        AIM_AXES = {
            HORIZONTAL = "rightx",
            VERTICAL = "righty"
        },
        
        -- Action buttons
        BUTTONS = {
            FIRE = "rightshoulder",
            PAUSE = "start"
        }
    }
}

return Controls
