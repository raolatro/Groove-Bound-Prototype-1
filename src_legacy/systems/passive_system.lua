-- passive_system.lua
-- Handles passive items and buffs for player stats

local L = require("lib.loader")
local ItemDefs = require("src.data.item_defs")

-- The PassiveSystem module
local PassiveSystem = {
    -- Equipped passive items
    passives = {},
    
    -- Combined buffs by stat type (flat and percentage modifiers)
    buffs = {
        flat = {},     -- Flat bonuses (e.g. +5 damage)
        percent = {}   -- Percentage bonuses (e.g. +15% fire rate)
    },
    
    -- Flag for whether system has been initialized
    initialized = false
}

-- Initialize the passive system
function PassiveSystem:init()
    -- Reset state
    self.passives = {}
    self.buffs = {
        flat = {},
        percent = {}
    }
    self.initialized = true
    
    return self
end

-- Add a passive item to the player
function PassiveSystem:addPassive(passiveId)
    -- Check if initialized
    if not self.initialized then
        self:init()
    end
    
    -- Find passive definition
    local passiveDef = nil
    for _, def in ipairs(ItemDefs.passives) do
        if def.id == passiveId then
            passiveDef = def
            break
        end
    end
    
    if not passiveDef then
        return false, "Unknown passive: " .. passiveId
    end
    
    -- Check if we already have this passive
    for i, passive in ipairs(self.passives) do
        if passive.id == passiveId then
            -- Already have it, try to level it up
            return self:levelUpPassive(i)
        end
    end
    
    -- Create passive instance
    local passive = {
        id = passiveId,
        def = passiveDef,
        level = 1,
    }
    
    -- Add to equipped passives
    table.insert(self.passives, passive)
    
    -- Recalculate buffs
    self:recalculateBuffs()
    
    return true, "Passive added: " .. passiveDef.displayName
end

-- Level up a passive item
function PassiveSystem:levelUpPassive(passiveIndex)
    -- Check if initialized
    if not self.initialized then
        return false, "Passive system not initialized"
    end
    
    -- Validate index
    local passive = self.passives[passiveIndex]
    if not passive then
        return false, "Invalid passive index"
    end
    
    -- Check if already at max level
    if passive.level >= passive.def.maxLevel then
        return false, "Passive already at max level"
    end
    
    -- Increase level
    passive.level = passive.level + 1
    
    -- Recalculate buffs
    self:recalculateBuffs()
    
    return true, "Leveled up " .. passive.def.displayName .. " to " .. passive.level
end

-- Recalculate all combined buffs based on equipped passives
function PassiveSystem:recalculateBuffs()
    -- Reset buffs
    self.buffs = {
        flat = {},
        percent = {}
    }
    
    -- Process each passive
    for _, passive in ipairs(self.passives) do
        local effects = passive.def.effects[passive.level]
        
        if effects then
            for stat, effect in pairs(effects) do
                -- Check if it's a flat or percentage modifier
                if effect.mode == "flat" then
                    -- Initialize stat if needed
                    self.buffs.flat[stat] = self.buffs.flat[stat] or 0
                    -- Add flat modifier
                    self.buffs.flat[stat] = self.buffs.flat[stat] + effect.value
                elseif effect.mode == "percent" then
                    -- Initialize stat if needed
                    self.buffs.percent[stat] = self.buffs.percent[stat] or 0
                    -- Add percentage modifier
                    self.buffs.percent[stat] = self.buffs.percent[stat] + effect.value
                end
            end
        end
    end
    
    -- Trigger events to notify other systems of buff changes
    -- Example: EventSystem:trigger("PASSIVE_BUFFS_UPDATED", self.buffs)
end

-- Get the combined buffs
function PassiveSystem:getBuffs()
    return self.buffs
end

-- Apply buffs to a base stat value
function PassiveSystem:applyBuffs(stat, baseValue)
    -- Start with base value
    local result = baseValue
    
    -- Apply flat modifiers first
    if self.buffs.flat[stat] then
        result = result + self.buffs.flat[stat]
    end
    
    -- Then apply percentage modifiers
    if self.buffs.percent[stat] then
        result = result * (1 + (self.buffs.percent[stat] / 100))
    end
    
    return result
end

-- Return the module
return PassiveSystem
