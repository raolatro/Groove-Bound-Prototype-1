-- Enemy entity
-- Represents enemies that move toward the player and can be damaged/killed

local Enemy = {}

-- Create a new enemy
-- @param x - Initial X position
-- @param y - Initial Y position
-- @param targetPlayer - Reference to the player entity (for movement)
-- @return A new enemy object
function Enemy.new(x, y, targetPlayer)
  local self = {
    x = x or 0,               -- X position
    y = y or 0,               -- Y position
    speed = 60,               -- Movement speed (pixels per second)
    hp = 20,                  -- Health points
    rectSize = 12,            -- Enemy rectangle size
    targetPlayer = targetPlayer, -- Reference to player for movement
    isDead = false            -- Flag to track if enemy is dead
  }
  
  -- Set the metatable for the enemy object
  setmetatable(self, {__index = Enemy})
  
  return self
end

-- Update enemy position and state
-- @param dt - Delta time since last update
function Enemy:update(dt)
  -- Skip update if enemy is dead
  if self.isDead then return end
  
  -- Calculate direction to player
  local dx = self.targetPlayer.x - self.x
  local dy = self.targetPlayer.y - self.y
  
  -- Normalize direction vector
  local length = math.sqrt(dx * dx + dy * dy)
  if length > 0 then
    dx = dx / length
    dy = dy / length
  end
  
  -- Move toward player
  self.x = self.x + dx * self.speed * dt
  self.y = self.y + dy * self.speed * dt
end

-- Draw the enemy
function Enemy:draw()
  -- Skip drawing if enemy is dead
  if self.isDead then return end
  
  -- Save current graphics state
  love.graphics.push("all")
  
  -- Draw enemy as a red rectangle
  love.graphics.setColor(0.8, 0.2, 0.2, 1) -- Red color
  
  -- Draw centered on enemy position
  local halfSize = self.rectSize / 2
  love.graphics.rectangle("fill", self.x - halfSize, self.y - halfSize, self.rectSize, self.rectSize)
  
  -- Restore graphics state
  love.graphics.pop()
end

-- Take damage and check if enemy dies
-- @param amount - Amount of damage to take
-- @return true if the enemy died from this damage
function Enemy:takeDamage(amount)
  -- Skip if already dead
  if self.isDead then return false end
  
  -- Reduce HP
  self.hp = self.hp - amount
  
  -- Check if enemy died
  if self.hp <= 0 then
    self.isDead = true
    
    -- Emit event for XP drop
    if EventBus then
      EventBus:emit("ENEMY_KILLED", {
        x = self.x,
        y = self.y,
        xp = 1
      })
    end
    
    return true
  end
  
  return false
end

-- Return the enemy module
return Enemy
