-- Game Play State for Groove Bound
-- Handles the main gameplay screen

local L = require("lib.loader")
local Config = require("config.settings")
local PATHS = require("config.paths")
local Player = require("src.player")

-- Shorthand for readability
local GAME = Config.GAME
local DEV = Config.DEV

-- Create gamestate
local GamePlay = {}

-- Initialize state
function GamePlay:init()
    -- Physics world initialization
    self.world = L.Windfield.newWorld(0, 0, true)
    
    -- Game state
    self.isPaused = false
    
    -- Load default font
    self.font = love.graphics.newFont(GAME.DEFAULT_FONT, GAME.FONT_SIZES.MEDIUM)
end

-- Execute on state enter
function GamePlay:enter()
    -- Create player in the center of the screen
    local centerX = love.graphics.getWidth() / 2
    local centerY = love.graphics.getHeight() / 2
    self.player = Player:new(centerX, centerY)
    
    -- TODO: Initialize enemies, pickups, etc.
end

-- Update logic
function GamePlay:update(dt)
    -- Skip update if paused
    if self.isPaused then return end
    
    -- Update physics world
    self.world:update(dt)
    
    -- Update player
    self.player:update(dt)
    
    -- TODO: Update other game elements (enemies, projectiles, etc.)
end

-- Draw the game
function GamePlay:draw()
    -- Clear screen
    love.graphics.clear(0.1, 0.1, 0.15)
    
    -- Draw player
    self.player:draw()
    
    -- Draw physics debug if enabled
    if DEV.DEBUG_PHYSICS and DEV.DEBUG_MASTER then
        self.world:draw()
    end
    
    -- Draw pause overlay
    if self.isPaused then
        self:drawPauseOverlay()
    end
    
    -- Draw FPS counter
    if DEV.DEBUG_FPS then
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.setFont(self.font)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
    end
    
    -- Draw debug info when master debug is enabled
    if DEV.DEBUG_MASTER then
        love.graphics.setColor(1, 1, 0, 0.8)
        love.graphics.setFont(self.font)
        love.graphics.print("DEBUG MODE", 10, love.graphics.getHeight() - 30)
    end
end

-- Draw pause overlay
function GamePlay:drawPauseOverlay()
    -- Dim the background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw pause text
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.font)
    local text = "PAUSED"
    local textWidth = self.font:getWidth(text)
    love.graphics.print(
        text, 
        love.graphics.getWidth() / 2 - textWidth / 2,
        love.graphics.getHeight() / 2 - self.font:getHeight() / 2
    )
end

-- Handle keypresses
function GamePlay:keypressed(key)
    -- Toggle pause on escape
    if key == Config.CONTROLS.KEYBOARD.PAUSE then
        self.isPaused = not self.isPaused
        return
    end
    
    -- Toggle master debug
    if key == Config.CONTROLS.KEYBOARD.DEBUG.TOGGLE_MASTER then
        DEV.DEBUG_MASTER = not DEV.DEBUG_MASTER
        print("Master debug: " .. (DEV.DEBUG_MASTER and "ON" or "OFF"))
        return
    end
    
    -- Forward keypresses to player when not paused
    if not self.isPaused then
        self.player:keypressed(key)
    end
end

-- Handle mouse press
function GamePlay:mousepressed(x, y, button)
    -- Handle mouse presses when not paused
    if not self.isPaused then
        -- TODO: Handle mouse press for shooting, etc.
    end
end

-- Handle window resize
function GamePlay:resize(w, h)
    -- TODO: Handle camera and UI adjustments on resize
end

-- Clean up when leaving the state
function GamePlay:leave()
    -- Save any game state if needed
end

return GamePlay
