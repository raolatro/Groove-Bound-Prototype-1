-- level_up_system.lua
-- Handles player leveling, XP, and item upgrades

local L = require("lib.loader")
local PATHS = require("config.paths")
local ItemDefs = require("src.data.item_defs")

-- The LevelUpSystem module
local LevelUpSystem = {
    -- XP and level tracking
    currentXP = 0,
    currentLevel = 1,
    xpToNextLevel = 100,  -- Base XP needed for level 2
    
    -- Level-up state
    isLevelingUp = false,
    choices = {},
    
    -- References to other systems
    weaponSystem = nil,
    passiveSystem = nil,
    
    -- Callbacks
    onLevelUp = nil,
    onChoiceSelected = nil,
    
    -- Flag for whether system has been initialized
    initialized = false
}

-- Initialize the level-up system
function LevelUpSystem:init(weaponSystem, passiveSystem)
    -- Store system references
    self.weaponSystem = weaponSystem
    self.passiveSystem = passiveSystem
    
    -- Reset state
    self.currentXP = 0
    self.currentLevel = 1
    self.xpToNextLevel = 100
    self.isLevelingUp = false
    self.choices = {}
    
    -- Mark as initialized
    self.initialized = true
    
    return self
end

-- Calculate XP needed for a given level
function LevelUpSystem:calculateXPForLevel(level)
    -- Simple exponential scaling formula
    return math.floor(100 * math.pow(1.2, level - 1))
end

-- Add XP to the player
function LevelUpSystem:addXP(amount)
    -- Check if initialized
    if not self.initialized then
        return false, "Level-up system not initialized"
    end
    
    -- Add XP
    self.currentXP = self.currentXP + amount
    
    -- Check for level up
    if self.currentXP >= self.xpToNextLevel then
        -- Level up!
        self.currentLevel = self.currentLevel + 1
        
        -- Calculate surplus XP
        local surplus = self.currentXP - self.xpToNextLevel
        
        -- Set new XP threshold
        self.currentXP = surplus
        self.xpToNextLevel = self:calculateXPForLevel(self.currentLevel + 1)
        
        -- Trigger level up sequence
        self:triggerLevelUp()
        
        return true, "Leveled up to " .. self.currentLevel
    end
    
    return true, "Added " .. amount .. " XP"
end

-- Set the current XP values directly (used by UI and external systems)
function LevelUpSystem:setXP(current, target)
    -- Skip if not initialized
    if not self.initialized then
        return false
    end
    
    -- Only update if values are provided
    if current ~= nil then
        self.currentXP = current
    end
    
    if target ~= nil then
        self.xpToNextLevel = target
    end
    
    return true
end

-- Trigger the level-up sequence
function LevelUpSystem:triggerLevelUp()
    -- Set leveling up state
    self.isLevelingUp = true
    
    -- Generate choices
    self:generateChoices()
    
    -- Call the level up callback if provided
    if self.onLevelUp then
        self.onLevelUp(self.currentLevel, self.choices)
    end
end

-- Generate level-up choices
function LevelUpSystem:generateChoices()
    self.choices = {}
    
    -- Determine if we can add new weapons
    local canAddWeapon = #self.weaponSystem.weapons < self.weaponSystem.maxSlots
    
    -- First choice: New weapon (if not maxed) or upgrade existing
    if canAddWeapon then
        -- Find weapons we don't already have
        local availableWeapons = {}
        local equippedWeaponIds = {}
        
        -- Get IDs of equipped weapons
        for _, weapon in ipairs(self.weaponSystem.weapons) do
            equippedWeaponIds[weapon.id] = true
        end
        
        -- Find available weapons
        for _, weaponDef in ipairs(ItemDefs.weapons) do
            if not equippedWeaponIds[weaponDef.id] then
                table.insert(availableWeapons, weaponDef)
            end
        end
        
        -- If we have available weapons, offer a random one
        if #availableWeapons > 0 then
            local randomWeapon = availableWeapons[math.random(#availableWeapons)]
            table.insert(self.choices, {
                type = "new_weapon",
                id = randomWeapon.id,
                name = randomWeapon.displayName,
                colour = randomWeapon.colour,
                description = "New weapon: " .. randomWeapon.displayName
            })
        end
    end
    
    -- Second choice: Upgrade an existing weapon (if any weapons equipped)
    if #self.weaponSystem.weapons > 0 then
        -- Find weapons that can be upgraded
        local upgradableWeapons = {}
        
        for i, weapon in ipairs(self.weaponSystem.weapons) do
            if weapon.level < weapon.def.maxLevel then
                table.insert(upgradableWeapons, {
                    index = i,
                    weapon = weapon
                })
            end
        end
        
        -- If we have upgradable weapons, offer a random one
        if #upgradableWeapons > 0 then
            local randomUpgrade = upgradableWeapons[math.random(#upgradableWeapons)]
            table.insert(self.choices, {
                type = "upgrade_weapon",
                index = randomUpgrade.index,
                id = randomUpgrade.weapon.id,
                name = randomUpgrade.weapon.def.displayName,
                level = randomUpgrade.weapon.level,
                colour = randomUpgrade.weapon.def.colour,
                description = "Upgrade " .. randomUpgrade.weapon.def.displayName .. " to level " .. (randomUpgrade.weapon.level + 1)
            })
        end
    end
    
    -- Third choice: New passive item or upgrade existing
    local hasPassives = #self.passiveSystem.passives > 0
    local randomPassiveType = math.random(2)
    
    if hasPassives and randomPassiveType == 1 then
        -- Upgrade an existing passive
        local upgradablePassives = {}
        
        for i, passive in ipairs(self.passiveSystem.passives) do
            if passive.level < passive.def.maxLevel then
                table.insert(upgradablePassives, {
                    index = i,
                    passive = passive
                })
            end
        end
        
        -- If we have upgradable passives, offer a random one
        if #upgradablePassives > 0 then
            local randomUpgrade = upgradablePassives[math.random(#upgradablePassives)]
            table.insert(self.choices, {
                type = "upgrade_passive",
                index = randomUpgrade.index,
                id = randomUpgrade.passive.id,
                name = randomUpgrade.passive.def.displayName,
                level = randomUpgrade.passive.level,
                colour = randomUpgrade.passive.def.colour,
                description = "Upgrade " .. randomUpgrade.passive.def.displayName .. " to level " .. (randomUpgrade.passive.level + 1)
            })
        else
            -- No upgradable passives, offer a new one
            randomPassiveType = 2
        end
    end
    
    if randomPassiveType == 2 then
        -- Offer a new passive
        local availablePassives = {}
        local equippedPassiveIds = {}
        
        -- Get IDs of equipped passives
        for _, passive in ipairs(self.passiveSystem.passives) do
            equippedPassiveIds[passive.id] = true
        end
        
        -- Find available passives
        for _, passiveDef in ipairs(ItemDefs.passives) do
            if not equippedPassiveIds[passiveDef.id] then
                table.insert(availablePassives, passiveDef)
            end
        end
        
        -- If we have available passives, offer a random one
        if #availablePassives > 0 then
            local randomPassive = availablePassives[math.random(#availablePassives)]
            table.insert(self.choices, {
                type = "new_passive",
                id = randomPassive.id,
                name = randomPassive.displayName,
                colour = randomPassive.colour,
                description = "New passive: " .. randomPassive.displayName
            })
        end
    end
    
    -- Ensure we have at least three choices (repeat if necessary)
    while #self.choices < 3 and #self.choices > 0 do
        local randomChoice = self.choices[math.random(#self.choices)]
        table.insert(self.choices, randomChoice)
    end
end

-- Apply the selected choice
function LevelUpSystem:applyChoice(choiceIndex)
    -- Check if initialized and leveling up
    if not self.initialized or not self.isLevelingUp then
        return false, "Not in level-up state"
    end
    
    -- Validate choice index
    local choice = self.choices[choiceIndex]
    if not choice then
        return false, "Invalid choice index"
    end
    
    local result = false
    local message = ""
    
    -- Apply the choice based on its type
    if choice.type == "new_weapon" then
        result, message = self.weaponSystem:addWeapon(choice.id)
    elseif choice.type == "upgrade_weapon" then
        result, message = self.weaponSystem:levelUpWeapon(choice.index)
    elseif choice.type == "new_passive" then
        result, message = self.passiveSystem:addPassive(choice.id)
    elseif choice.type == "upgrade_passive" then
        result, message = self.passiveSystem:levelUpPassive(choice.index)
    end
    
    -- End level-up state
    self.isLevelingUp = false
    self.choices = {}
    
    -- Call the choice selected callback if provided
    if self.onChoiceSelected then
        self.onChoiceSelected(choice, result, message)
    end
    
    return result, message
end

-- Draw level-up UI (placeholder)
function LevelUpSystem:draw()
    -- This would be implemented in a separate UI component
end

-- Get current level information
function LevelUpSystem:getLevelInfo()
    return {
        level = self.currentLevel,
        currentXP = self.currentXP,
        nextLevelXP = self.xpToNextLevel,
        progress = self.currentXP / self.xpToNextLevel
    }
end

-- Return the module
return LevelUpSystem
