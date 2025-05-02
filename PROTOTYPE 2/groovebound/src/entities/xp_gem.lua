-- XP Gem entity
-- Gems that appear when enemies are killed and can be collected by the player

local XPGem = {}

-- Create a new XP gem
-- @param x - X position
-- @param y - Y position
-- @param value - XP value of the gem (default: 1)
-- @return A new XP gem object
function XPGem.new(x, y, value)
  local self = {
    x = x,                -- X position
    y = y,                -- Y position
    value = value or 1,   -- XP value of the gem
    rectSize = 6,         -- Size of the gem
    attractRadius = 200,   -- Radius in which gem is attracted to player
    speed = 200,          -- Movement speed when attracted to player
    isCollected = false,  -- Whether the gem has been collected
    
    -- Visual properties
    pulseAmount = 1,      -- For visual pulsing effect
    pulseSpeed = 2,       -- Speed of pulse animation
    pulseTime = 0         -- Timer for pulse animation
  }
  
  -- Set the metatable for the gem object
  setmetatable(self, {__index = XPGem})
  
  return self
end

-- Update the XP gem
-- @param dt - Delta time since last update
-- @param player - Reference to the player object
-- @return true if the gem was collected and should be removed
function XPGem:update(dt, player)
  -- Skip update if already collected
  if self.isCollected then
    return true
  end
  
  -- Update pulse animation
  self.pulseTime = self.pulseTime + dt * self.pulseSpeed
  self.pulseAmount = 0.8 + 0.2 * math.sin(self.pulseTime * 5)
  
  -- Calculate distance to player
  local dx = player.x - self.x
  local dy = player.y - self.y
  local distance = math.sqrt(dx * dx + dy * dy)
  
  -- Check if gem is within collect radius
  local collectRadius = player.rectSize / 2 + self.rectSize / 2
  if distance <= collectRadius then
    -- Collected the gem
    self.isCollected = true
    
    -- Emit XP pickup event
    if EventBus then
      EventBus:emit("XP_PICKED", {xp = self.value})
    end
    
    return true
  end
  
  -- Check if gem should move toward player
  if distance <= self.attractRadius then
    -- Normalize direction vector
    local dirX = dx / distance
    local dirY = dy / distance
    
    -- Move toward player
    self.x = self.x + dirX * self.speed * dt
    self.y = self.y + dirY * self.speed * dt
  end
  
  return false
end

-- Draw the XP gem
function XPGem:draw()
  -- Skip drawing if collected
  if self.isCollected then return end
  
  -- Save current graphics state
  love.graphics.push("all")
  
  -- Draw gem as a blue rectangle/diamond with pulsing effect
  love.graphics.setColor(0.3, 0.5, 0.9, 0.8) -- Blue color
  
  -- Calculate size with pulse effect
  local size = self.rectSize * self.pulseAmount
  
  -- Draw as a diamond shape (rotated square)
  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  love.graphics.rotate(math.pi / 4) -- 45 degrees rotation
  love.graphics.rectangle("fill", -size/2, -size/2, size, size)
  love.graphics.setColor(0.5, 0.7, 1, 1) -- Lighter blue outline
  love.graphics.rectangle("line", -size/2, -size/2, size, size)
  love.graphics.pop()
  
  -- Restore graphics state
  love.graphics.pop()
end

-- Return the XP gem module
return XPGem
