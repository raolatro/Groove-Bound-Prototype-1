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

-- Calculate combined buffs from all passives
function PassiveSystem:calculateCombinedBuffs()
    -- Reset buffs
    self.buffs = {
        flat = {},
        percent = {}
    }
    
    Debug.log("PassiveSystem: Recalculating combined buffs for " .. #self.passives .. " passives")
    
    -- Process each passive
    for _, passive in ipairs(self.passives) do
        -- Handle different effect structures based on what's available
        local effects = nil
        
        -- Try to get effects from various possible locations
        if passive.def and passive.def.effects then
            if type(passive.def.effects) == "table" then
                if passive.def.effects[passive.level] then
                    -- Standard structure: passive.def.effects[level]
                    effects = passive.def.effects[passive.level]
                else
                    -- Alternative: effects table directly
                    effects = passive.def.effects
                end
            end
        elseif passive.effects then
            -- Direct effects property
            effects = passive.effects
        end
        
        if effects then
            Debug.log("Processing effects for " .. passive.id .. " (level " .. passive.level .. ")")
            
            for stat, effect in pairs(effects) do
                -- Support different effect structures
                if effect.mode and effect.value then
                    -- Standard {mode="flat", value=10} structure
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
                elseif effect.flat or effect.percent then
                    -- Alternative {flat=10, percent=5} structure
                    if effect.flat then
                        -- Initialize stat if needed
                        self.buffs.flat[stat] = self.buffs.flat[stat] or 0
                        -- Add flat modifier
                        self.buffs.flat[stat] = self.buffs.flat[stat] + effect.flat
                    end
                    
                    if effect.percent then
                        -- Initialize stat if needed
                        self.buffs.percent[stat] = self.buffs.percent[stat] or 0
                        -- Add percentage modifier
                        self.buffs.percent[stat] = self.buffs.percent[stat] + effect.percent
                    end
                elseif type(effect) == "number" then
                    -- Simple {stat=10} structure - assume it's flat
                    -- Initialize stat if needed
                    self.buffs.flat[stat] = self.buffs.flat[stat] or 0
                    -- Add flat modifier
                    self.buffs.flat[stat] = self.buffs.flat[stat] + effect
                end
            end
        else
            Debug.log("WARNING: No effects found for passive " .. passive.id)
        end
    end
    
    -- Trigger events to notify other systems of buff changes
    -- Example: EventSystem:trigger("PASSIVE_BUFFS_UPDATED", self.buffs)
end

-- Get a specific passive by ID
function PassiveSystem:getPassive(passiveId)
    -- Return the passive with matching ID
    for _, passive in ipairs(self.passives) do
        if passive.id == passiveId then
            return passive
        end
    end
    
    -- Return nil if not found
    return nil
end

-- Add a new passive by ID
function PassiveSystem:addPassive(passiveId)
    -- Check if passive already exists
    if self:getPassive(passiveId) then
        Debug.log("Passive '" .. passiveId .. "' already exists, not adding again")
        return false
    end
    
    -- Find passive definition
    local passiveDef = nil
    if ItemDefs and ItemDefs.passives then
        for _, def in ipairs(ItemDefs.passives) do
            if def.id == passiveId then
                passiveDef = def
                break
            end
        end
    end
    
    if not passiveDef then
        Debug.log("ERROR: Cannot find passive definition for '" .. passiveId .. "'")
        return false
    end
    
    -- Create new passive
    local passive = {
        id = passiveId,
        level = 1,
        def = passiveDef,
        effects = passiveDef.effects or {}
    }
    
    -- Add to passives list
    table.insert(self.passives, passive)
    
    -- Recalculate combined buffs
    self:calculateCombinedBuffs()
    
    Debug.log("Added new passive '" .. passiveId .. "' at level 1")
    return true
end

-- Get level of a specific passive by ID
function PassiveSystem:getLevel(passiveId)
    -- Find passive with matching ID
    local passive = self:getPassive(passiveId)
    
    -- Return level if found, 0 otherwise
    if passive then
        return passive.level
    else
        return 0
    end
end

-- Add or upgrade a passive by ID
function PassiveSystem:addOrUpgrade(passiveId)
    -- Check if passive already exists
    local passive = self:getPassive(passiveId)
    
    if passive then
        -- Upgrade existing passive
        self:upgradePassive(passive.id)
    else
        -- Add new passive
        self:addPassive(passiveId)
    end
end

-- Upgrade an existing passive by ID
function PassiveSystem:upgradePassive(passiveId)
    -- Find the passive to upgrade
    local passive = self:getPassive(passiveId)
    if not passive then
        Debug.log("ERROR: Cannot upgrade non-existent passive '" .. passiveId .. "'")
        return false
    end
    
    -- Increment the level
    passive.level = passive.level + 1
    
    -- Update stats based on new level
    self:updatePassiveEffects(passive)
    
    -- Recalculate combined buffs
    self:calculateCombinedBuffs()
    
    Debug.log("Upgraded passive '" .. passiveId .. "' to level " .. passive.level)
    return true
end

-- Update a passive's effects based on its level
function PassiveSystem:updatePassiveEffects(passive)
    -- Apply level-based scaling to passive effects
    -- Each passive type has different scaling logic
    local passiveType = passive.id:match("(.+)_")
    
    if passive.effects then
        -- Scale each effect based on level
        for stat, effect in pairs(passive.effects) do
            -- Linear scaling for now, can be changed to more complex formulas later
            if effect.flat then
                effect.flat = effect.flat * passive.level
            end
            if effect.percent then
                effect.percent = effect.percent * passive.level
            end
        end
    end
end

-- Get active buff summaries for UI display
function PassiveSystem:getActiveBuffSummaries()
    local summaries = {}
    
    -- Safety check - ensure we have passives array
    if not self.passives then
        Debug.log("WARNING: PassiveSystem has no passives array")
        return summaries
    end
    
    Debug.log("PassiveSystem: Generating summaries for " .. #self.passives .. " passives")
    
    -- For each passive, create a summary entry
    for i, passive in ipairs(self.passives) do
        -- Make sure the passive is valid
        if not passive then
            Debug.log("WARNING: Nil passive at index " .. i)
            goto continue
        end
        
        if not passive.id then
            Debug.log("WARNING: Passive at index " .. i .. " has no ID")
            goto continue
        end
        
        -- Extract info from passive with fallbacks for every property
        local name = "Unknown Passive"
        local description = "No description"
        local icon = nil
        
        -- Try to get display name from various places
        if passive.def and passive.def.displayName then
            name = passive.def.displayName
        elseif passive.displayName then
            name = passive.displayName
        elseif passive.name then
            name = passive.name
        else
            -- If all else fails, format the ID
            name = passive.id:gsub("_", " "):gsub("%a[%w_']*", function(word)
                return word:sub(1,1):upper() .. word:sub(2)
            end)
        end
        
        -- Try to get description from various places
        if passive.def and passive.def.description then
            description = passive.def.description
        elseif passive.description then
            description = passive.description
        end
        
        -- Build the summary
        local summary = {
            id = passive.id,
            name = name,
            level = passive.level or 1,
            description = description,
            icon = icon,
            effects = {}
        }
        
        -- Get effects if available
        if passive.effects then
            summary.effects = passive.effects
        elseif passive.def and passive.def.effects then
            -- Handle both formats of effects (array by level or direct table)
            if type(passive.def.effects) == "table" then
                if passive.def.effects[passive.level] then
                    summary.effects = passive.def.effects[passive.level]
                else
                    summary.effects = passive.def.effects
                end
            end
        end
        
        -- Add to summaries list
        table.insert(summaries, summary)
        
        -- Label to continue the loop on errors
        ::continue::
    end
    
    Debug.log("PassiveSystem: Generated " .. #summaries .. " buff summaries")
    return summaries
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
