-- game_over_system.lua
-- Handles game over state, statistics, and restart

local L = require("lib.loader")
local Config = require("config.settings")
local PATHS = require("config.paths")
local Event = require("lib.event")
local Debug = require("src.debug")
local Gamestate = L.Gamestate  -- Import Gamestate from loader
local DEV = Config.DEV

-- Define events
Event.define("GAME_RESTART", {})

-- The GameOverSystem module
local GameOverSystem = {
    -- Game state
    isGameOver = false,
    fadeAlpha = 0,
    fadeState = "none", -- "none", "to_black", "hold", "from_black"
    
    -- References
    player = nil,
    gameMenu = nil,
    
    -- Stats
    stats = {
        finalLevel = 0,
        totalXP = 0,
        timeAlive = 0,
        enemiesKilled = 0,
        weaponsAcquired = {},
        passiveItems = {}
    },
    
    -- Timers and durations
    fadeToBlackDuration = 0.5,
    fadeHoldDuration = 0.3,
    fadeFromBlackDuration = 0.5,
    fadeTimer = 0,
    
    -- Flags
    initialized = false
}

-- Initialize the game over system
function GameOverSystem:init(player, gameSystems)
    -- Store references
    self.player = player
    self.gameSystems = gameSystems
    
    -- Reset state
    self.isGameOver = false
    self.fadeAlpha = 0
    self.fadeState = "none"
    self.fadeTimer = 0
    
    -- Clear stats
    self:resetStats()
    
    -- Set up event listeners
    Event.subscribe("PLAYER_DEAD", function(data)
        self:onPlayerDead()
    end)
    
    Event.subscribe("GAME_RESTART", function(data)
        self:restartGame()
    end)
    
    Event.subscribe("ENEMY_KILLED", function(data)
        -- Track enemy kills
        self.stats.enemiesKilled = self.stats.enemiesKilled + 1
    end)
    
    -- Mark as initialized
    self.initialized = true
    
    return self
end

-- Reset statistics
function GameOverSystem:resetStats()
    self.stats = {
        finalLevel = 0,
        totalXP = 0,
        timeAlive = 0,
        enemiesKilled = 0,
        weaponsAcquired = {},
        passiveItems = {}
    }
end

-- Handle player death
function GameOverSystem:onPlayerDead()
    if self.isGameOver then
        return -- Already in game over state
    end
    
    -- Set game over state
    self.isGameOver = true
    
    -- Pause enemy and spawner updates
    if self.gameSystems then
        -- Pause enemy system
        if self.gameSystems.enemySystem then
            self.gameSystems.enemySystem.paused = true
        end
        
        -- Pause enemy spawner
        if self.gameSystems.enemySpawner then
            self.gameSystems.enemySpawner.paused = true
        end
    end
    
    -- Collect final stats
    self:collectStats()
    
    -- Start fade to black
    self.fadeState = "to_black"
    self.fadeTimer = 0
    self.fadeAlpha = 0
end

-- Collect player stats
function GameOverSystem:collectStats()
    -- Get level info from level up system
    if self.gameSystems and self.gameSystems.levelUpSystem then
        local levelInfo = self.gameSystems.levelUpSystem:getLevelInfo()
        self.stats.finalLevel = levelInfo.level
        self.stats.totalXP = levelInfo.currentXP
    end
    
    -- Get time alive (would come from a game timer)
    -- For now, use placeholder or estimate from game systems
    self.stats.timeAlive = self.gameSystems.gameTimer or 0
    
    -- Weapons acquired
    if self.gameSystems and self.gameSystems.weaponSystem then
        self.stats.weaponsAcquired = {}
        for _, weapon in ipairs(self.gameSystems.weaponSystem.weapons) do
            table.insert(self.stats.weaponsAcquired, {
                id = weapon.id,
                name = weapon.def.displayName,
                level = weapon.level
            })
        end
    end
    
    -- Passive items
    if self.gameSystems and self.gameSystems.passiveSystem then
        self.stats.passiveItems = {}
        for _, passive in ipairs(self.gameSystems.passiveSystem.passives) do
            table.insert(self.stats.passiveItems, {
                id = passive.id,
                name = passive.def.displayName,
                level = passive.level
            })
        end
    end
end

-- Update method 
function GameOverSystem:update(dt)
    -- Skip if not initialized
    if not self.initialized then
        return
    end
    
    -- Handle fade states
    if self.fadeState == "to_black" then
        -- Fading to black
        self.fadeTimer = self.fadeTimer + dt
        self.fadeAlpha = math.min(1, self.fadeTimer / self.fadeToBlackDuration)
        
        if self.fadeTimer >= self.fadeToBlackDuration then
            -- Fully black, show game over menu
            self.fadeState = "hold"
            self.fadeTimer = 0
            self.fadeAlpha = 1
            
            -- Create game over menu if needed
            if not self.gameMenu then
                local GameOverMenu = require("src.ui.game_over_menu")
                self.gameMenu = GameOverMenu:init(self.stats)
            else
                self.gameMenu:show(self.stats)
            end
        end
    elseif self.fadeState == "hold" then
        -- Holding black screen
        self.fadeTimer = self.fadeTimer + dt
        self.fadeAlpha = 1
    elseif self.fadeState == "from_black" then
        -- Fading from black (after restart)
        self.fadeTimer = self.fadeTimer + dt
        self.fadeAlpha = 1 - math.min(1, self.fadeTimer / self.fadeFromBlackDuration)
        
        if self.fadeTimer >= self.fadeFromBlackDuration then
            -- Fully visible, back to gameplay
            self.fadeState = "none"
            self.fadeTimer = 0
            self.fadeAlpha = 0
        end
    end
end

-- Restart the game
function GameOverSystem:restartGame()
    -- Optional fade hold if not already black
    if self.fadeAlpha < 1 then
        self.fadeState = "to_black"
        self.fadeTimer = 0
        return -- Will call restartGame again when fade completes
    end
    
    -- Start fade from black
    self.fadeState = "from_black"
    self.fadeTimer = 0
    
    -- Hide game over menu
    if self.gameMenu then
        self.gameMenu:hide()
    end
    
    -- Reset game state
    self.isGameOver = false
    
    -- Purge all entities
    self:purgeEntities()
    
    -- Reset player
    self:resetPlayer()
    
    -- Reset systems
    self:resetSystems()
    
    -- Reset statistics
    self:resetStats()
    
    -- MULTIPLE APPROACH CAMERA RESET: Use several techniques to guarantee proper camera centering
    
    -- 1. Wait for player position to stabilize (ensure player has a valid position)
    -- This small delay ensures the player has a chance to be fully positioned
    love.timer.sleep(0.01) -- Wait 10ms before reading player position
    
    -- Get player position
    local playerX, playerY
    local positionSource = "unknown"
    
    if self.player and self.player.collider then
        playerX, playerY = self.player.collider:getPosition()
        positionSource = "player.collider"
    elseif self.player then
        playerX, playerY = self.player.x, self.player.y
        positionSource = "player direct coords"
    else
        -- Fallback to screen center if player reference is invalid
        playerX, playerY = love.graphics.getWidth()/2, love.graphics.getHeight()/2
        positionSource = "screen center fallback"
        Debug.log("WARNING: Camera reset without valid player position, using screen center")
    end
    
    -- Always log player position details
    Debug.log("PLAYER SPAWN POSITION: x=" .. math.floor(playerX) .. ", y=" .. math.floor(playerY) .. 
              " (source: " .. positionSource .. ")")
    
    
    -- 2. Direct camera manipulation - most aggressive approach
    if _G.camera then
        -- Get current camera position before reset
        local prevCamX, prevCamY = _G.camera.x, _G.camera.y
        Debug.log("CAMERA PRE-RESET: x=" .. math.floor(prevCamX) .. ", y=" .. math.floor(prevCamY))
        
        -- Completely reset all camera parameters
        _G.camera:resetPosition(playerX, playerY) -- Uses our enhanced camera reset
        
        -- Direct coordinate setting as a fallback
        _G.camera.x = playerX
        _G.camera.y = playerY
        
        -- Cancel any ongoing camera behaviors
        _G.camera.isTransitioning = false
        _G.camera.shakeIntensity = 0
        _G.camera.lag = 1.0 -- Force immediate snap to position
        
        -- Get camera position after reset
        local newCamX, newCamY = _G.camera.x, _G.camera.y
        Debug.log("CAMERA POST-RESET: x=" .. math.floor(newCamX) .. ", y=" .. math.floor(newCamY))
        
        -- Debug camera offset from player
        local offsetX = math.floor(newCamX - playerX)
        local offsetY = math.floor(newCamY - playerY)
        Debug.log("CAMERA-PLAYER OFFSET: x=" .. offsetX .. ", y=" .. offsetY .. 
                  (offsetX == 0 and offsetY == 0 and " (PERFECT)" or " (MISALIGNED)"))
    else
        Debug.log("ERROR: Cannot reset camera - no global camera reference")
    end
    
    -- 3. GamePlay state flag - for redundancy
    if _G.Gamestate and _G.Gamestate.current() then
        local currentState = _G.Gamestate.current()
        if currentState.cameraResetNeeded ~= nil then
            currentState.cameraResetNeeded = true
            
            -- Also force set camera coordinates again on the next frame
            currentState.pendingCameraReset = {
                x = playerX,
                y = playerY,
                resetFrames = 3  -- Reset for 3 consecutive frames
            }
            
            if DEV.DEBUG_MASTER then
                Debug.log("Camera reset flags set in GamePlay state with 3-frame persistence")
            end
        end
    end
end

-- Purge all entities
function GameOverSystem:purgeEntities()
    if not self.gameSystems then return end
    
    -- Clear enemies manually
    if self.gameSystems.enemySystem then
        -- Destroy colliders if they exist
        for _, enemy in ipairs(self.gameSystems.enemySystem.enemies or {}) do
            if enemy.collider then
                enemy.collider:destroy()
            end
        end
        
        -- Clear the enemies table
        self.gameSystems.enemySystem.enemies = {}
        
        -- Debug output
        if _G.DEBUG_MASTER and _G.DEBUG_ENEMIES then
            Debug.log("Cleared all enemies for game restart")
        end
    end
    
    -- Clear projectiles (both player and enemy)
    local Projectile = require("src.projectile")
    Projectile:clearAll()
    
    local EnemyProjectile = require("src.entities.enemy_projectile")
    EnemyProjectile:clearAll()
    
    -- Clear gems
    local XPGem = require("src.entities.xp_gem")
    XPGem:clearAll()
    
    -- Clear any other entities (bombs, drones, etc.)
    -- These would be implemented in their respective systems
end

-- Reset player
function GameOverSystem:resetPlayer()
    if not self.player then return end
    
    -- Reset HP
    self.player.currentHP = Config.TUNING.PLAYER.MAX_HP or 200
    self.player.maxHP = Config.TUNING.PLAYER.MAX_HP or 200
    
    -- Reset timers
    self.player.invincibleTimer = 0
    self.player.damageFlashTimer = 0
    
    -- Reset position (if applicable)
    local centerX = 400
    local centerY = 300
    
    if self.player.collider then
        self.player.collider:setPosition(centerX, centerY) -- Center of screen
    else
        self.player.x = centerX
        self.player.y = centerY
    end
    
    -- Reset camera with animated transition to the player
    if _G.camera then
        -- Use the animated camera transition (1 second duration)
        _G.camera:resetPosition(centerX, centerY, true, 1.0)
        
        -- Also set the camera reset flag for GamePlay as a fallback
        if _G.gamePlay and _G.gamePlay.cameraResetNeeded ~= nil then
            _G.gamePlay.cameraResetNeeded = false -- Don't reset manually since we're using animation
        end
        
        if _G.DEBUG_MASTER then
            Debug.log("Starting 1-second camera transition to player at: " .. centerX .. "," .. centerY)
        end
    end
    
    -- Reset weapons
    if self.gameSystems and self.gameSystems.weaponSystem then
        -- Clear existing weapons
        self.gameSystems.weaponSystem.weapons = {}
        
        -- Add fresh pistol (level 1)
        self.gameSystems.weaponSystem:addWeapon("pistol")
    end
    
    -- Reset passives
    if self.gameSystems and self.gameSystems.passiveSystem then
        self.gameSystems.passiveSystem.passives = {}
    end
end

-- Reset systems
function GameOverSystem:resetSystems()
    if not self.gameSystems then return end
    
    -- Reset level system using proper reset method
    if self.gameSystems.levelUpSystem then
        self.gameSystems.levelUpSystem:reset()
        
        -- Force UI refresh
        if _G.DEBUG_MASTER then
            Debug.log("GameOverSystem: Reset level-up system to level 1")
        end
    end
    
    -- Reset enemy spawner
    if self.gameSystems.enemySpawner then
        self.gameSystems.enemySpawner.paused = false
        self.gameSystems.enemySpawner.spawnTimer = 0
    end
    
    -- Reset enemy system
    if self.gameSystems.enemySystem then
        self.gameSystems.enemySystem.paused = false
    end
    
    -- Reset gem system
    if self.gameSystems.gemSystem then
        self.gameSystems.gemSystem.currentXP = 0
        self.gameSystems.gemSystem.totalXP = 0
        self.gameSystems.gemSystem.currentLevel = 1
    end
    
    -- Reset game timer
    self.gameSystems.gameTimer = 0
end

-- Draw fade overlay
function GameOverSystem:draw()
    -- Skip if not initialized
    if not self.initialized then
        return
    end
    
    -- Draw fade overlay if fading
    if self.fadeAlpha > 0 then
        love.graphics.setColor(0, 0, 0, self.fadeAlpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    -- Draw game over menu if in game over state
    if self.isGameOver and self.fadeAlpha >= 1 and self.gameMenu then
        self.gameMenu:draw()
    end
end

-- Return the module
return GameOverSystem
