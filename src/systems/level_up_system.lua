-- level_up_system.lua
-- Handles player leveling, XP, and item upgrades

local L = require("lib.loader")
local PATHS = require("config.paths")
local ItemDefs = require("src.data.item_defs")
local LevelUpShop = require("src.ui.level_up_shop")
local Config = require("config.settings")
local Event = require("lib.event")
local Debug = require("src.debug")

-- Local shorthand
local TUNING = Config.TUNING
local DEV = Config.DEV

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
    player = nil,
    
    -- Shop system
    shop = nil,
    shopOpen = false,
    
    -- Callbacks
    onLevelUp = nil,
    onChoiceSelected = nil,
    
    -- Flag for whether system has been initialized
    initialized = false
}

-- Initialize the level-up system
function LevelUpSystem:init(weaponSystem, passiveSystem, player)
    -- Store system references
    self.weaponSystem = weaponSystem
    self.passiveSystem = passiveSystem
    self.player = player
    
    -- Reset state
    self.currentXP = 0
    self.currentLevel = 1
    self.xpToNextLevel = 100
    self.isLevelingUp = false
    self.choices = {}
    self.shopOpen = false
    self.flashActive = false
    self.flashTimer = 0
    
    -- Initialize level-up shop with correct references
    self.shop = LevelUpShop:init(player, self)
    
    -- Make sure weapon and passive system references are set
    if self.weaponSystem and self.passiveSystem then
        self.shop.weaponSystem = self.weaponSystem
        self.shop.passiveSystem = self.passiveSystem
        
        if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
            Debug.log("LevelUpSystem: Set shop references to weapon and passive systems")
        end
    else
        if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
            Debug.log("LevelUpSystem: WARNING - Missing weapon or passive system references")
        end
    end
    
    -- Register for shop closure event
    local Event = require("lib.event")
    Event.subscribe("LEVEL_UP_SHOP_CLOSED", function(data)
        self.shopOpen = false
        self.isLevelingUp = false
    end)
    
    -- Mark as initialized
    self.initialized = true
    
    if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
        Debug.log("LevelUpSystem initialized with shop")
    end
    
    return self
end

-- Calculate XP needed for a given level
function LevelUpSystem:calculateXPForLevel(level)
    -- More linear scaling formula with reasonable progression
    -- Start at 100, then add 25 per level
    local baseXP = 100
    local xpPerLevel = 25
    local xpNeeded = baseXP + (xpPerLevel * (level - 1))
    
    if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
        Debug.log(string.format("LevelUpSystem: XP needed for level %d = %d", level, xpNeeded))
    end
    
    return xpNeeded
end

-- Add XP to the player
function LevelUpSystem:addXP(amount)
    -- Check if initialized
    if not self.initialized then
        Debug.log("Level-up system not initialized")
        return false, "Level-up system not initialized"
    end
    
    -- Skip if level-up shop is open or flash is active
    if self.shopOpen or self.flashActive or self.isLevelingUp then
        if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
            Debug.log("LevelUpSystem: Skipping XP add - level up in progress")
        end
        return false, "Level-up in progress"
    end
    
    -- Validate input
    if not amount or type(amount) ~= "number" or amount <= 0 then
        return false, "Invalid XP amount"
    end
    
    -- Add XP with debug info
    local oldXP = self.currentXP
    self.currentXP = self.currentXP + amount
    
    if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
        Debug.log(string.format("⭐ LevelUpSystem: Added %d XP. Now %d/%d XP (Level %d)", 
                           amount, self.currentXP, self.xpToNextLevel, self.currentLevel))
    end
    
    -- Check for level up
    if self.currentXP >= self.xpToNextLevel then
        -- Level up!
        self.currentLevel = self.currentLevel + 1
        
        -- Calculate surplus XP
        local surplus = self.currentXP - self.xpToNextLevel
        
        -- Set new XP threshold
        self.currentXP = surplus
        self.xpToNextLevel = self:calculateXPForLevel(self.currentLevel + 1)
        
        if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
            Debug.log(string.format("LevelUpSystem: LEVEL UP! Now level %d with %d surplus XP. Next level at %d XP", 
                                self.currentLevel, surplus, self.xpToNextLevel))
        end
        
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
    -- Ensure we have necessary systems
    if not self.shop then
        if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
            Debug.log("LevelUpSystem: Cannot trigger level up - shop not created")
        end
        return
    end
    
    -- Check if shop is already open (avoid double trigger)
    if self.shopOpen or self.isLevelingUp then
        if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
            Debug.log("LevelUpSystem: Shop already open, ignoring duplicate trigger")
        end
        return
    end
    
    -- CRITICAL SEQUENCE: First pause the game, then open shop
    
    -- 1. Set leveling up state BEFORE dispatching events
    self.isLevelingUp = true
    self.shopOpen = true
    
    if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
        Debug.log("LevelUpSystem: Pausing game for level-up shop")
    end
    
    -- 2. First dispatch event to pause gameplay
    -- This ensures the game is paused BEFORE the shop opens
    Event.dispatch("LEVEL_UP_STARTED", {})
    
    -- 3. Give a tiny delay to ensure pause is processed
    -- Delay is handled through the engine's timing system
    local pauseDelay = 0.05 -- 50ms delay for pause to take effect
    self.shop.openDelay = pauseDelay
    self.shop.delayTimer = 0
    self.shop.pendingOpen = true
    self.shop.player = self.player
    
    if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
        Debug.log("LevelUpSystem: Shop prepared for opening with slight delay")
    end
    
    if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
        Debug.log("LevelUpSystem: Level up triggered, shop opened")
    end
    
    -- Call the level up callback if provided (legacy support)
    if self.onLevelUp then
        self.onLevelUp(self.currentLevel, nil)
    end
end

-- Get current level information for UI
function LevelUpSystem:getLevelInfo()
    -- Calculate progress percentage for UI bar
    local progress = self.currentXP / self.xpToNextLevel
    if progress > 1 then progress = 1 end
    
    -- Return complete level info object
    return {
        level = self.currentLevel,
        currentXP = self.currentXP,
        nextLevelXP = self.xpToNextLevel,
        progress = progress
    }
end

-- Reset the level-up system (called on game restart)
function LevelUpSystem:reset()
    -- Reset XP and level
    self.currentXP = 0
    self.currentLevel = 1
    self.xpToNextLevel = self:calculateXPForLevel(2) -- Reset to level 2 threshold
    
    -- Reset state flags
    self.isLevelingUp = false
    self.shopOpen = false
    
    -- Also reset the shop if it exists
    if self.shop then
        self.shop.isOpen = false
    end
    
    if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
        Debug.log("LevelUpSystem: Reset to Level 1 (0/" .. self.xpToNextLevel .. " XP)")
    end
    
    return self
end

-- Update the level-up system
function LevelUpSystem:update(dt)
    -- Skip if not initialized
    if not self.initialized then
        return
    end
    
    -- Update shop - simple update as the flash effect has been removed
    if self.shop then
        -- Update the shop UI
        self.shop:update(dt)
    end
end

-- Draw the level-up UI
function LevelUpSystem:draw()
    -- Skip if not initialized
    if not self.initialized then
        return
    end
    
    -- Draw shop if open - double-check both the system flag and the shop state
    if self.shop and (self.shopOpen or self.shop.isOpen) then
        -- Ensure shopOpen state is consistent between system and shop
        if self.shopOpen ~= self.shop.isOpen then
            self.shopOpen = self.shop.isOpen -- Sync the states
            if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
                Debug.log("LevelUpSystem:draw - Syncing shop state: " .. tostring(self.shopOpen))
            end
        end
        
        if DEV.DEBUG_MASTER and self.shopOpen then
            Debug.log("LevelUpSystem:draw - Drawing shop")
        end
        
        -- Call shop's draw method to render UI
        self.shop:draw()
    else
        -- Only log if debug is enabled and with lower frequency to avoid spam
        if DEV.DEBUG_MASTER and love.timer.getTime() % 1 < 0.1 then
            Debug.log("LevelUpSystem:draw - Shop not open or not initialized")
        end
    end
end

-- Handle keyboard input for the shop
function LevelUpSystem:keypressed(key)
    -- Skip if shop not open
    if not self.shopOpen or not self.shop then
        return false
    end
    
    return self.shop:keypressed(key)
end

-- Handle gamepad input for the shop
function LevelUpSystem:gamepadpressed(gamepad, button)
    -- Skip if shop not open
    if not self.shopOpen or not self.shop then
        return false
    end
    
    return self.shop:gamepadpressed(gamepad, button)
end

-- Handle mouse input for the shop
function LevelUpSystem:mousepressed(x, y, button)
    -- Skip if shop not open
    if not self.shopOpen or not self.shop then
        return false
    end
    
    return self.shop:mousepressed(x, y, button)
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
