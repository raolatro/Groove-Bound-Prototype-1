-- drone.lua
-- Orbiting drone entity with autonomous firing

local L = require("lib.loader")
local Projectile = require("src.projectile")

-- Local references for better performance
local sin, cos, pi = math.sin, math.cos, math.pi

-- The Drone module
local Drone = {
    -- Active drones list
    drones = {}
}

-- Create metatable for drone instances
local DroneMT = {__index = {}}

-- Local reference to drone methods
local DroneMethods = DroneMT.__index

-- Spawn a new drone
function Drone:spawn(x, y, player, orbitRadius, orbitSpeed, offsetAngle, fireRate, damage, projectileSpeed, projectileRange, colour)
    -- Parameter validation
    if not (x and y and player) then
        return nil
    end
    
    -- Ensure we have valid values for required parameters
    orbitRadius = orbitRadius or 50
    orbitSpeed = orbitSpeed or 1
    offsetAngle = offsetAngle or 0
    fireRate = fireRate or 1.5
    damage = damage or 10
    projectileSpeed = projectileSpeed or 200
    projectileRange = projectileRange or 300
    colour = colour or {1, 1, 1, 1}
    
    -- Create new drone instance
    local drone = {
        -- Position
        x = x,
        y = y,
        -- References
        player = player,
        -- Orbit parameters
        orbitRadius = orbitRadius or 100,
        orbitSpeed = orbitSpeed or 1,  -- Revolutions per second
        orbitAngle = offsetAngle or 0, -- Starting angle offset
        -- Combat stats
        fireTimer = 0,
        fireRate = fireRate or 1,
        damage = damage or 5,
        projectileSpeed = projectileSpeed or 400,
        projectileRange = projectileRange or 200,
        -- Visual properties
        colour = colour or {1, 1, 1, 1},
        size = 8,
        -- State
        active = true,
        -- Animation
        pulseTimer = 0,
        pulseSize = 1
    }
    
    -- Add to active list
    table.insert(self.drones, setmetatable(drone, DroneMT))
    
    return drone
end

-- Update a drone
function DroneMethods:update(dt, playerX, playerY, aimX, aimY)
    -- Update orbit angle
    self.orbitAngle = self.orbitAngle + (self.orbitSpeed * 2 * pi * dt)
    
    -- Calculate position around player
    local px, py = 0, 0
    if self.player.collider then
        px, py = self.player.collider:getPosition()
    else
        px, py = self.player.x, self.player.y
    end
    
    self.x = px + cos(self.orbitAngle) * self.orbitRadius
    self.y = py + sin(self.orbitAngle) * self.orbitRadius
    
    -- Pulse animation
    self.pulseTimer = (self.pulseTimer + dt * 3) % (2 * pi)
    self.pulseSize = 1 + 0.1 * sin(self.pulseTimer)
    
    -- Update fire timer and fire if ready
    self.fireTimer = self.fireTimer - dt
    if self.fireTimer <= 0 then
        self:fire(aimX, aimY)
        self.fireTimer = self.fireRate
    end
end

-- Fire a projectile
function DroneMethods:fire(aimX, aimY)
    -- Calculate firing direction (outward from player, in orbit tangent direction)
    local px, py = 0, 0
    if self.player.collider then
        px, py = self.player.collider:getPosition()
    else
        px, py = self.player.x, self.player.y
    end
    
    -- Direction from player to drone (outward)
    local dx = self.x - px
    local dy = self.y - py
    
    -- Normalize direction
    local len = math.sqrt(dx*dx + dy*dy)
    if len > 0 then
        dx = dx / len
        dy = dy / len
    end
    
    -- Calculate tangent direction (perpendicular to orbit radius)
    -- This gives a more interesting firing pattern where drones shoot
    -- perpendicular to their orbit, like a swirling attack pattern
    local tdx = -dy -- Tangent is perpendicular to radius vector
    local tdy = dx
    
    -- Mix tangent and outward directions for a slightly forward-facing shot
    dx = dx * 0.7 + tdx * 0.3
    dy = dy * 0.7 + tdy * 0.3
    
    -- Normalize again
    len = math.sqrt(dx*dx + dy*dy)
    if len > 0 then
        dx = dx / len
        dy = dy / len
    end
    
    -- Create projectile
    Projectile:spawn(
        self.x, 
        self.y,
        dx * self.projectileSpeed,
        dy * self.projectileSpeed,
        self.damage,
        self.projectileRange / self.projectileSpeed,  -- Lifetime based on range and speed
        self.colour
    )
end

-- Draw a drone
function DroneMethods:draw()
    local r, g, b, a = unpack(self.colour)
    
    -- Draw drone body (diamond shape for distinction)
    love.graphics.setColor(r, g, b, 0.8)
    
    -- Draw a diamond shape
    local size = self.size * self.pulseSize
    love.graphics.polygon(
        "fill",
        self.x, self.y - size,  -- Top
        self.x + size, self.y,  -- Right
        self.x, self.y + size,  -- Bottom
        self.x - size, self.y   -- Left
    )
    
    -- Draw outline
    love.graphics.setColor(r, g, b, 1)
    love.graphics.polygon(
        "line",
        self.x, self.y - size,  -- Top
        self.x + size, self.y,  -- Right
        self.x, self.y + size,  -- Bottom
        self.x - size, self.y   -- Left
    )
    
    -- Draw orbit path if debug enabled
    if DEBUG_MASTER and DEBUG_HITBOXES then
        local px, py = 0, 0
        if self.player.collider then
            px, py = self.player.collider:getPosition()
        else
            px, py = self.player.x, self.player.y
        end
        
        -- Draw orbit circle
        love.graphics.setColor(r, g, b, 0.2)
        love.graphics.circle("line", px, py, self.orbitRadius)
        
        -- Draw line from player to drone
        love.graphics.setColor(r, g, b, 0.3)
        love.graphics.line(px, py, self.x, self.y)
    end
end

-- Update all active drones
function Drone:updateAll(dt, playerX, playerY, aimX, aimY)
    for i = #self.drones, 1, -1 do
        local drone = self.drones[i]
        drone:update(dt, playerX, playerY, aimX, aimY)
        
        -- Remove inactive drones
        if not drone.active then
            table.remove(self.drones, i)
        end
    end
end

-- Draw all active drones
function Drone:drawAll()
    for _, drone in ipairs(self.drones) do
        drone:draw()
    end
end

-- Return the drone module
return Drone
