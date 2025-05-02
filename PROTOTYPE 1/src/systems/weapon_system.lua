-- weapon_system.lua
-- Handles weapon behaviours, cooldowns, and projectile spawning

local L = require("lib.loader")
local PATHS = require("config.paths")
local ItemDefs = require("src.data.item_defs")
local Projectile = require("src.projectile")
local Bomb = require("src.entities.bomb")
local Drone = require("src.entities.drone")

-- Get reference to global Debug flags
-- These are defined in main.lua as globals
local DEBUG_MASTER = _G.DEBUG_MASTER or false
local DEBUG_WEAPONS = _G.DEBUG_WEAPONS or false
local DEBUG_HITBOXES = _G.DEBUG_HITBOXES or false

-- Local references for better performance
local sin, cos, rad, pi = math.sin, math.cos, math.rad, math.pi

-- The WeaponSystem module
local WeaponSystem = {
    -- Equipped weapons
    weapons = {},
    
    -- Active drones (for drone behaviour)
    drones = {},
    
    -- Maximum slots for weapons
    maxSlots = 4,
    
    -- Flag for whether system has been initialized
    initialized = false
}

-- Behaviour registry for different weapon types
local behaviours = {
    -- Forward firing behaviour (straight shot)
    forward = function(weapon, x, y, aimX, aimY, player)
        -- Safety check for parameters
        if not (x and y and aimX and aimY) then return end
        
        if DEBUG_MASTER and DEBUG_WEAPONS then
            love.graphics.setColor(weapon.def.colour)
            love.graphics.circle("fill", x, y, 3)
        end
        
        -- Calculate projectile direction and starting position
        local angle = math.atan2(aimY, aimX)
        local startX = x + cos(angle) * 20  -- Offset to start outside player
        local startY = y + sin(angle) * 20
        
        -- Fire projectile
        Projectile:spawn(
            startX, startY,
            weapon.stats.projectileSpeed * cos(angle),
            weapon.stats.projectileSpeed * sin(angle),
            weapon.stats.damage,
            weapon.stats.range / weapon.stats.projectileSpeed,  -- Lifetime based on range and speed
            weapon.def.colour,
            nil,  -- No special radius
            nil,  -- No sprite
            {     -- Weapon info including stats for gameplay and debugging
                name = weapon.def.displayName,
                level = weapon.level,
                id = weapon.id,
                piercing = weapon.stats.piercing or 0,
                critChance = weapon.stats.critChance or 0,
                critMultiplier = weapon.stats.critMultiplier or 2
            }
        )
    end,
    
    -- Spread behaviour (multiple projectiles in a fan)
    spread = function(weapon, x, y, aimX, aimY, player)
        -- Safety check for parameters
        if not (x and y and aimX and aimY) then return end
        
        if DEBUG_MASTER and DEBUG_WEAPONS then
            love.graphics.setColor(weapon.def.colour)
            love.graphics.circle("fill", x, y, 3)
        end
        
        -- Calculate base angle from aim vector
        local baseAngle = math.atan2(aimY, aimX)
        
        -- Calculate spread angles based on number of projectiles
        local spreadRad = rad(weapon.stats.spreadAngle)
        local numProjectiles = weapon.stats.projectiles
        
        -- If only one projectile, shoot straight
        if numProjectiles == 1 then
            behaviours.forward(weapon, x, y, aimX, aimY, player)
            return
        end
        
        -- Calculate angle increment for evenly spaced projectiles
        local angleStep = spreadRad / (numProjectiles - 1)
        local startAngle = baseAngle - spreadRad / 2
        
        -- Spawn projectiles in a fan
        for i = 1, numProjectiles do
            local angle = startAngle + (i - 1) * angleStep
            local projectileX = x + cos(angle) * 20  -- Offset from player
            local projectileY = y + sin(angle) * 20  -- Offset from player
            Projectile:spawn(
                projectileX, projectileY,
                weapon.stats.projectileSpeed * cos(angle),
                weapon.stats.projectileSpeed * sin(angle),
                weapon.stats.damage,
                weapon.stats.range / weapon.stats.projectileSpeed,
                weapon.def.colour,
                nil,  -- No special radius
                nil,  -- No sprite
                {     -- Weapon info including stats for gameplay and debugging
                    name = weapon.def.displayName,
                    level = weapon.level,
                    id = weapon.id,
                    piercing = weapon.stats.piercing or 0,
                    critChance = weapon.stats.critChance or 0,
                    critMultiplier = weapon.stats.critMultiplier or 2
                }
            )
        end
    end,
    
    -- AOE behaviour (bombs that explode in an area)
    aoe = function(weapon, x, y, aimX, aimY, player)
        -- Safety check for parameters
        if not (x and y and aimX and aimY) then return end
        
        if DEBUG_MASTER and DEBUG_WEAPONS then
            love.graphics.setColor(weapon.def.colour)
            love.graphics.circle("fill", x, y, 3)
        end
        
        -- Calculate projectile direction and starting position
        local angle = math.atan2(aimY, aimX)
        local startX = x + cos(angle) * 20  -- Offset from player
        local startY = y + sin(angle) * 20
        
        -- Calculate target position based on range
        local targetX = x + cos(angle) * weapon.stats.range
        local targetY = y + sin(angle) * weapon.stats.range
        
        -- Spawn bomb entity
        Bomb:spawn(
            startX, startY,
            targetX, targetY,
            weapon.stats.projectileSpeed,
            weapon.stats.damage,
            weapon.stats.blastRadius,
            weapon.def.colour
        )
    end,
    
    -- Drone behaviour (orbiting autonomous units)
    drone = function(weapon, x, y, aimX, aimY, player)
        -- Safety check for parameters
        if not (x and y) then return end
        
        -- This is only called when the weapon is first equipped or on level-up
        -- We need to make sure to spawn/maintain the correct number of drones
        
        -- Remove any existing drones for this weapon
        for i = #WeaponSystem.drones, 1, -1 do
            local drone = WeaponSystem.drones[i]
            if drone.weaponId == weapon.id then
                table.remove(WeaponSystem.drones, i)
            end
        end
        
        -- Spawn new drones based on weapon level
        for i = 1, weapon.stats.projectiles do
            -- Calculate initial position around the player
            local angle = (i - 1) * (2 * pi / weapon.stats.projectiles)
            local droneX = x + cos(angle) * weapon.stats.orbitRadius
            local droneY = y + sin(angle) * weapon.stats.orbitRadius
            
            -- Create the drone with a specified offset angle
            local drone = Drone:spawn(
                droneX, droneY,
                player,
                weapon.stats.orbitRadius,
                weapon.stats.orbitSpeed,
                angle,  -- Initial offset angle
                weapon.stats.fireRate,
                weapon.stats.damage,
                weapon.stats.projectileSpeed,
                weapon.stats.range,
                weapon.def.colour
            )
            
            -- Store reference to the weapon it belongs to
            drone.weaponId = weapon.id
            
            -- Add to active drones list
            table.insert(WeaponSystem.drones, drone)
        end
        
        if DEBUG_MASTER and DEBUG_WEAPONS then
            love.graphics.setColor(weapon.def.colour)
            love.graphics.circle("fill", x, y, 3)
        end
    end
}

-- Initialize the weapon system
function WeaponSystem:init(player, passiveBuffs)
    -- Reset state
    self.weapons = {}
    self.drones = {}
    self.initialized = true
    
    return self
end

-- Add a weapon to the player's arsenal
function WeaponSystem:addWeapon(weaponId)
    -- Check if initialized
    if not self.initialized then
        self:init()
    end
    
    -- Prevent exceeding slot limit
    if #self.weapons >= self.maxSlots then
        return false, "No free weapon slots"
    end
    
    -- Find weapon definition
    local weaponDef = nil
    for _, def in ipairs(ItemDefs.weapons) do
        if def.id == weaponId then
            weaponDef = def
            break
        end
    end
    
    if not weaponDef then
        return false, "Unknown weapon: " .. weaponId
    end
    
    -- Create weapon instance
    local weapon = {
        id = weaponId,
        def = weaponDef,
        level = 1,
        cooldownTimer = 0,
        currentDelay = weaponDef.stats.fireRate, -- Initial delay based on base stats
        stats = {} -- Will be populated with calculated stats
    }
    
    -- Initialize stats with base values from definition
    for stat, value in pairs(weaponDef.stats) do
        weapon.stats[stat] = value
    end
    
    -- Add to equipped weapons
    table.insert(self.weapons, weapon)
    
    -- If it's a drone weapon, initialize drones
    if weaponDef.behaviour == "drone" then
        -- Get player reference (assuming it's passed during update)
        -- Drones will be properly spawned on the first update
    end
    
    return true, "Weapon added: " .. weaponDef.displayName
end

-- Level up a weapon
function WeaponSystem:levelUpWeapon(weaponIndex)
    -- Check if initialized
    if not self.initialized then
        return false, "Weapon system not initialized"
    end
    
    -- Validate index
    local weapon = self.weapons[weaponIndex]
    if not weapon then
        return false, "Invalid weapon index"
    end
    
    -- Check if already at max level
    if weapon.level >= weapon.def.maxLevel then
        return false, "Weapon already at max level"
    end
    
    -- Increase level
    weapon.level = weapon.level + 1
    
    -- Recalculate stats based on level-ups
    self:recalculateWeaponStats(weaponIndex)
    
    -- If it's a drone weapon, respawn drones with updated stats
    if weapon.def.behaviour == "drone" then
        -- This will be handled on the next update
    end
    
    return true, "Leveled up " .. weapon.def.displayName .. " to " .. weapon.level
end

-- Recalculate a weapon's stats based on its level and any passive buffs
function WeaponSystem:recalculateWeaponStats(weaponIndex, passiveBuffs)
    local weapon = self.weapons[weaponIndex]
    if not weapon then return end
    
    -- Start with base stats from definition
    for stat, value in pairs(weapon.def.stats) do
        weapon.stats[stat] = value
    end
    
    -- Apply level-up bonuses
    for stat, levelUp in pairs(weapon.def.levelUps) do
        local baseValue = weapon.stats[stat]
        
        if levelUp.mode == "flat" then
            -- Flat bonus (e.g. +5 per level)
            weapon.stats[stat] = baseValue + (levelUp.value * (weapon.level - 1))
        elseif levelUp.mode == "percent" then
            -- Percentage bonus/reduction (e.g. -10% per level for fire rate)
            local multiplier = 1 + ((levelUp.value / 100) * (weapon.level - 1))
            weapon.stats[stat] = baseValue * multiplier
        end
    end
    
    -- Apply passive buffs if provided
    if passiveBuffs then
        -- First apply flat bonuses
        for stat, buff in pairs(passiveBuffs.flat or {}) do
            if weapon.stats[stat] then
                weapon.stats[stat] = weapon.stats[stat] + buff
            end
        end
        
        -- Then apply percentage bonuses
        for stat, buff in pairs(passiveBuffs.percent or {}) do
            if weapon.stats[stat] then
                weapon.stats[stat] = weapon.stats[stat] * (1 + (buff / 100))
            end
        end
    end
    
    -- Update current fire delay
    weapon.currentDelay = weapon.stats.fireRate
end

-- Calculate fire delay with all modifiers (including passive buffs)
function WeaponSystem:calcFireDelay(weapon, passiveBuffs)
    local baseDelay = weapon.stats.fireRate
    
    -- Apply passive buffs if provided
    if passiveBuffs then
        -- Apply flat modifiers first
        if passiveBuffs.flat and passiveBuffs.flat.fireRate then
            baseDelay = baseDelay + passiveBuffs.flat.fireRate
        end
        
        -- Then apply percentage modifiers
        if passiveBuffs.percent and passiveBuffs.percent.fireRate then
            baseDelay = baseDelay * (1 + (passiveBuffs.percent.fireRate / 100))
        end
    end
    
    -- Ensure minimum delay
    return math.max(0.05, baseDelay)
end

-- Calculate damage with all modifiers (including passive buffs)
function WeaponSystem:calcDamage(weapon, passiveBuffs)
    local baseDamage = weapon.stats.damage
    
    -- Apply passive buffs if provided
    if passiveBuffs then
        -- Apply flat modifiers first
        if passiveBuffs.flat and passiveBuffs.flat.damage then
            baseDamage = baseDamage + passiveBuffs.flat.damage
        end
        
        -- Then apply percentage modifiers
        if passiveBuffs.percent and passiveBuffs.percent.damage then
            baseDamage = baseDamage * (1 + (passiveBuffs.percent.damage / 100))
        end
    end
    
    return baseDamage
end

-- Fire a weapon if its cooldown has elapsed
function WeaponSystem:fireWeapon(weaponIndex, x, y, aimX, aimY, player, passiveBuffs)
    local weapon = self.weapons[weaponIndex]
    if not weapon then return false end
    
    -- Skip if still on cooldown
    if weapon.cooldownTimer > 0 then
        return false
    end
    
    -- Get behavior function
    local behaviour = behaviours[weapon.def.behaviour]
    if not behaviour then
        return false
    end
    
    -- Fire the weapon using its behaviour
    behaviour(weapon, x, y, aimX, aimY, player)
    
    -- Reset cooldown timer
    weapon.cooldownTimer = self:calcFireDelay(weapon, passiveBuffs)
    
    return true
end

-- Main update function
function WeaponSystem:update(dt, x, y, aimX, aimY, player, passiveBuffs)
    -- Update all equipped weapons
    for i, weapon in ipairs(self.weapons) do
        -- Update cooldown timer
        if weapon.cooldownTimer > 0 then
            weapon.cooldownTimer = weapon.cooldownTimer - dt
        end
        
        -- Auto-fire weapons when cooldown is ready
        if weapon.cooldownTimer <= 0 then
            self:fireWeapon(i, x, y, aimX, aimY, player, passiveBuffs)
        end
    end
    
    -- Update all active drones
    for i = #self.drones, 1, -1 do
        local drone = self.drones[i]
        if drone.active then
            drone:update(dt, x, y, aimX, aimY)
        else
            -- Remove inactive drones
            table.remove(self.drones, i)
        end
    end
end

-- Get a specific weapon by ID
function WeaponSystem:getWeapon(weaponId)
    -- Return the weapon with matching ID
    for _, weapon in ipairs(self.weapons) do
        if weapon.id == weaponId then
            return weapon
        end
    end
    
    -- Return nil if not found
    return nil
end

-- Get level of a specific weapon by ID
function WeaponSystem:getLevel(weaponId)
    -- Find weapon with matching ID
    local weapon = self:getWeapon(weaponId)
    
    -- Return level if found, 0 otherwise
    if weapon then
        return weapon.level
    else
        return 0
    end
end

-- Add or upgrade a weapon by ID
function WeaponSystem:addOrUpgrade(weaponId)
    -- Check if weapon already exists
    local weapon = self:getWeapon(weaponId)
    
    if weapon then
        -- Upgrade existing weapon
        self:upgradeWeapon(weapon.id)
        return self:findSlotByWeaponId(weapon.id) -- Return slot index
    else
        -- Add new weapon
        self:addWeapon(weaponId)
        return self:findSlotByWeaponId(weaponId) -- Return slot index
    end
end

-- Find slot index by weapon ID
function WeaponSystem:findSlotByWeaponId(weaponId)
    for i, weapon in ipairs(self.weapons) do
        if weapon.id == weaponId then
            return i
        end
    end
    return nil
end

-- Activate all weapons to begin firing immediately
function WeaponSystem:activateAll()
    for _, weapon in ipairs(self.weapons) do
        -- Reset cooldowns to fire immediately
        weapon.cooldownTimer = 0
    end
end

-- Draw all weapons and effects
function WeaponSystem:draw()
    -- Draw debug visuals if enabled
    if DEBUG_MASTER and DEBUG_WEAPONS then
        for _, weapon in ipairs(self.weapons) do
            -- Debug visualizations are handled in the behaviour functions
        end
    end
    
    -- Draw all active drones
    for _, drone in ipairs(self.drones) do
        drone:draw()
    end
end

-- Handle key presses
function WeaponSystem:keypressed(key)
    -- For future hotkey implementation
end

-- Return the module
return WeaponSystem
