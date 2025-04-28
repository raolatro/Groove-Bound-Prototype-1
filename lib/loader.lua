-- Library loader for Groove Bound
-- Centralizes all external library imports

local PATHS = require("config.paths")

local Loader = {
    -- HUMP libraries (Helper Utilities for Massive Productivity)
    Gamestate = require(PATHS.LIB.HUMP.GAMESTATE:gsub("%.lua$", "")),
    Timer = require(PATHS.LIB.HUMP.TIMER:gsub("%.lua$", "")),
    Class = require(PATHS.LIB.HUMP.CLASS:gsub("%.lua$", "")),
    Vector = require(PATHS.LIB.HUMP.VECTOR:gsub("%.lua$", "")),
    
    -- Physics
    Windfield = require(PATHS.LIB.WINDFIELD),
    
    -- Animation
    Anim8 = require(PATHS.LIB.ANIM8:gsub("%.lua$", ""))
}

-- Initialize random number generator with seed
Loader.RNG = love.math.newRandomGenerator(os.time())

return Loader
