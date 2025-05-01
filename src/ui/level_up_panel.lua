-- level_up_panel.lua
-- Handles the UI for level-up choices
-- DISABLED: This legacy panel has been replaced by the new LevelUpShop system

local L = require("lib.loader")
local PATHS = require("config.paths")
local UI = require("config.ui")
local Debug = require("src.debug")

-- The LevelUpPanel module
local LevelUpPanel = {
    -- UI positioning and sizing
    x = 0,
    y = 0,
    width = 800,
    height = 400,
    padding = 20,
    cardWidth = 220,
    cardHeight = 300,
    
    -- Fonts
    titleFont = nil,
    headerFont = nil,
    textFont = nil,
    
    -- Animation and state
    visible = false,
    fadeInTime = 0.3,
    currentFade = 0,
    selectedCard = nil,
    
    -- Level-up data
    newLevel = 1,
    choices = {},
    
    -- References
    levelUpSystem = nil,
    
    -- Flag for whether panel has been initialized
    initialized = false,
    
    -- Flag to indicate this system is disabled
    disabled = true
}

-- Initialize the level-up panel - does minimal setup since it's disabled
function LevelUpPanel:init(levelUpSystem)
    self.initialized = true
    return self
end

-- Show the level-up panel - disabled
function LevelUpPanel:show(level, choices)
    -- Disabled - does nothing
    return
end

-- Hide the level-up panel - disabled
function LevelUpPanel:hide()
    -- Disabled - does nothing
    return
end

-- Update the level-up panel - disabled
function LevelUpPanel:update(dt)
    -- Disabled - does nothing
    return
end

-- Process panel input - disabled
function LevelUpPanel:processInput()
    -- Disabled - does nothing
    return
end

-- Draw the level-up panel - disabled
function LevelUpPanel:draw()
    -- Disabled - does nothing
    return
end

-- Handle resize - disabled
function LevelUpPanel:resize(w, h)
    -- Disabled - does nothing
    return
end

return LevelUpPanel
