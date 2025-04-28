-- main.lua for Groove Bound (Prototype)
-- Twin-stick survivor roguelike

-- Load libraries
local L = require("lib.loader")
local PATHS = require("config.paths")

-- Load global configuration
Config = require("config.settings") -- Only allowed global

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
