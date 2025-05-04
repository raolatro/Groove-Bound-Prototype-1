-- Arena Manager
-- Handles the gameplay arena, boundaries, and provides utility functions
-- for positioning and collision with arena edges

local Settings = require("src/core/settings")

local ArenaManager = {
  width = 0,       -- Arena width
  height = 0,      -- Arena height
  borderThickness = 0,  -- Border thickness
  borderColor = {0.3, 0.3, 0.3, 1}  -- Border color
}

-- Initialize the arena with settings
-- @return self for chaining
function ArenaManager:init()
  -- Load arena settings
  self.width = Settings.arena.width
  self.height = Settings.arena.height
  self.borderThickness = Settings.arena.border_thickness
  self.borderColor = Settings.arena.border_color
  
  -- Log initialization
  if _G.SafeLog then
    SafeLog("SYSTEM", "Arena initialized: " .. self.width .. "x" .. self.height)
  elseif Logger and Logger.info then
    Logger:info("Arena initialized: " .. self.width .. "x" .. self.height)
  else
    print("Arena initialized: " .. self.width .. "x" .. self.height)
  end
  
  return self
end

-- Get the center position of the arena
-- @return x, y - Center coordinates
function ArenaManager:getCenter()
  return self.width / 2, self.height / 2
end

-- Check if a position is inside the arena boundaries
-- @param x - X position to check
-- @param y - Y position to check
-- @param padding - Optional padding from edge (default: 0)
-- @return bool - True if position is inside arena
function ArenaManager:isInside(x, y, padding)
  padding = padding or 0
  return x >= padding and y >= padding and 
         x <= self.width - padding and 
         y <= self.height - padding
end

-- Constrain a position to be within the arena boundaries
-- @param x - X position to constrain
-- @param y - Y position to constrain
-- @param padding - Optional padding from edge (default: 0)
-- @return x, y - Constrained position
function ArenaManager:constrain(x, y, padding)
  padding = padding or 0
  
  x = math.max(padding, math.min(x, self.width - padding))
  y = math.max(padding, math.min(y, self.height - padding))
  
  return x, y
end

-- Get a random position within the arena
-- @param padding - Optional padding from edge (default: 0)
-- @return x, y - Random position
function ArenaManager:getRandomPosition(padding)
  padding = padding or 0
  
  local x = math.random(padding, self.width - padding)
  local y = math.random(padding, self.height - padding)
  
  return x, y
end

-- Get a random position around the edge of the arena
-- @param padding - Optional padding from edge (default: 0)
-- @return x, y - Random position on edge
function ArenaManager:getRandomEdgePosition(padding)
  padding = padding or 0
  
  -- Decide which edge to spawn on (0-3: top, right, bottom, left)
  local edge = math.random(0, 3)
  
  local x, y
  if edge == 0 then
    -- Top edge
    x = math.random(padding, self.width - padding)
    y = padding
  elseif edge == 1 then
    -- Right edge
    x = self.width - padding
    y = math.random(padding, self.height - padding)
  elseif edge == 2 then
    -- Bottom edge
    x = math.random(padding, self.width - padding)
    y = self.height - padding
  else
    -- Left edge
    x = padding
    y = math.random(padding, self.height - padding)
  end
  
  return x, y
end

-- Get a random position at a certain distance from a target position
-- @param targetX - Target X position
-- @param targetY - Target Y position
-- @param minDistance - Minimum distance from target
-- @param maxDistance - Maximum distance from target
-- @return x, y - Random position at specified distance
function ArenaManager:getRandomPositionAroundTarget(targetX, targetY, minDistance, maxDistance)
  -- Get a random angle
  local angle = math.random() * math.pi * 2
  
  -- Get a random distance between min and max
  local distance = minDistance + math.random() * (maxDistance - minDistance)
  
  -- Calculate position from angle and distance
  local x = targetX + math.cos(angle) * distance
  local y = targetY + math.sin(angle) * distance
  
  -- Constrain to arena boundaries
  return self:constrain(x, y, self.borderThickness)
end

-- Draw the arena boundaries
function ArenaManager:draw()
  -- Save current graphics state
  love.graphics.push("all")
  
  -- Set border color
  love.graphics.setColor(self.borderColor)
  
  -- Draw top border
  love.graphics.rectangle("fill", 0, 0, self.width, self.borderThickness)
  
  -- Draw bottom border
  love.graphics.rectangle("fill", 0, self.height - self.borderThickness, self.width, self.borderThickness)
  
  -- Draw left border
  love.graphics.rectangle("fill", 0, 0, self.borderThickness, self.height)
  
  -- Draw right border
  love.graphics.rectangle("fill", self.width - self.borderThickness, 0, self.borderThickness, self.height)
  
  -- Restore graphics state
  love.graphics.pop()
end

-- Return the module
return ArenaManager
