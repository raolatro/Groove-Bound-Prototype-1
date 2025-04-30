-- Main entry point for Groove Bound
-- Initializes game systems and sets up the main loop

-- Global Debug Flags
-- These will be overridden by the Config.DEV values later
-- Only need to define them here to avoid nil errors before Config is loaded
DEBUG_MASTER = false
DEBUG_WEAPONS = false
DEBUG_HITBOXES = false
DEBUG_UI = false
DEBUG_AIM = false

-- Load libraries
local L = require("lib.loader")
local PATHS = require("config.paths")

-- Load global configuration
Config = require("config.settings") -- Only allowed global

-- Initialize debug flags from Config.DEV settings to ensure consistency
DEBUG_MASTER = Config.DEV.DEBUG_MASTER
DEBUG_WEAPONS = Config.DEV.DEBUG_WEAPONS
DEBUG_HITBOXES = Config.DEV.DEBUG_HITBOXES or false
DEBUG_UI = Config.DEV.DEBUG_UI or false
DEBUG_AIM = Config.DEV.DEBUG_AIM or false
DEBUG_PROJECTILES = Config.DEV.DEBUG_PROJECTILES or false

-- Load game states
local GameStatePlay = require("src.game_play")

-- Setup love.load callback
function love.load()
    -- Set window properties
    love.window.setTitle(Config.GAME.TITLE)
    love.window.setMode(
        Config.GAME.WINDOW.WIDTH,
        Config.GAME.WINDOW.HEIGHT,
        {
            resizable = Config.GAME.WINDOW.RESIZABLE,
            vsync = Config.GAME.WINDOW.VSYNC,
            fullscreen = Config.GAME.WINDOW.FULLSCREEN
        }
    )
    
    -- Setup random seed
    math.randomseed(os.time())
    
    -- Register states with HUMP Gamestate
    L.Gamestate.registerEvents()
    
    -- Switch to the play state
    L.Gamestate.switch(GameStatePlay)
end

-- Forward resize events to the current state
function love.resize(w, h)
    -- Update window dimensions in config
    Config.GAME.WINDOW.WIDTH = w
    Config.GAME.WINDOW.HEIGHT = h
end
