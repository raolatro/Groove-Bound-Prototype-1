-- xp_gem.lua
-- XP gem entity with attraction behavior

local L = require("lib.loader")
local Config = require("config.settings")
local PATHS = require("config.paths")
local Debug = require("src.debug")

-- Import events system
local Event = require("lib.event")

-- Define events
Event.define("XP_GAINED", {"amount"})
Event.define("LEVEL_UP_READY", {"totalXp"})

-- Constants
local TUNING = Config.TUNING.GEMS
local DEV = Config.DEV

-- Local references
local VecNormalize = L.utils.math.normalize

-- Pool of inactive gems for reuse
local gemPool = {}
local activeGems = {}

-- The XP Gem module
local XPGem = {}
XPGem.__index = XPGem

-- Initialize the gem pool
function XPGem:initPool()
    gemPool = {}
    activeGems = {}
    
    -- Debug output
    if _G.DEBUG_MASTER and _G.DEBUG_GEMS then
        Debug.log("XP Gem pool initialized")
    end
end

-- Create a new gem
function XPGem:new(x, y, value, baseColor)
    -- Check if we can reuse a gem from the pool
    local gem = nil
    if #gemPool > 0 then
        gem = table.remove(gemPool)
    else
        gem = {}
        setmetatable(gem, XPGem)
    end
    
    -- Initialize gem properties
    gem.x = x
    gem.y = y
    gem.vx = 0
    gem.vy = 0
    gem.size = 12
    gem.value = value or TUNING.BASE_XP
    gem.color = baseColor or {0, 200/255, 255/255, 0.8} -- Cyan by default
    gem.isActive = true
    gem.isAttracted = false
    gem.spawnTime = love.timer.getTime()
    gem.lifeTime = 0
    
    -- Add a slight initial "pop" motion
    local angle = math.random() * (math.pi * 2)
    local speed = math.random(20, 50)
    gem.vx = math.cos(angle) * speed
    gem.vy = math.sin(angle) * speed
    
    -- Add to active gems list
    table.insert(activeGems, gem)
    
    -- Debug output
    if _G.DEBUG_MASTER and _G.DEBUG_GEMS then
        Debug.log(string.format("Spawned XP gem at (%.1f, %.1f) with value: %d", x, y, gem.value))
    end
    
    return gem
end

-- Update all active gems
function XPGem:updateAll(dt, player)
    -- Skip if no player
    if not player then
        return
    end
    
    -- Get player position
    local playerX, playerY
    if player.collider then
        playerX, playerY = player.collider:getPosition()
    else
        playerX, playerY = player.x, player.y
    end
    
    -- Player hitbox for collection
    local playerHitRadius = player.hitRadius or 24
    
    -- Process all active gems
    local i = 1
    while i <= #activeGems do
        local gem = activeGems[i]
        
        -- Update gem lifetime
        gem.lifeTime = gem.lifeTime + dt
        
        -- Calculate distance to player
        local dx = playerX - gem.x
        local dy = playerY - gem.y
        local dist = math.sqrt(dx*dx + dy*dy)
        
        -- Check if gem should be attracted to player
        if dist < TUNING.ATTRACT_RADIUS then
            gem.isAttracted = true
        end
        
        -- Movement logic
        if gem.isAttracted then
            -- FIXED BEHAVIOR: Direct velocity assignment for smooth gem homing
            -- Normalize direction vector
            local dirX, dirY
            if dist > 0 then
                dirX, dirY = dx / dist, dy / dist
            else
                dirX, dirY = 0, 0
            end
            
            -- Calculate improved magnetism speed with exponential easing
            -- Starts very slow and gradually accelerates as it gets closer
            local baseSpeed = TUNING.ATTRACT_SPEED
            local magnetSpeed = baseSpeed
            
            -- Enhanced exponential easing - much stronger curve
            if dist < TUNING.ATTRACT_RADIUS then
                -- Calculate normalized distance (1.0 at edge of radius, 0.0 at player)
                local normalizedDist = dist / TUNING.ATTRACT_RADIUS
                
                -- Exponential curve: starts very slow, ends very fast
                -- Using a stronger exponent for more dramatic effect
                local easeFactor = 1 - normalizedDist  -- 0 to 1, inverted distance
                local exponent = 3  -- Higher = more dramatic curve
                
                -- Apply exponential ease-in
                local speedMultiplier = math.pow(easeFactor, exponent) * 5 + 1  -- +1 to ensure we never go below base speed
                
                -- Apply the speed multiplier
                magnetSpeed = baseSpeed * speedMultiplier
                
                -- Add a minimum speed to prevent very slow movement far away
                if magnetSpeed < baseSpeed * 0.8 then
                    magnetSpeed = baseSpeed * 0.8
                end
            end
            
            -- Directly set velocity based on direction and speed
            gem.vx = dirX * magnetSpeed
            gem.vy = dirY * magnetSpeed
            
            -- Debug output
            if _G.DEBUG_MASTER and _G.DEBUG_GEMS and math.random() < 0.005 then
                Debug.log(string.format("Gem homing: dist=%.1f, speed=%.1f, multiplier=%.2f",
                                      dist, magnetSpeed, magnetSpeed/baseSpeed))  
            end
            
            if _G.DEBUG_MASTER and _G.DEBUG_GEMS and math.random() < 0.01 then
                Debug.log(string.format("Gem homing: dist=%.1f, speed=%.1f, v=(%.1f,%.1f)", 
                                        dist, magnetSpeed, gem.vx, gem.vy))
            end
        else
            -- Initial "pop" deceleration
            gem.vx = gem.vx * 0.95
            gem.vy = gem.vy * 0.95
        end
        
        -- Apply velocity
        gem.x = gem.x + gem.vx * dt
        gem.y = gem.y + gem.vy * dt
        
        -- IMPROVED COLLECTION: Check using player hitbox tiles (3 vertical positions)
        -- This creates a more natural collection area matching the player's character
        local playerHalfWidth = playerHitRadius * 0.7
        local playerHeight = playerHitRadius * 2
        
        -- Check if gem is within any of the player's collision tiles
        local inPlayerBounds = 
            -- Check if within player's horizontal bounds
            math.abs(gem.x - playerX) <= playerHalfWidth and
            -- Check if within player's vertical bounds
            math.abs(gem.y - playerY) <= playerHeight/2
            
        if inPlayerBounds or dist <= playerHitRadius/2 then
            -- Dispatch XP gained event
            Event.dispatch("XP_GAINED", {amount = gem.value})
            
            -- Debug output for gem collection
            if _G.DEBUG_MASTER and _G.DEBUG_GEMS then
                Debug.log(string.format("Collected gem worth %d XP at distance %.1f", gem.value, dist))
            end
            
            -- Debug output
            if _G.DEBUG_MASTER and _G.DEBUG_GEMS then
                Debug.log(string.format("Collected XP gem with value: %d", gem.value))
            end
            
            -- Deactivate gem
            gem.isActive = false
            table.remove(activeGems, i)
            table.insert(gemPool, gem)
        else
            i = i + 1
        end
    end
end

-- Helper function to generate triangle vertices
local function triVerts(c, s)
    return {
        c.x, c.y - s,         -- Top vertex
        c.x + s * 0.866, c.y + s * 0.5,  -- Bottom right vertex
        c.x - s * 0.866, c.y + s * 0.5   -- Bottom left vertex
    }
end

-- Draw all active gems
function XPGem:drawAll()
    -- Store current graphics state
    local r, g, b, a = love.graphics.getColor()
    
    -- Draw each gem
    for _, gem in ipairs(activeGems) do
        -- Pulse effect based on lifetime
        local pulse = 1.0 + 0.2 * math.sin(gem.lifeTime * 5)
        local size = gem.size * pulse
        
        -- Create triangle vertices
        local center = {x = gem.x, y = gem.y}
        local vertices = triVerts(center, size)
        
        -- Draw gem (filled triangle)
        love.graphics.setColor(0, 0.8, 1, 0.8) -- Cyan-blue color
        love.graphics.polygon("fill", vertices)
        
        -- Draw gem outline in debug mode or for visibility
        if _G.DEBUG_MASTER and _G.DEBUG_GEMS then
            love.graphics.setColor(1, 1, 1, 1) -- White outline
            love.graphics.polygon("line", vertices)
        end
        
        -- Debug visualization of attraction state
        if _G.DEBUG_MASTER and _G.DEBUG_GEMS and gem.isAttracted then
            love.graphics.setColor(1, 1, 0, 0.3)
            love.graphics.circle("line", gem.x, gem.y, size + 4)
        end
    end
    
    -- Restore graphics state
    love.graphics.setColor(r, g, b, a)
end

-- Draw debug visualization
function XPGem:drawDebug(player)
    -- Skip if debugging is disabled
    if not (_G.DEBUG_MASTER and _G.DEBUG_GEMS) or not player then
        return
    end
    
    -- Store current graphics state
    local r, g, b, a = love.graphics.getColor()
    
    -- Get player position
    local playerX, playerY
    if player.collider then
        playerX, playerY = player.collider:getPosition()
    else
        playerX, playerY = player.x, player.y
    end
    
    -- Draw attraction radius as dashed circle
    love.graphics.setColor(0, 200/255, 255/255, 0.2)
    
    -- Draw dashed circle
    local segments = 36
    local radius = TUNING.ATTRACT_RADIUS
    for i = 1, segments do
        if i % 2 == 0 then -- Skip every other segment for dashed effect
            local startAngle = (i - 1) * (2 * math.pi / segments)
            local endAngle = i * (2 * math.pi / segments)
            
            -- Draw arc segment
            love.graphics.arc(
                "line", 
                playerX, playerY, 
                radius, 
                startAngle, endAngle
            )
        end
    end
    
    -- Restore graphics state
    love.graphics.setColor(r, g, b, a)
end

-- Spawn multiple gems at a position
function XPGem:spawnMultiple(x, y, count, valuePerGem)
    count = count or 1
    valuePerGem = valuePerGem or TUNING.BASE_XP
    
    -- Spawn the requested number of gems
    for i = 1, count do
        -- Add slight position variation for visual interest
        local offsetX = math.random(-15, 15)
        local offsetY = math.random(-15, 15)
        
        -- Create the gem
        self:new(x + offsetX, y + offsetY, valuePerGem)
    end
    
    -- Debug output
    if _G.DEBUG_MASTER and _G.DEBUG_GEMS then
        Debug.log(string.format("Spawned %d gems at (%.1f, %.1f) with total value: %d", 
            count, x, y, count * valuePerGem))
    end
end

-- Clear all active gems
function XPGem:clearAll()
    -- Debug output
    if _G.DEBUG_MASTER and _G.DEBUG_GEMS then
        Debug.log("Clearing all active XP gems: " .. #activeGems)
    end
    
    -- Move all active gems back to the pool
    while #activeGems > 0 do
        local gem = table.remove(activeGems)
        table.insert(gemPool, gem)
    end
end

-- Return the module
return XPGem
