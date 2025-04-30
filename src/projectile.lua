-- Projectile Entity for Groove Bound
-- Handles projectile creation, movement, and pooling

local L = require("lib.loader")
local Config = require("config.settings")
local PATHS = require("config.paths")

-- Shorthand for readability
local DEV = Config.DEV
local TUNING = Config.TUNING.PROJECTILES

-- Local debug flag, ANDed with master debug
local DEBUG_PROJECTILES = false

-- Object pool for projectiles
local projectilePool = {}
local activeProjectiles = {}
local poolSize = 0

-- Projectile metatable
local Projectile = {}
Projectile.__index = Projectile

-- Initialize the projectile pool
function Projectile:initPool()
    projectilePool = {}
    activeProjectiles = {}
    poolSize = TUNING.POOL_MAX_PROJECTILES
    
    -- Create pool of inactive projectiles
    for i = 1, poolSize do
        local proj = {
            isActive = false,
            -- Basic properties
            x = 0,
            y = 0,
            vx = 0,
            vy = 0,
            damage = 0,
            radius = 5,
            lifetime = 0,
            distance = 0,
            -- Source information
            sourceWeapon = nil,
            -- Additional effects
            piercing = 0,
            critChance = 0,
            critMultiplier = 2,
            maxRange = nil,
            rangeFalloff = 0,
            -- Hit area for debug visualization
            hitArea = {
                x = 0,
                y = 0,
                r = 5
            }
        }
        projectilePool[i] = proj
    end
    
    if DEBUG_PROJECTILES and DEV.DEBUG_MASTER then
        print("Projectile pool initialized with " .. poolSize .. " projectiles")
    end
end

-- Get a projectile from the pool
function Projectile:get(x, y, vx, vy, damage, radius, sprite)
    -- Initialize pool if not done yet
    if poolSize == 0 then
        self:initPool()
    end
    
    -- Find an inactive projectile in the pool
    local proj = nil
    for i = 1, poolSize do
        if not projectilePool[i].isActive then
            proj = projectilePool[i]
            break
        end
    end
    
    -- If no inactive projectile found, find oldest active one to recycle
    if not proj then
        -- Find the oldest active projectile
        local oldestIdx = 1
        local oldestLifetime = 0
        
        for i, p in ipairs(activeProjectiles) do
            if p.lifetime > oldestLifetime then
                oldestIdx = i
                oldestLifetime = p.lifetime
            end
        end
        
        -- Recycle it
        proj = activeProjectiles[oldestIdx]
        table.remove(activeProjectiles, oldestIdx)
        
        if DEBUG_PROJECTILES and DEV.DEBUG_MASTER then
            print("Recycling oldest projectile (lifetime: " .. oldestLifetime .. ")")
        end
    end
    
    -- Set projectile properties
    proj.x = x
    proj.y = y
    proj.vx = vx
    proj.vy = vy
    proj.damage = damage
    proj.radius = radius or 5
    proj.isActive = true
    proj.lifetime = 0
    proj.distance = 0
    proj.maxRange = nil
    proj.rangeFalloff = 0
    proj.piercing = 0
    proj.critChance = 0
    proj.critMultiplier = 2
    
    -- Set hit area
    proj.hitArea.x = x
    proj.hitArea.y = y
    proj.hitArea.r = radius or 5
    
    -- Load sprite if provided
    if sprite then
        proj.sprite = sprite
        if not proj.spriteImg then
            proj.spriteImg = L.Asset.safeImage(sprite, 16, 16)
        end
    else
        proj.sprite = nil
        proj.spriteImg = nil
    end
    
    -- Add to active projectiles list
    table.insert(activeProjectiles, proj)
    
    if DEBUG_PROJECTILES and DEV.DEBUG_MASTER then
        print("Projectile activated at " .. x .. ", " .. y)
    end
    
    return proj
end

-- Update all active projectiles
function Projectile:updateAll(dt)
    local i = 1
    while i <= #activeProjectiles do
        local proj = activeProjectiles[i]
        
        -- Update position
        local oldX, oldY = proj.x, proj.y
        proj.x = proj.x + proj.vx * dt
        proj.y = proj.y + proj.vy * dt
        
        -- Update lifetime and traveled distance
        proj.lifetime = proj.lifetime + dt
        local dx = proj.x - oldX
        local dy = proj.y - oldY
        proj.distance = proj.distance + math.sqrt(dx * dx + dy * dy)
        
        -- Update hit area
        proj.hitArea.x = proj.x
        proj.hitArea.y = proj.y
        
        -- Check if out of bounds
        local margin = TUNING.SCREEN_MARGIN
        local screenWidth, screenHeight = love.graphics.getDimensions()
        local outOfBounds = 
            proj.x < -margin or 
            proj.y < -margin or 
            proj.x > screenWidth + margin or 
            proj.y > screenHeight + margin
        
        -- Check if max range exceeded
        local rangeExceeded = false
        if proj.maxRange and proj.distance >= proj.maxRange then
            rangeExceeded = true
            
            -- Apply range falloff if still in bounds
            if not outOfBounds and proj.rangeFalloff > 0 then
                -- Calculate falloff multiplier
                local fadeDistance = proj.maxRange * 0.2 -- Last 20% of range
                local falloffStart = proj.maxRange - fadeDistance
                
                if proj.distance > falloffStart then
                    local falloffFactor = (proj.distance - falloffStart) / fadeDistance
                    proj.damage = proj.damage * (1 - falloffFactor * proj.rangeFalloff)
                end
            end
        end
        
        -- Check if lifetime exceeded
        local lifetimeExceeded = proj.lifetime > TUNING.DEFAULT_LIFETIME
        
        -- Deactivate if necessary
        if outOfBounds or rangeExceeded or lifetimeExceeded then
            self:deactivate(i)
        else
            i = i + 1
        end
    end
end

-- Deactivate a projectile
function Projectile:deactivate(index)
    if not activeProjectiles[index] then return end
    
    -- Mark as inactive
    activeProjectiles[index].isActive = false
    
    -- Remove from active list
    table.remove(activeProjectiles, index)
    
    if DEBUG_PROJECTILES and DEV.DEBUG_MASTER then
        print("Projectile deactivated")
    end
end

-- Draw all active projectiles
function Projectile:drawAll()
    for _, proj in ipairs(activeProjectiles) do
        if proj.isActive then
            -- Draw sprite if available
            if proj.spriteImg then
                love.graphics.setColor(1, 1, 1, 1)
                
                -- Calculate rotation from velocity
                local rotation = math.atan2(proj.vy, proj.vx)
                
                -- Draw centered and rotated
                love.graphics.draw(
                    proj.spriteImg,
                    proj.x,
                    proj.y,
                    rotation,
                    1, 1,
                    proj.spriteImg:getWidth() / 2,
                    proj.spriteImg:getHeight() / 2
                )
            else
                -- Fallback: draw a circle
                love.graphics.setColor(1, 0.8, 0, 1)
                love.graphics.circle("fill", proj.x, proj.y, proj.radius)
            end
        end
    end
end

-- Draw debug visualization for all active projectiles
function Projectile:drawDebug()
    if not (DEBUG_PROJECTILES and DEV.DEBUG_MASTER) then return end
    
    for _, proj in ipairs(activeProjectiles) do
        if proj.isActive then
            -- Draw hit area
            love.graphics.setColor(1, 0, 0, 0.5)
            love.graphics.circle("line", proj.hitArea.x, proj.hitArea.y, proj.hitArea.r)
            
            -- Draw velocity vector
            love.graphics.setColor(0, 1, 0, 0.8)
            love.graphics.line(
                proj.x,
                proj.y,
                proj.x + proj.vx * 0.1,
                proj.y + proj.vy * 0.1
            )
            
            -- Draw damage text
            love.graphics.setColor(1, 1, 1, 0.7)
            love.graphics.print(
                string.format("DMG: %.1f", proj.damage),
                proj.x + 10,
                proj.y - 10
            )
        end
    end
    
    -- Draw pool usage stats
    love.graphics.setColor(1, 1, 0, 0.8)
    love.graphics.print(
        string.format("Projectiles: %d/%d", #activeProjectiles, poolSize),
        10,
        50
    )
end

-- Handle key press
function Projectile:keypressed(key)
    -- Toggle projectiles debug (requires master debug to be on)
    if key == Config.CONTROLS.KEYBOARD.DEBUG.TOGGLE_PROJECTILES and love.keyboard.isDown("lshift", "rshift") then
        DEBUG_PROJECTILES = not DEBUG_PROJECTILES
        if DEV.DEBUG_MASTER then
            print("Projectiles debug: " .. (DEBUG_PROJECTILES and "ON" or "OFF"))
        end
    end
end

-- Get count of active projectiles
function Projectile:getActiveCount()
    return #activeProjectiles
end

-- For testing: deactivate all projectiles
function Projectile:clearAll()
    for i = #activeProjectiles, 1, -1 do
        self:deactivate(i)
    end
end

return Projectile
