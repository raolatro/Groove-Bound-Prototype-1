-- Path configuration for Groove Bound
-- Centralizes all file path references

local PATHS = {
    -- Asset paths
    ASSETS = {
        ROOT = "assets/",
        SPRITES = {
            ROOT = "assets/sprites/",
            PLAYER = "assets/sprites/player_walk.png"
        },
        FONTS = {
            ROOT = "assets/fonts/",
            PRESS_START = "assets/fonts/m6x11plus.ttf"
        }
    },
    
    -- Source code paths
    SRC = {
        ROOT = "src/",
        STATES = {
            PLAY = "src/game_play.lua"
        },
        ENTITIES = {
            PLAYER = "src/player.lua"
        }
    },
    
    -- Config paths
    CONFIG = {
        ROOT = "config/",
        SETTINGS = "config/settings.lua",
        PATHS = "config/paths.lua"
    },
    
    -- Libraries
    LIB = {
        ROOT = "lib/",
        LOADER = "lib/loader.lua",
        HUMP = {
            ROOT = "lib/hump/",
            GAMESTATE = "lib/hump/gamestate.lua",
            TIMER = "lib/hump/timer.lua",
            CLASS = "lib/hump/class.lua",
            VECTOR = "lib/hump/vector.lua"
        },
        WINDFIELD = "lib/windfield/",
        ANIM8 = "lib/anim8/anim8.lua"
    }
}

return PATHS
