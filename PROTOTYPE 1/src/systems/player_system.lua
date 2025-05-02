-- player_system.lua
-- Manages player health, damage, and related effects

local L = require("lib.loader")
local Config = require("config.settings")
local PATHS = require("config.paths")
local Event = require("lib.event")
local Debug = require("src.debug")

-- Constants
local TUNING = Config.TUNING.PLAYER
local DEV = Config.DEV

-- The PlayerSystem module
local PlayerSystem = {
    -- Reference to the player
    player = nil,
    
    -- Flag for whether system has been initialized
    initialized = false
}

-- Initialize the player system
function PlayerSystem:init(player)
    -- Store player reference
    self.player = player
    
    -- Mark as initialized
    self.initialized = true
    
    -- Set up event listeners
    local Event = require("lib.event")
    Event.subscribe("ENEMY_PROJECTILE_HIT", function(data)
        if data and data.damage then
            self:applyDamage(data.damage, "enemyProjectile")
        end
    end)
    
    return self
end

-- Apply damage to the player with source tracking
function PlayerSystem:applyDamage(amount, source)
    -- Skip if not initialized
    if not self.initialized or not self.player then
        return false
    end
    
    -- Use player's existing takeDamage method with source tracking
    local damageApplied = self.player:takeDamage(amount, source)
    
    -- If damage was applied, flash and trigger events with source
    if damageApplied then
        -- Flash the player (visual feedback)
        self:flash()
        
        -- Debug output with damage source
        if _G.DEBUG_MASTER and _G.DEBUG_HP then
            Debug.log(string.format("Player took %d damage from %s! HP: %d/%d", 
                amount, source or "unknown", self.player.currentHP, self.player.maxHP))
        end
        
        -- Note: We don't dispatch PLAYER_DAMAGED event here because Player already does it
        -- This prevents duplicate event firing
    end
    
    return damageApplied
end

-- Flash player (visual feedback for damage)
function PlayerSystem:flash()
    -- Skip if not initialized
    if not self.initialized or not self.player then
        return
    end
    
    -- Set damage flash timer
    self.player.damageFlashTimer = Config.DEV.HP_DEBUG.DAMAGE_FLASH_TIME or 0.2
end

-- Update method for player system
function PlayerSystem:update(dt)
    -- Skip if not initialized
    if not self.initialized or not self.player then
        return
    end
    
    -- Any additional player system update logic would go here
end

-- Return the module
return PlayerSystem
