-- Player entity
-- Represents the player character with movement and rendering logic

local Bullet = require("src/entities/bullet")

local Player = {}

-- Create a new player instance
-- @param x - Initial X position
-- @param y - Initial Y position
-- @return A new player object
function Player.new(x, y)
  local self = {
    x = x or 0,         -- X position
    y = y or 0,         -- Y position
    speed = 120,        -- Movement speed (pixels per second)
    baseSpeed = 120,    -- Base movement speed (for upgrades)
    hp = 100,           -- Health points
    maxHp = 100,        -- Maximum health points
    rectSize = 16,      -- Player rectangle size
    aimDirectionX = 1,  -- Aim direction X component
    aimDirectionY = 0,  -- Aim direction Y component
    
    -- Weapon properties
    weapon = {
      damage = 30,       -- Weapon damage
      level = 1,         -- Weapon level
      fireRate = 0.05     -- Shots per second (lower = faster)
    },
    fireCooldown = 0.05,  -- Time between shots
    fireTimer = 0,       -- Current fire timer
    bullets = {}        -- Active bullets
  }
  
  -- Set the metatable for the player object
  setmetatable(self, {__index = Player})
  
  return self
end

-- Update player position and state
-- @param dt - Delta time since last update
function Player:update(dt)
  -- Get movement direction from input
  local dx, dy = Input:getMovementDirection()
  
  -- Move player based on direction and speed
  self.x = self.x + dx * self.speed * dt
  self.y = self.y + dy * self.speed * dt
  
  -- Clamp player to arena bounds
  -- This uses the window dimensions for now
  local windowWidth, windowHeight = love.graphics.getDimensions()
  local halfSize = self.rectSize / 2
  
  -- Ensure player stays within the boundaries
  self.x = math.max(halfSize, math.min(self.x, windowWidth - halfSize))
  self.y = math.max(halfSize, math.min(self.y, windowHeight - halfSize))
  
  -- Update aim direction
  self.aimDirectionX, self.aimDirectionY = Input:getAimDirection(self.x, self.y)
  
  -- Update fire cooldown timer
  if self.fireTimer > 0 then
    self.fireTimer = self.fireTimer - dt
  end
  
  -- Check for fire input and create bullets if ready
  if Input:isFirePressed() and self.fireTimer <= 0 then
    self:fire()
    
    -- Reset fire timer
    self.fireTimer = self.fireCooldown
  end
  
  -- Update all bullets
  for i = #self.bullets, 1, -1 do
    local bullet = self.bullets[i]
    
    -- If bullet is dead, remove it
    if bullet:update(dt) then
      table.remove(self.bullets, i)
    end
  end
end

-- Draw the player
function Player:draw()
  -- Save current graphics state
  love.graphics.push("all")
  
  -- Draw player rectangle
  love.graphics.setColor(0.7, 0.7, 0.7, 1) -- Gray color
  
  -- Draw centered on player position
  local halfSize = self.rectSize / 2
  love.graphics.rectangle("fill", self.x - halfSize, self.y - halfSize, self.rectSize, self.rectSize)
  
  -- Draw aim direction indicator (optional)
  love.graphics.setColor(1, 0, 0, 1) -- Red line for aim direction
  local lineLength = self.rectSize
  love.graphics.line(
    self.x, 
    self.y, 
    self.x + self.aimDirectionX * lineLength, 
    self.y + self.aimDirectionY * lineLength
  )
  
  -- Draw all bullets
  for _, bullet in ipairs(self.bullets) do
    bullet:draw()
  end
  
  -- Restore graphics state
  love.graphics.pop()
end

-- Take damage and update health
-- @param amount - Amount of damage to take
-- @return true if player is still alive, false if dead
function Player:takeDamage(amount)
  self.hp = math.max(0, self.hp - amount)
  return self.hp > 0
end

-- Heal the player
-- @param amount - Amount of health to restore
function Player:heal(amount)
  self.hp = math.min(self.maxHp, self.hp + amount)
end

-- Fire a bullet in the aim direction
function Player:fire()
  -- Create a new bullet at player position
  local bullet = Bullet.new(
    self.x, 
    self.y, 
    self.aimDirectionX, 
    self.aimDirectionY, 
    self.weapon.damage
  )
  
  -- Add to the bullets table
  table.insert(self.bullets, bullet)
  
  -- Log the shot
  if Debug then
    Debug.log("PLAYER", "Fired bullet with damage " .. self.weapon.damage)
  end
  
  return bullet
end

-- Get all active bullets
-- @return Table of active bullets
function Player:getBullets()
  return self.bullets
end

-- Return the player module
return Player
