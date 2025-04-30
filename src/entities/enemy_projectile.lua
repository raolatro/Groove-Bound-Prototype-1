-- enemy_projectile.lua
-- Projectile entity for enemy attacks

local L = require("lib.loader")
local Config = require("config.settings")
local PATHS = require("config.paths")

-- Constants
local TUNING = Config.TUNING
local DEV = Config.DEV

-- Pool of inactive projectiles for reuse
local projectilePool = {}
local activeProjectiles = {}

-- The EnemyProjectile module
local EnemyProjectile = {}
EnemyProjectile.__index = EnemyProjectile

-- Initialize the projectile pool
function EnemyProjectile:initPool()
    projectilePool = {}
    activeProjectiles = {}
    
    -- Debug output
    if _G.DEBUG_MASTER and _G.DEBUG_ENEMIES then
        print("Enemy Projectile pool initialized")
    end
end

-- Create a new projectile
function EnemyProjectile:spawn(x, y, dirX, dirY, settings)
    -- Parameter validation
    if not (x and y and dirX and dirY and settings) then
        print("ERROR: Enemy projectile spawn missing parameters")
        return nil
    end
    
    -- Calculate velocity from direction and speed
    local speed = settings.speed or 150
    local vx = dirX * speed
    local vy = dirY * speed
    
    -- Check if we can reuse a projectile from the pool
    local proj = nil
    if #projectilePool > 0 then
        proj = table.remove(projectilePool)
    else
        proj = {}
        setmetatable(proj, EnemyProjectile)
    end
    
    -- Initialize projectile properties
    proj.x = x
    proj.y = y
    proj.vx = vx
    proj.vy = vy
    proj.damage = settings.damage or 5
    proj.size = settings.size or 8
    proj.range = settings.range or 400
    proj.color = settings.color or {1, 0.3, 0.3, 0.9} -- Default reddish
    proj.isActive = true
    proj.distance = 0
    proj.lifetime = 0
    proj.maxLifetime = proj.range / speed  -- Auto-calculate lifetime based on range/speed
    
    -- Add to active projectiles list
    table.insert(activeProjectiles, proj)
    
    -- Debug output
    if _G.DEBUG_MASTER and _G.DEBUG_ENEMIES then
        print(string.format("Spawned enemy projectile at (%.1f, %.1f) with damage: %d", 
            x, y, proj.damage))
    end
    
    return proj
end

-- Update all active projectiles
function EnemyProjectile:updateAll(dt)
    -- Process all active projectiles
    local i = 1
    while i <= #activeProjectiles do
        local proj = activeProjectiles[i]
        
        -- Update position
        local oldX, oldY = proj.x, proj.y
        proj.x = proj.x + proj.vx * dt
        proj.y = proj.y + proj.vy * dt
        
        -- Update lifetime and traveled distance
        proj.lifetime = proj.lifetime + dt
        local distanceTraveled = math.sqrt((proj.x - oldX)^2 + (proj.y - oldY)^2)
        proj.distance = proj.distance + distanceTraveled
        
        -- Check if projectile should be deactivated
        local shouldDeactivate = false
        
        -- Check lifetime
        if proj.lifetime >= proj.maxLifetime then
            shouldDeactivate = true
        end
        
        -- Check max range
        if proj.distance >= proj.range then
            shouldDeactivate = true
        end
        
        -- Check if out of bounds (very large margin)
        local margin = 2000
        local screenWidth, screenHeight = love.graphics.getDimensions()
        if proj.x < -margin or proj.y < -margin or 
           proj.x > screenWidth + margin or proj.y > screenHeight + margin then
            shouldDeactivate = true
        end
        
        -- Deactivate if necessary
        if shouldDeactivate then
            proj.isActive = false
            table.remove(activeProjectiles, i)
            table.insert(projectilePool, proj)
        else
            i = i + 1
        end
    end
end

-- Draw all active projectiles
function EnemyProjectile:drawAll()
    -- Store current graphics state
    local r, g, b, a = love.graphics.getColor()
    
    -- Draw each projectile
    for _, proj in ipairs(activeProjectiles) do
        -- Calculate rotation from velocity
        local rotation = math.atan2(proj.vy, proj.vx)
        
        -- Draw projectile body (filled circle)
        love.graphics.setColor(proj.color)
        love.graphics.circle("fill", proj.x, proj.y, proj.size)
        
        -- Debug visualization
        if _G.DEBUG_MASTER and _G.DEBUG_ENEMIES then
            -- Draw trail
            local trailLength = 20
            local backX = proj.x - proj.vx/math.sqrt(proj.vx*proj.vx + proj.vy*proj.vy) * trailLength
            local backY = proj.y - proj.vy/math.sqrt(proj.vx*proj.vx + proj.vy*proj.vy) * trailLength
            
            love.graphics.setColor(proj.color[1], proj.color[2], proj.color[3], 0.5)
            love.graphics.line(proj.x, proj.y, backX, backY)
            
            -- Draw hitbox
            love.graphics.setColor(1, 1, 1, 0.3)
            love.graphics.circle("line", proj.x, proj.y, proj.size)
        end
    end
    
    -- Restore graphics state
    love.graphics.setColor(r, g, b, a)
end

-- Check collision with player
function EnemyProjectile:checkPlayerCollision(player)
    -- Skip if no player
    if not player then
        return false
    end
    
    -- Get player position and hitbox
    local playerX, playerY
    if player.collider then
        playerX, playerY = player.collider:getPosition()
    else
        playerX, playerY = player.x, player.y
    end
    
    local playerHitRadius = player.hitRadius or 24
    
    -- Check each projectile
    for i, proj in ipairs(activeProjectiles) do
        -- Calculate distance
        local dx = playerX - proj.x
        local dy = playerY - proj.y
        local dist = math.sqrt(dx*dx + dy*dy)
        
        -- Check collision
        if dist <= (playerHitRadius + proj.size) then
            -- Player hit by projectile - dispatch event for PlayerSystem
            local Event = require("lib.event")
            Event.dispatch("ENEMY_PROJECTILE_HIT", {
                damage = proj.damage,
                projectileType = proj.projectileType or "default"
            })
            
            -- Deactivate projectile
            proj.isActive = false
            table.remove(activeProjectiles, i)
            table.insert(projectilePool, proj)
            
            -- Return damage value (for compatibility with existing code)
            return proj.damage
        end
    end
    
    -- No collision
    return false
end

-- Get all active projectiles
function EnemyProjectile:getActiveProjectiles()
    return activeProjectiles
end

-- Return the module
return EnemyProjectile
