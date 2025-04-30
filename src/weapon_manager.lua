-- Weapon Manager for Groove Bound
-- Handles weapon selection, acquisition, and updates

local L = require("lib.loader")
local Config = require("config.settings")
local PATHS = require("config.paths")
local WeaponBase = require("src.weapons.base")
local WeaponDefs = require("config.weapons")

-- Shorthand for readability
local DEV = Config.DEV
local TUNING = Config.TUNING.WEAPONS

-- Local debug flag, ANDed with master debug
local DEBUG_WEAPONS = false

-- Weapon manager singleton
local WeaponManager = {
    -- Player's active weapons, indexed by slot
    activeWeapons = {},
    
    -- Cooldown for acquiring new weapons
    acquireCooldown = 0
}

-- Initialize the weapon manager
function WeaponManager:init()
    self.activeWeapons = {}
    self.acquireCooldown = 0
    
    if DEBUG_WEAPONS and DEV.DEBUG_MASTER then
        print("Weapon Manager initialized")
    end
end

-- Add a weapon to the player's arsenal
function WeaponManager:addWeapon(slotName, weaponID)
    -- Check if the weapon definition exists
    if not WeaponDefs[weaponID] then
        if DEBUG_WEAPONS and DEV.DEBUG_MASTER then
            print("Error: Weapon '" .. weaponID .. "' not found in weapon definitions")
        end
        return nil
    end
    
    -- Check if on cooldown
    if self.acquireCooldown > 0 then
        if DEBUG_WEAPONS and DEV.DEBUG_MASTER then
            print("Cannot add weapon - on cooldown: " .. self.acquireCooldown .. "s remaining")
        end
        return nil
    end
    
    -- Create the weapon instance
    local weaponDef = WeaponDefs[weaponID]
    local weapon = WeaponBase:new(weaponDef)
    
    -- Store in the appropriate slot
    local slot = slotName or weaponDef.slot
    self.activeWeapons[slot] = weapon
    
    -- Start acquisition cooldown
    self.acquireCooldown = TUNING.ACQUIRE_COOLDOWN
    
    if DEBUG_WEAPONS and DEV.DEBUG_MASTER then
        print("Added weapon '" .. weaponID .. "' to slot '" .. slot .. "'")
    end
    
    return weapon
end

-- Remove a weapon from a slot
function WeaponManager:removeWeapon(slotName)
    if not self.activeWeapons[slotName] then
        return false
    end
    
    if DEBUG_WEAPONS and DEV.DEBUG_MASTER then
        print("Removed weapon from slot '" .. slotName .. "'")
    end
    
    self.activeWeapons[slotName] = nil
    return true
end

-- Get a weapon by slot
function WeaponManager:getWeapon(slotName)
    return self.activeWeapons[slotName]
end

-- Update all weapons
function WeaponManager:updateAll(dt, player)
    -- Update acquisition cooldown
    if self.acquireCooldown > 0 then
        self.acquireCooldown = self.acquireCooldown - dt
    end
    
    -- Update each weapon
    for slot, weapon in pairs(self.activeWeapons) do
        weapon:update(dt, player)
    end
end

-- Draw all weapons
function WeaponManager:drawAll()
    for slot, weapon in pairs(self.activeWeapons) do
        weapon:draw()
    end
end

-- Draw debug visualization
function WeaponManager:drawDebug()
    if not (DEBUG_WEAPONS and DEV.DEBUG_MASTER) then return end
    
    -- Draw each weapon's debug information
    for slot, weapon in pairs(self.activeWeapons) do
        weapon:drawDebug()
    end
    
    -- Display weapon inventory
    love.graphics.setColor(1, 1, 0, 0.8)
    local y = 100
    love.graphics.print("WEAPONS:", 10, y)
    y = y + 20
    
    -- List all equipped weapons
    for slot, weapon in pairs(self.activeWeapons) do
        love.graphics.print(
            string.format("- %s: %s (DMG: %d)", slot, weapon.name, weapon.damage),
            20, y
        )
        y = y + 15
    end
end

-- Handle key press
function WeaponManager:keypressed(key)
    -- Toggle weapons debug (requires master debug to be on)
    if key == Config.CONTROLS.KEYBOARD.DEBUG.TOGGLE_WEAPONS then
        if not love.keyboard.isDown("lshift", "rshift") then
            DEBUG_WEAPONS = not DEBUG_WEAPONS
            DEV.DEBUG_WEAPONS = DEBUG_WEAPONS
            if DEV.DEBUG_MASTER then
                print("Weapons debug: " .. (DEBUG_WEAPONS and "ON" or "OFF"))
            end
        end
    end
    
    -- Forward key presses to all weapons
    for slot, weapon in pairs(self.activeWeapons) do
        if weapon.keypressed then
            weapon:keypressed(key)
        end
    end
end

return WeaponManager
