-- gem_system.lua
-- Manages XP gems, attraction, and level-up tracking

local L = require("lib.loader")
local PATHS = require("config.paths")
local Config = require("config.settings")
local Debug = require("src.debug")
local XPGem = require("src.entities.xp_gem")

-- Import events system
local Event = require("lib.event")

-- Constants
local TUNING = Config.TUNING.GEMS
local DEV = Config.DEV

-- The GemSystem module
local GemSystem = {
    -- XP tracking
    currentXP = 0,
    totalXP = 0,
    
    -- Level tracking
    currentLevel = 1,
    xpForNextLevel = 100, -- Will be calculated based on formula
    
    -- References
    player = nil,
    levelSystem = nil,
    
    -- State
    initialized = false
}

-- Level XP requirements formula
-- Each level requires more XP than the previous
local function calculateXPForLevel(level)
    -- Simple quadratic scaling formula
    -- Level 1: 100 XP
    -- Level 2: 250 XP
    -- Level 3: 450 XP
    -- etc.
    return 100 * level + 50 * (level * level)
end

-- Initialize the gem system
function GemSystem:init(player, levelSystem)
    -- Store references
    self.player = player
    self.levelSystem = levelSystem
    
    -- Reset XP counters
    self.currentXP = 0
    self.totalXP = 0
    self.currentLevel = 1
    self.xpForNextLevel = calculateXPForLevel(1)
    
    -- Initialize XP gem pool
    XPGem:initPool()
    
    -- Set up event listeners
    self:setupEvents()
    
    -- Mark as initialized
    self.initialized = true
    
    -- Debug output
    if _G.DEBUG_MASTER and _G.DEBUG_GEMS then
        Debug.log("Gem System initialized")
        Debug.log("XP for level 2: " .. self.xpForNextLevel)
    end
    
    return self
end

-- Set up event listeners
function GemSystem:setupEvents()
    -- Listen for enemy deaths to spawn gems
    Event.subscribe("ENEMY_KILLED", function(data)
        if not data or not data.enemy or not data.position then
            return
        end
        
        -- Get enemy data
        local enemy = data.enemy
        local position = data.position
        local cause = data.cause or "unknown"
        
        -- Only spawn gems if the enemy was killed by a player projectile
        if cause ~= "playerProjectile" then
            -- Debug output for non-projectile kills (no gems)
            if _G.DEBUG_MASTER and _G.DEBUG_GEMS then
                Debug.log(string.format("No gems spawned for %s kill (cause: %s)", 
                    enemy.displayName or "unknown enemy", cause))
            end
            return
        end
        
        -- Calculate gems to spawn based on XP multiplier
        local gemCount = math.max(1, math.floor(enemy.xpMultiplier or 1))
        
        -- Debug output
        if _G.DEBUG_MASTER and _G.DEBUG_GEMS then
            Debug.log(string.format("Spawning %d gems from %s (projectile kill)", 
                gemCount, enemy.displayName or "unknown enemy"))
        end
        
        -- Spawn gems at enemy's death position
        XPGem:spawnMultiple(position.x, position.y, gemCount, TUNING.BASE_XP)
    end)
    
    -- Listen for XP gained events
    Event.subscribe("XP_GAINED", function(data)
        if not data or not data.amount then
            return
        end
        
        -- Add XP
        self:addXP(data.amount)
    end)
    
    -- Debug output
    if _G.DEBUG_MASTER and _G.DEBUG_GEMS then
        Debug.log("Gem System event listeners set up")
    end
end

-- Add XP and check for level up
function GemSystem:addXP(amount)
    -- Skip if not initialized
    if not self.initialized then
        return
    end
    
    -- Keep track of total XP for stats
    self.totalXP = self.totalXP + amount
    
    -- Debug output
    if _G.DEBUG_MASTER and _G.DEBUG_GEMS then
        Debug.log(string.format("GemSystem: Collected %d XP", amount))
    end
    
    -- Let the LevelUpSystem handle all XP tracking and level ups
    if self.levelSystem then
        local success, message = self.levelSystem:addXP(amount)
        
        if _G.DEBUG_MASTER and _G.DEBUG_GEMS then
            if success then
                Debug.log("GemSystem: Successfully sent XP to LevelUpSystem - " .. message)
            else
                Debug.log("GemSystem: Failed to add XP to LevelUpSystem - " .. (message or "Unknown error"))
            end
        end
    else
        -- Fallback if no level system (shouldn't happen)
        if _G.DEBUG_MASTER then
            Debug.log("WARNING: GemSystem has no LevelUpSystem reference!")
        end
    end
end

-- Handle level up
function GemSystem:levelUp()
    -- Increment level
    self.currentLevel = self.currentLevel + 1
    
    -- Calculate XP overflow
    local overflow = self.currentXP - self.xpForNextLevel
    
    -- Reset current XP with overflow
    self.currentXP = overflow
    
    -- Calculate new XP threshold
    self.xpForNextLevel = calculateXPForLevel(self.currentLevel)
    
    -- Debug output
    if _G.DEBUG_MASTER and _G.DEBUG_GEMS then
        Debug.log(string.format("LEVEL UP! Now level %d. XP: %d/%d", 
            self.currentLevel, self.currentXP, self.xpForNextLevel))
    end
    
    -- Dispatch level up event
    Event.dispatch("LEVEL_UP_READY", {totalXp = self.totalXP})
end

-- Update the gem system
function GemSystem:update(dt)
    -- Skip if not initialized
    if not self.initialized then
        return
    end
    
    -- Update all active gems
    XPGem:updateAll(dt, self.player)
end

-- Draw all gems
function GemSystem:draw()
    -- Skip if not initialized
    if not self.initialized then
        return
    end
    
    -- Draw all active gems
    XPGem:drawAll()
    
    -- Draw debug visualization if enabled
    XPGem:drawDebug(self.player)
    
    -- Draw debug info if enabled
    if _G.DEBUG_MASTER and _G.DEBUG_GEMS then
        -- Store current graphics state
        local r, g, b, a = love.graphics.getColor()
        local font = love.graphics.getFont()
        
        -- Draw XP text in top-right corner
        love.graphics.setColor(0, 200/255, 255/255, 0.9)
        love.graphics.print(
            string.format("XP: %d/%d (Level %d)", 
                self.currentXP, self.xpForNextLevel, self.currentLevel),
            love.graphics.getWidth() - 200, 10
        )
        
        -- Restore graphics state
        love.graphics.setColor(r, g, b, a)
        love.graphics.setFont(font)
    end
end

-- Return the module
return GemSystem
