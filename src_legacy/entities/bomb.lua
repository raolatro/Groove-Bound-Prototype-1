-- bomb.lua
-- Area of effect bomb entity with timed explosion

local L = require("lib.loader")

-- Local references for better performance
local sin, cos, pi = math.sin, math.cos, math.pi

-- The Bomb module
local Bomb = {
    -- Active bombs list
    bombs = {},
    
    -- Default values
    defaults = {
        explodeDelay = 0.25  -- Seconds to wait at target before exploding
    }
}

-- Create metatable for bomb instances
local BombMT = {__index = {}}

-- Local reference to bomb methods
local BombMethods = BombMT.__index

-- Spawn a new bomb
function Bomb:spawn(x, y, targetX, targetY, speed, damage, blastRadius, colour)
    -- Parameter validation
    if not (x and y and targetX and targetY and speed) then
        return nil
    end
    
    -- Ensure we have valid numbers for required parameters
    damage = damage or 10
    blastRadius = blastRadius or 50
    colour = colour or {1, 1, 1, 1}
    
    -- Create new bomb instance
    local bomb = {
        -- Position and movement
        x = x,
        y = y,
        targetX = targetX,
        targetY = targetY,
        speed = speed,
        -- Direction vector
        dx = targetX - x,
        dy = targetY - y,
        distance = 0,
        totalDistance = math.sqrt((targetX - x)^2 + (targetY - y)^2),
        -- Combat stats
        damage = damage,
        blastRadius = blastRadius,
        -- Visual properties
        colour = colour or {1, 1, 1, 1},
        size = 8,
        -- State
        active = true,
        exploding = false,
        explodeTimer = 0,
        explodeAlpha = 0,
        -- Animation
        pulseTimer = 0,
        pulseSize = 1
    }
    
    -- Normalize direction vector
    local len = math.sqrt(bomb.dx*bomb.dx + bomb.dy*bomb.dy)
    if len > 0 then
        bomb.dx = bomb.dx / len
        bomb.dy = bomb.dy / len
    end
    
    -- Add to active list
    table.insert(self.bombs, setmetatable(bomb, BombMT))
    
    return bomb
end

-- Update a bomb
function BombMethods:update(dt)
    -- If exploding, handle explosion animation
    if self.exploding then
        self.explodeTimer = self.explodeTimer + dt
        
        -- Explosion animation (0.5 second total)
        if self.explodeTimer < 0.5 then
            -- Fade in quickly, then fade out
            if self.explodeTimer < 0.1 then
                self.explodeAlpha = self.explodeTimer / 0.1
            else
                self.explodeAlpha = 1 - ((self.explodeTimer - 0.1) / 0.4)
            end
        else
            -- Deactivate after animation completes
            self.active = false
        end
        
        return
    end
    
    -- Pulse animation while moving
    self.pulseTimer = (self.pulseTimer + dt * 5) % (2 * pi)
    self.pulseSize = 1 + 0.2 * sin(self.pulseTimer)
    
    -- Check if we've reached the target
    if self.distance >= self.totalDistance then
        -- Start explosion sequence
        self.exploding = true
        self.explodeTimer = 0
        
        -- Start the explosion
        self:explode()
        return
    end
    
    -- Move towards target
    local moveDistance = self.speed * dt
    self.distance = self.distance + moveDistance
    
    -- Cap at total distance
    if self.distance > self.totalDistance then
        self.distance = self.totalDistance
    end
    
    -- Calculate new position
    local t = self.distance / self.totalDistance
    self.x = (1 - t) * self.x + t * self.targetX
    self.y = (1 - t) * self.y + t * self.targetY
end

-- Explode the bomb
function BombMethods:explode()
    -- TODO: Query physics world for enemies in blast radius
    -- For now, we just show the visual effect
    
    -- Play sound effect here
    -- love.audio.play(explosionSound)
    
    -- Could spawn particles here
    -- particleSystem:spawn(self.x, self.y, self.colour)
    
    -- Apply damage to enemies within blast radius
    -- This would typically query the physics world
    
    -- Example of how to get entities in radius (pseudo-code):
    -- local entities = world:queryCircle(self.x, self.y, self.blastRadius)
    -- for _, entity in ipairs(entities) do
    --     if entity.collision_class == "enemy" then
    --         entity:takeDamage(self.damage)
    --     end
    -- end
end

-- Draw a bomb
function BombMethods:draw()
    local r, g, b, a = unpack(self.colour)
    
    -- Draw the bomb
    if not self.exploding then
        -- Draw bomb body
        love.graphics.setColor(r, g, b, 0.8)
        love.graphics.circle("fill", self.x, self.y, self.size * self.pulseSize)
        
        -- Draw outline
        love.graphics.setColor(r, g, b, 1)
        love.graphics.circle("line", self.x, self.y, self.size * self.pulseSize)
        
        -- Draw indicator for blast radius if debug enabled
        if DEBUG_MASTER and DEBUG_HITBOXES then
            love.graphics.setColor(r, g, b, 0.3)
            love.graphics.circle("line", self.targetX, self.targetY, self.blastRadius)
        end
    else
        -- Draw explosion
        love.graphics.setColor(r, g, b, self.explodeAlpha * 0.6)
        love.graphics.circle("fill", self.x, self.y, self.blastRadius * (self.explodeTimer * 2))
        
        -- Draw explosion ring
        love.graphics.setColor(r, g, b, self.explodeAlpha)
        love.graphics.circle("line", self.x, self.y, self.blastRadius * (self.explodeTimer * 2))
    end
end

-- Update all active bombs
function Bomb:updateAll(dt)
    for i = #self.bombs, 1, -1 do
        local bomb = self.bombs[i]
        bomb:update(dt)
        
        -- Remove inactive bombs
        if not bomb.active then
            table.remove(self.bombs, i)
        end
    end
end

-- Draw all active bombs
function Bomb:drawAll()
    for _, bomb in ipairs(self.bombs) do
        bomb:draw()
    end
end

-- Handle key press (for debugging)
function Bomb:keypressed(key)
    -- For future hotkey implementation
end

-- Return the bomb module
return Bomb
