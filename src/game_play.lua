-- Game Play State for Groove Bound
-- Handles the main gameplay screen

local L = require("lib.loader")
local Config = require("config.settings")
local PATHS = require("config.paths")
local UI = require("config.ui")
local Controls = require("config.controls")
local Player = require("src.player")
local Projectile = require("src.projectile")
local Camera = require("lib.camera")
local Arena = require("src.arena")
local WallManager = require("src.wall_manager")
local WeaponManager = require("src.weapon_manager")

-- Get global Debug instance
local Debug = _G.Debug

-- Shorthand for readability
local GAME = Config.GAME
local DEV = Config.DEV

-- Create gamestate
local GamePlay = {}

-- Local instances
local camera = nil

-- Initialize state
function GamePlay:init()
    -- Physics world initialization
    if self.world then
        self.world:destroy()
    end
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
    
    -- Initialize arena
    self.arena = Arena
    self.arena:init(self.world)
    
    -- Initialize obstacles
    self.wallManager = WallManager
    self.wallManager:spawn(UI.ARENA.obstacleCount, self.world, os.time())
    
    -- Initialize player in the center of the arena
    self.player = Player:new(UI.ARENA.w / 2, UI.ARENA.h / 2, self.world)
    
    -- TODO: Initialize enemies, pickups, etc.
end

-- Update logic
function GamePlay:update(dt)
    -- Initialize camera if not already created
    if not _G.camera then
        _G.camera = Camera:new(UI.ARENA.w, UI.ARENA.h)
    end
    -- Store camera reference for gameplay state access
    self.camera = _G.camera
    
    -- Update camera to follow player (get position from collider)
    local targetX, targetY = 0, 0
    if self.player.collider then
        targetX, targetY = self.player.collider:getPosition()
    else
        targetX, targetY = self.player.x, self.player.y
    end
    _G.camera:update(dt, targetX, targetY)
    
    -- Update debug messages
    Debug.update(dt)
    
    -- Skip update if paused
    if self.isPaused then return end
    
    -- Update physics world
    self.world:update(dt)
    
    -- Update player
    self.player:update(dt)
    
    -- Update wall manager
    self.wallManager:update(dt)
    
    -- TODO: Update other game elements (enemies, projectiles, etc.)
end

-- Draw the game
function GamePlay:draw()
    -- Clear screen
    love.graphics.clear(0.05, 0.05, 0.1)
    
    -- Camera transformation start
    if _G.camera then
        _G.camera:attach()
    end
    
    -- Draw arena
    self.arena:draw()
    self.wallManager:draw()
    
    -- Draw player
    self.player:draw()
    
    -- Draw physics debug if enabled
    if DEV.DEBUG_PHYSICS and DEV.DEBUG_MASTER then
        self.world:draw()
    end

    -- Camera transformation end
    if _G.camera then
        _G.camera:detach()
    end
    
    -- Draw debug messages (outside camera transform)
    Debug.draw()
    
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
        WeaponManager:keypressed(key)
        Projectile:keypressed(key)
    end
    
    -- Forward to arena and wall systems
    self.arena:keypressed(key)
    self.wallManager:keypressed(key)
    
    -- Forward to debug system (for F9 clear logs)
    Debug.keypressed(key)
    
    -- Toggle input mode on F10 (direct toggle between pad and mouse)
    if key == "f10" then
        -- Simple toggle between pad and mouse
        Controls.inputMode = (Controls.inputMode == "pad") and "mouse" or "pad"
        if Debug.enabled and Debug.INPUT then 
            Debug.log("[toggle] Input mode: " .. Controls.inputMode)
        end
    end
    
    -- Forward to camera (no toggles, but might have other functions)
    if camera then camera:keypressed(key) end
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
    -- Update camera viewport if it exists
    if camera then
        camera.viewportWidth = w
        camera.viewportHeight = h
    end
end

-- Clean up when leaving the state
function GamePlay:leave()
    -- Save any game state if needed
end

return GamePlay
