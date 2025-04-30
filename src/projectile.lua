-- Projectile Entity for Groove Bound
-- Handles projectile creation, movement, and pooling

local L = require("lib.loader")
local Config = require("config.settings")
local PATHS = require("config.paths")

-- Shorthand for readability
local DEV = Config.DEV
local TUNING = Config.TUNING.PROJECTILES

-- Instead of storing debug flags as local variables, we'll always use the global _G versions
-- This ensures we respect the current settings in Config.DEV and the debug hierarchy
-- DO NOT override the global debug flags here - that would break the user's settings

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
    
    if _G.DEBUG_MASTER and _G.DEBUG_PROJECTILES then
        print("Projectile activated at " .. x .. ", " .. y)
    end
    
    return proj
end

-- Spawn a projectile (alias for get method to maintain compatibility)
function Projectile:spawn(x, y, vx, vy, damage, maxLifetime, colour, radius, sprite, weaponInfo)
    -- Parameter validation
    if not (x and y and vx and vy) then
        print("ERROR: Projectile spawn missing position or velocity parameters")
        return nil
    end
    
    -- Debug output for projectile spawning
    if _G.DEBUG_MASTER and (_G.DEBUG_PROJECTILES or _G.DEBUG_WEAPONS) then
        local weaponName = "Unknown"
        local weaponLevel = 1
        if weaponInfo then
            weaponName = weaponInfo.name or "Unknown"
            weaponLevel = weaponInfo.level or 1
        end
        
        print(string.format("PROJECTILE SPAWN: Weapon=%s, Level=%d, Pos=(%d,%d), Vel=(%d,%d), Damage=%d, Lifetime=%d", 
            weaponName, weaponLevel, math.floor(x), math.floor(y), math.floor(vx), math.floor(vy), damage, maxLifetime))
    end
    
    -- Initialize defaults
    damage = damage or 10
    radius = radius or 5
    maxLifetime = maxLifetime or 2
    
    -- Convert colour to sprite if provided
    local spriteToUse = sprite
    if not sprite and colour then
        -- In future we might create a colored sprite here
        -- For now just use the color later in draw
    end
    
    -- Use the get method to create the projectile
    local proj = self:get(x, y, vx, vy, damage, radius, spriteToUse)
    
    -- Set additional properties
    proj.maxLifetime = maxLifetime
    proj.colour = colour or {1, 1, 1, 1}
    
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
        
        -- Debug position update
        if _G.DEBUG_MASTER and (_G.DEBUG_PROJECTILES or _G.DEBUG_WEAPONS) then
            if math.random() < 0.01 then  -- Log only occasionally to avoid spam
                print(string.format("PROJECTILE MOVE: ID=%d, Pos=(%d,%d), Vel=(%d,%d), dt=%.3f, Travel=%.1f", 
                    i, math.floor(proj.x), math.floor(proj.y), 
                    math.floor(proj.vx), math.floor(proj.vy), 
                    dt, proj.distance or 0))
            end
        end
        
        -- Update lifetime and traveled distance
        proj.lifetime = proj.lifetime + dt
        local distanceTraveled = math.sqrt((proj.x - oldX)^2 + (proj.y - oldY)^2)
        proj.distance = proj.distance + distanceTraveled
        
        -- Update hit area
        proj.hitArea.x = proj.x
        proj.hitArea.y = proj.y
        
        -- Check if projectile should be removed
        local shouldDeactivate = false
        
        -- Check if projectile exceeds maxLifetime (if set)
        local deactivateReason = nil
        if proj.maxLifetime and proj.lifetime >= proj.maxLifetime then
            shouldDeactivate = true
            deactivateReason = "lifetime_exceeded"
        end
        
        -- Check if out of bounds (using a much larger margin to let projectiles travel further)
        local margin = 2000  -- Very large margin to ensure projectiles can travel across the entire arena
        local screenWidth, screenHeight = love.graphics.getDimensions()
        local outOfBounds = 
            proj.x < -margin or 
            proj.y < -margin or 
            proj.x > screenWidth + margin or 
            proj.y > screenHeight + margin
            
        -- Debug out of bounds
        if outOfBounds and _G.DEBUG_MASTER and (_G.DEBUG_PROJECTILES or _G.DEBUG_WEAPONS) then
            print(string.format("PROJECTILE OUT OF BOUNDS: ID=%d, Pos=(%d,%d), Screen=(%d,%d), Margin=%d",
                i, math.floor(proj.x), math.floor(proj.y),
                screenWidth, screenHeight, margin))
        end
            
        if outOfBounds then
            shouldDeactivate = true
            deactivateReason = deactivateReason or "out_of_bounds"
        end
        
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
                    local fadePercentage = 1 - falloffFactor * proj.rangeFalloff
                    
                    -- Apply damage falloff based on distance
                    proj.damage = proj.damage * fadePercentage
                    
                    -- Last part: actually check if we need to deactivate
                    if fadePercentage <= 0 then
                        shouldDeactivate = true
                        deactivateReason = deactivateReason or "range_falloff"
                    end
                end
            else
                -- If range exceeded and no falloff, deactivate
                shouldDeactivate = true
                deactivateReason = deactivateReason or "range_exceeded"
            end
        end
        
        -- Check lifetime exceeded (for additional lifetime checks beyond maxLifetime)
        local lifetimeExceeded = false
        -- TODO: Add lifetime cap check if needed
        
        if lifetimeExceeded then
            shouldDeactivate = true
            deactivateReason = deactivateReason or "extra_lifetime_check"
        end
        
        -- Deactivate if necessary
        if shouldDeactivate then
            self:deactivate(i, deactivateReason)
        else
            i = i + 1
        end
    end
end

-- Deactivate a projectile
function Projectile:deactivate(index, reason)
    if not activeProjectiles[index] then return end
    
    local proj = activeProjectiles[index]
    
    -- Mark as inactive
    proj.isActive = false
    
    -- Debug deactivation with detailed info
    if _G.DEBUG_MASTER and (_G.DEBUG_PROJECTILES or _G.DEBUG_WEAPONS) then
        reason = reason or "unknown"
        print(string.format("PROJECTILE DEACTIVATED: ID=%d, Reason=%s, Pos=(%d,%d), Lifetime=%.2fs, Distance=%.1f", 
            index, reason, 
            math.floor(proj.x or 0), math.floor(proj.y or 0),
            proj.lifetime or 0, proj.distance or 0))
    end
    
    -- Remove from active list
    table.remove(activeProjectiles, index)
end

-- Draw all active projectiles
function Projectile:drawAll()
    -- Debug header
    if _G.DEBUG_MASTER and (_G.DEBUG_PROJECTILES or _G.DEBUG_WEAPONS) then
        if math.random() < 0.01 then  -- Log occasionally
            print(string.format("PROJECTILE DRAW: Active Count=%d", #activeProjectiles))
        end
    end
    
    for i, proj in ipairs(activeProjectiles) do
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
                -- Fallback: draw a circle using projectile color
                if proj.colour then
                    -- Use the weapon-defined color
                    love.graphics.setColor(proj.colour[1], proj.colour[2], proj.colour[3], 1)
                else
                    -- Default yellow fallback if no color defined
                    love.graphics.setColor(1, 0.8, 0, 1)
                end
                
                -- Make projectiles larger and add trails for better visibility
                local radius = proj.radius * 2  -- Double the radius for better visibility
                love.graphics.circle("fill", proj.x, proj.y, radius)
                
                -- Add a trail in debug mode
                if _G.DEBUG_MASTER and (_G.DEBUG_PROJECTILES or _G.DEBUG_WEAPONS) then
                    -- Draw a trailing line showing direction
                    local trailLength = 20
                    local backX = proj.x - (proj.vx / (proj.vx*proj.vx + proj.vy*proj.vy)^0.5) * trailLength
                    local backY = proj.y - (proj.vy / (proj.vx*proj.vx + proj.vy*proj.vy)^0.5) * trailLength
                    
                    love.graphics.setColor(proj.colour[1], proj.colour[2], proj.colour[3], 0.5)
                    love.graphics.line(proj.x, proj.y, backX, backY)
                end
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
