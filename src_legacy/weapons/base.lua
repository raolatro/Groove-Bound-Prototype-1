-- Base Weapon Class for Groove Bound
-- Provides the foundation for all weapon types

local L = require("lib.loader")
local Config = require("config.settings")
local PATHS = require("config.paths")
local Projectile = require("src.projectile")

-- Shorthand for readability
local DEV = Config.DEV
local TUNING = Config.TUNING

-- Local debug flag, ANDed with master debug
local DEBUG_WEAPONS = false

-- Weapon base metatable
local WeaponBase = {}
WeaponBase.__index = WeaponBase

-- Constructor from weapon definition
function WeaponBase:new(defTable)
    local instance = {
        -- Basic properties
        id = defTable.id,
        name = defTable.name,
        slot = defTable.slot,
        category = defTable.category,
        
        -- Attack properties
        damage = defTable.damage or 10,
        cooldown = defTable.cooldown or TUNING.WEAPONS.DEFAULT_COOLDOWN,
        projectileSpeed = defTable.projectileSpeed or 500,
        projectileCount = defTable.projectileCount or 1,
        spread = defTable.spread or 0,
        area = defTable.area or 5,
        
        -- Current state
        cooldownTimer = 0,
        isReady = true,
        
        -- Assets
        sprite = defTable.sprite,
        projectileSprite = defTable.projectileSprite,
        sfx = defTable.sfx,
        
        -- Additional category and weapon attributes
        catAttrib = defTable.catAttrib or {},
        weaponAttrib = defTable.weaponAttrib or {},
        
        -- Owner reference (will be set by manager)
        owner = nil,
        
        -- Hit area for debug visualization
        hitArea = {
            x = 0,
            y = 0,
            r = defTable.area or 5
        }
    }
    
    -- Load sprite if provided
    if instance.sprite then
        instance.spriteImg = L.Asset.safeImage(instance.sprite, 32, 32)
    end
    
    -- Debug info
    if DEBUG_WEAPONS and DEV.DEBUG_MASTER then
        print("Weapon created: " .. instance.name .. " (ID: " .. instance.id .. ")")
    end
    
    return setmetatable(instance, self)
end

-- Update weapon state
function WeaponBase:update(dt, owner)
    -- Update owner reference
    self.owner = owner
    
    -- Update hit area position to match owner
    self.hitArea.x = owner.x
    self.hitArea.y = owner.y
    
    -- Update cooldown timer
    if self.cooldownTimer > 0 then
        self.cooldownTimer = self.cooldownTimer - dt
        self.isReady = false
    else
        self.isReady = true
    end
    
    -- Auto-fire if owner is firing
    if owner.input and owner.input.fire and self.isReady then
        -- Get aim direction from owner
        local aimX, aimY = owner:getAimVector()
        self:fire(owner, aimX, aimY)
    end
end

-- Fire the weapon
function WeaponBase:fire(owner, dirX, dirY)
    if not self.isReady then return end
    
    -- Start cooldown
    self.cooldownTimer = self.cooldown
    self.isReady = false
    
    -- Get origin position (where projectiles spawn)
    local originX = owner.x
    local originY = owner.y
    
    -- Normalize direction vector if not already
    local length = math.sqrt(dirX * dirX + dirY * dirY)
    if length > 0 then
        dirX = dirX / length
        dirY = dirY / length
    else
        -- Default to right if no direction
        dirX, dirY = 1, 0
    end
    
    -- Fire projectile(s)
    for i = 1, self.projectileCount do
        -- Calculate spread
        local spreadAngle = 0
        if self.projectileCount > 1 then
            -- Distribute projectiles evenly within spread
            spreadAngle = -self.spread + (2 * self.spread * (i - 1) / (self.projectileCount - 1))
        elseif self.spread > 0 then
            -- Single projectile gets random spread
            spreadAngle = love.math.random(-self.spread, self.spread)
        end
        
        -- Apply spread to direction
        local cosA = math.cos(spreadAngle)
        local sinA = math.sin(spreadAngle)
        local spreadDirX = dirX * cosA - dirY * sinA
        local spreadDirY = dirX * sinA + dirY * cosA
        
        -- Create projectile
        local proj = Projectile:get(
            originX, 
            originY, 
            spreadDirX * self.projectileSpeed,
            spreadDirY * self.projectileSpeed,
            self.damage,
            self.area,
            self.projectileSprite
        )
        
        -- Set additional properties on projectile
        proj.sourceWeapon = self.id
        proj.critChance = self.weaponAttrib.critChance or 0
        
        -- Apply any weapon-specific projectile modifiers
        self:applyProjectileModifiers(proj)
    end
    
    -- TODO: Play sound effect if sfx provided
    -- This would require a sound system
    
    -- Debug output
    if DEBUG_WEAPONS and DEV.DEBUG_MASTER then
        print(string.format(
            "Fired %s: %d projectile(s) at (%0.2f, %0.2f)", 
            self.name, 
            self.projectileCount,
            dirX, 
            dirY
        ))
    end
end

-- Apply any weapon-specific modifiers to a projectile
function WeaponBase:applyProjectileModifiers(projectile)
    -- Base implementation - can be overridden by specific weapons
    -- Add piercing if the weapon has it
    if self.weaponAttrib.piercing then
        projectile.piercing = self.weaponAttrib.piercing
    end
    
    -- Add additional effects based on weapon attributes
    if self.weaponAttrib.critMultiplier then
        projectile.critMultiplier = self.weaponAttrib.critMultiplier
    end
    
    -- Range limitation for certain weapons
    if self.weaponAttrib.range then
        projectile.maxRange = self.weaponAttrib.range
        projectile.rangeFalloff = self.weaponAttrib.falloff or 0
    end
end

-- Draw the weapon (visual representation when equipped)
function WeaponBase:draw()
    -- This would be implemented by specific weapon types
    -- Base implementation does nothing
end

-- Draw debug visualization
function WeaponBase:drawDebug()
    if not (DEBUG_WEAPONS and DEV.DEBUG_MASTER) then return end
    
    -- Draw weapon hit area
    love.graphics.setColor(1, 0.5, 0, 0.5)
    love.graphics.circle("line", self.hitArea.x, self.hitArea.y, self.hitArea.r)
    
    -- Draw cooldown indicator
    local percentage = (self.cooldown - self.cooldownTimer) / self.cooldown
    love.graphics.setColor(0, 1, 0, 0.8)
    love.graphics.arc(
        "fill", 
        self.hitArea.x, 
        self.hitArea.y, 
        self.hitArea.r + 5, 
        0, 
        percentage * math.pi * 2
    )
    
    -- Draw weapon info
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print(
        self.name .. "\n" ..
        "DMG: " .. self.damage .. "\n" ..
        "CD: " .. string.format("%.1f", self.cooldownTimer) .. "/" .. self.cooldown,
        self.hitArea.x + 20, 
        self.hitArea.y - 40
    )
end

-- Handle key press
function WeaponBase:keypressed(key)
    -- Toggle weapons debug (requires master debug to be on)
    if key == Config.CONTROLS.KEYBOARD.DEBUG.TOGGLE_WEAPONS then
        if not love.keyboard.isDown("lshift", "rshift") then
            DEBUG_WEAPONS = not DEBUG_WEAPONS
            if DEV.DEBUG_MASTER then
                print("Weapons debug: " .. (DEBUG_WEAPONS and "ON" or "OFF"))
            end
        end
    end
end

return WeaponBase
