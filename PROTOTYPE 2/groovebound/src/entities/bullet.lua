-- Bullet entity
-- Represents projectiles fired by the player

local Bullet = {}

-- Create a new bullet
-- @param x - Starting X position
-- @param y - Starting Y position
-- @param dx - X direction component (normalized)
-- @param dy - Y direction component (normalized)
-- @param damage - Damage amount (default: 10)
-- @return A new bullet object
function Bullet.new(x, y, dx, dy, damage)
  local self = {
    x = x,                -- X position
    y = y,                -- Y position
    dx = dx,              -- X direction (normalized)
    dy = dy,              -- Y direction (normalized)
    speed = 400,          -- Movement speed (pixels per second)
    damage = damage or 10, -- Damage amount
    life = 1.0,           -- Lifetime in seconds
    size = 4,             -- Size of the bullet
    dead = false          -- Whether the bullet is dead
  }
  
  -- Set the metatable for the bullet object
  setmetatable(self, {__index = Bullet})
  
  return self
end

-- Update the bullet
-- @param dt - Delta time since last update
-- @return true if the bullet is dead (expired or hit something)
function Bullet:update(dt)
  -- Skip if already dead
  if self.dead then return true end
  
  -- Update position
  self.x = self.x + self.dx * self.speed * dt
  self.y = self.y + self.dy * self.speed * dt
  
  -- Update lifetime
  self.life = self.life - dt
  
  -- Check if lifetime expired
  if self.life <= 0 then
    self.dead = true
    return true
  end
  
  -- Check if bullet is off-screen
  local screenWidth, screenHeight = love.graphics.getDimensions()
  if self.x < 0 or self.x > screenWidth or self.y < 0 or self.y > screenHeight then
    self.dead = true
    return true
  end
  
  return false
end

-- Draw the bullet
function Bullet:draw()
  -- Skip if dead
  if self.dead then return end
  
  -- Save current graphics state
  love.graphics.push("all")
  
  -- Draw bullet as a yellow rectangle
  love.graphics.setColor(0.9, 0.9, 0.2, 1) -- Yellow color
  
  -- Draw centered on bullet position
  local halfSize = self.size / 2
  love.graphics.rectangle("fill", self.x - halfSize, self.y - halfSize, self.size, self.size)
  
  -- Restore graphics state
  love.graphics.pop()
end

-- Mark the bullet as dead (hit something)
function Bullet:hit()
  self.dead = true
end

-- Get whether the bullet is dead
-- @return true if the bullet is dead
function Bullet:isDead()
  return self.dead
end

-- Return the bullet module
return Bullet
