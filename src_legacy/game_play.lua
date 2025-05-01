-- Game Play State for Groove Bound
-- Handles the main gameplay screen

local L = require("lib.loader")
local PATHS = require("config.paths")
local Config = require("config.settings")
local Player = require("src.player")
local Arena = require("src.arena")
local WallManager = require("src.wall_manager")
local Projectile = require("src.projectile")
local GameSystems = require("src.systems.game_systems")
local Debug = require("src.debug")
local Camera = require("lib.camera")
local UI = require("config.ui")
local Controls = require("config.controls")
local Event = require("lib.event")

-- Use the imported Debug module

-- Shorthand for readability
local GAME = Config.GAME
local DEV = Config.DEV

-- Create gamestate
local GamePlay = {}

-- Expose gameplay state globally for cross-system access 
-- (needed for camera resets and other direct control)
_G.gamePlay = GamePlay

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
    self.pauseReason = nil  -- Can be "manual", "levelup", "gameover", etc.
    self.cameraResetNeeded = false  -- Flag to force camera reset
    
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
    
    -- Make sure projectile system is initialized first
    Projectile:initPool()
    
    -- Initialize game systems (weapons, passives, inventory)
    self.gameSystems = GameSystems:init(self.player)
    
    -- Print debug message about initialization
    if DEV.DEBUG_MASTER then
        Debug.log("Gameplay initialized - Projectile system and weapon systems ready")
    end
    
    -- Set up event listeners for level-up shop
    Event.subscribe("LEVEL_UP_STARTED", function(data)
        -- Pause the game when level-up shop starts
        self.isPaused = true
        self.pauseReason = "levelup" -- Set reason for pause
        
        if DEV.DEBUG_MASTER then
            Debug.log("GamePlay: Game paused due to level-up shop")
        end
    end)
    
    Event.subscribe("LEVEL_UP_SHOP_CLOSED", function(data)
        -- Unpause the game when level-up shop closes
        self.isPaused = false
        self.pauseReason = nil -- Clear pause reason
        
        if DEV.DEBUG_MASTER then
            Debug.log("GamePlay: Game unpaused - level-up shop closed")
        end
    end)
    
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
    
    -- Check if camera needs to be reset (like after game restart)
    if self.cameraResetNeeded then
        -- Immediately snap camera to player
        _G.camera:resetPosition(targetX, targetY)
        self.cameraResetNeeded = false -- Reset the flag
        
        -- Debug output
        if DEV.DEBUG_MASTER then
            Debug.log("Camera forcibly reset to player at: " .. targetX .. "," .. targetY)
        end
    else
        -- Normal smooth camera update
        _G.camera:update(dt, targetX, targetY)
    end
    
    -- Update debug messages
    Debug.update(dt)
    
    -- If the game is paused
    if self.isPaused then
        -- Still update the level-up shop if it's open
        if self.pauseReason == "levelup" and self.gameSystems and self.gameSystems.levelUpSystem then
            -- Only update the level-up system when paused for level-up
            self.gameSystems.levelUpSystem:update(dt)
            
            if DEV.DEBUG_MASTER then
                -- Debug.log("GamePlay:update - Updating level-up system while paused")
            end
        end
        
        -- Skip all other updates
        return
    end
    
    -- Update physics world
    self.world:update(dt)
    
    -- Update player
    self.player:update(dt)
    
    -- Update wall manager
    self.wallManager:update(dt)
    
    -- Update game systems
    if self.gameSystems then
        self.gameSystems:update(dt)
    end
    
    -- TODO: Update other game elements (enemies, projectiles, etc.)
end

-- Draw the game
function GamePlay:draw()
    -- Determine if we're in a level-up shop state
    local isLevelUpShopOpen = self.isPaused and self.pauseReason == "levelup" and 
                            self.gameSystems and 
                            self.gameSystems.levelUpSystem and 
                            self.gameSystems.levelUpSystem.shopOpen
    
    -- Clear screen
    love.graphics.clear(0.05, 0.05, 0.1)
    
    -- Camera transformation start
    if _G.camera then
        _G.camera:attach()
    end
    
    -- Draw arena
    self.arena:draw()
    self.wallManager:draw()
    
    -- Draw projectiles
    -- This must be done inside the camera transformation
    Projectile:drawAll()
    
    -- Draw player
    self.player:draw()
    
    -- Only draw non-UI game systems inside camera transform
    if self.gameSystems then
        self.gameSystems:drawWorld() -- Only draw world elements (weapons, effects, etc.)
    end
    
    -- Draw physics debug if enabled
    if DEV.DEBUG_PHYSICS and DEV.DEBUG_MASTER then
        self.world:draw()
    end

    -- Camera transformation end
    if _G.camera then
        _G.camera:detach()
    end
    
    -- Draw UI components from game systems (outside camera transform)
    if self.gameSystems then
        -- Normal UI drawing when not paused
        if not self.isPaused then
            self.gameSystems:drawUI()
        -- Special case: when paused for level-up, we still need to draw the shop
        elseif self.pauseReason == "levelup" then
            -- Only draw the level-up shop when paused for level-up
            if self.gameSystems.levelUpSystem then
                self.gameSystems.levelUpSystem:draw()
            end
            
            if DEV.DEBUG_MASTER then
                -- Debug.log("GamePlay:draw - Drawing level-up shop while paused")
            end
        end
    end
    
    -- Handle pause conditions
    if self.isPaused then
        -- If paused for level-up, draw the shop UI
        if self.pauseReason == "levelup" and self.gameSystems and self.gameSystems.levelUpSystem then
            -- First draw a full-screen dark overlay
            love.graphics.setColor(0, 0, 0, 0.9)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
            love.graphics.setColor(1, 1, 1, 1)
            
            -- Force the level-up shop to draw
            if self.gameSystems.levelUpSystem.shop then
                -- Force shop to be open
                self.gameSystems.levelUpSystem.shop.isOpen = true
                
                -- Draw the shop UI
                self.gameSystems.levelUpSystem.shop:draw()
                
                if DEV.DEBUG_MASTER then
                    -- Debug.log("GamePlay:draw - Directly drawing level-up shop during pause")
                end
            end
        else
            -- For other pause types, draw the standard pause overlay
            self:drawPauseOverlay()
        end
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
    
    -- Draw debug messages last to ensure they appear on top of everything
    -- This includes level-up shop and all other UI elements
    Debug.draw()
end

-- Draw pause overlay
function GamePlay:drawPauseOverlay()
    -- Only draw the pause overlay if this is a manual pause
    -- Don't draw if paused due to level up shop or other special screens
    if self.pauseReason and self.pauseReason ~= "manual" then
        return -- Skip drawing overlay for special pause types
    end
    
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
    -- Toggle pause on escape, but only if we're not in a special pause state
    if key == Config.CONTROLS.KEYBOARD.PAUSE then
        if self.pauseReason and self.pauseReason ~= "manual" then
            -- Don't allow manual pause toggle during level-up or other special states
            if DEV.DEBUG_MASTER then
                Debug.log("GamePlay: Cannot toggle pause during " .. self.pauseReason)
            end
        else
            -- Toggle pause state
            self.isPaused = not self.isPaused
            
            -- Set or clear the pause reason
            if self.isPaused then
                self.pauseReason = "manual"
                if DEV.DEBUG_MASTER then
                    Debug.log("GamePlay: Game manually paused")
                end
            else
                self.pauseReason = nil
                if DEV.DEBUG_MASTER then
                    Debug.log("GamePlay: Game manually unpaused")
                end
            end
        end
        return
    end
    
    -- Forward keypressed to game systems
    if self.gameSystems then
        self.gameSystems:keypressed(key)
    end
    
    -- Toggle master debug
    if key == Config.CONTROLS.KEYBOARD.DEBUG.TOGGLE_MASTER then
        DEV.DEBUG_MASTER = not DEV.DEBUG_MASTER
        Debug.log("Master debug: " .. (DEV.DEBUG_MASTER and "ON" or "OFF"))
        return
    end
    
    -- Forward keypresses to player when not paused
    if not self.isPaused then
        self.player:keypressed(key)
        
        -- Use the new gameSystems module instead of WeaponManager
        if self.gameSystems then
            self.gameSystems:keypressed(key)
        end
        
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
    -- Forward to game systems (this handles game over menu clicks as well)
    if self.gameSystems then
        self.gameSystems:mousepressed(x, y, button)
    end
    
    -- Handle other mouse presses when not paused
    if not self.isPaused then
        -- We can add player mouse handling here in the future if needed
        -- Player class doesn't have a mousepressed method yet
    end
end

-- Handle gamepad button press
function GamePlay:gamepadpressed(joystick, button)
    -- Forward to game systems (this handles game over menu gamepad input)
    if self.gameSystems then
        self.gameSystems:gamepadpressed(joystick, button)
    end
    
    -- Toggle pause on start button
    if button == "start" and not (self.gameSystems and self.gameSystems.gameOverSystem and self.gameSystems.gameOverSystem.isGameOver) then
        self.isPaused = not self.isPaused
        return
    end
    
    -- No need to forward to player as it doesn't have a gamepadpressed method yet
    -- We can add other gamepad controls here in the future if needed
end

-- Handle window resize
function GamePlay:resize(w, h)
    -- Pass resize event to game systems
    if self.gameSystems then
        self.gameSystems:resize(w, h)
    end
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
