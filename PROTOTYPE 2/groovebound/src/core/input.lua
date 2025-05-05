-- Input module
-- Handles keyboard and mouse input for player control

local Input = {
  -- Movement directions
  up = false,
  down = false,
  left = false,
  right = false,
  
  -- Mouse position and buttons
  mouseX = 0,
  mouseY = 0,
  mouseButton1 = false, -- Left mouse button
  mouseButton2 = false, -- Right mouse button
  
  -- Special keys
  pause = false
}

-- Initialize the input system
function Input:init()
  -- Reset all input states
  self:reset()
end

-- Reset all input states
function Input:reset()
  self.up = false
  self.down = false
  self.left = false
  self.right = false
  self.mouseButton1 = false
  self.mouseButton2 = false
  self.pause = false
end

-- Update mouse position
-- @param x - Mouse X coordinate
-- @param y - Mouse Y coordinate
function Input:updateMouse(x, y)
  self.mouseX = x
  self.mouseY = y
end

-- Handle key press events
-- @param key - The key that was pressed
-- @return boolean - true if the input was handled by this system
function Input:keypressed(key)
  -- Movement keys
  if key == "w" or key == "up" then
    self.up = true
  elseif key == "s" or key == "down" then
    self.down = true
  elseif key == "a" or key == "left" then
    self.left = true
  elseif key == "d" or key == "right" then
    self.right = true
  -- Special keys
  elseif key == "escape" then
    -- Only set pause if we're in a valid state for game pause
    -- Check if we're in the title or run state where global pause makes sense
    local currentState = StateStack:peek()
    if currentState and (currentState.name == "RunState" or currentState.name == "TitleState") then
      self.pause = true
      return true
    end
    -- Don't handle escape for other states, let them handle it
    return false
  end
  
  return true
end

-- Handle key release events
-- @param key - The key that was released
function Input:keyreleased(key)
  -- Movement keys
  if key == "w" or key == "up" then
    self.up = false
  elseif key == "s" or key == "down" then
    self.down = false
  elseif key == "a" or key == "left" then
    self.left = false
  elseif key == "d" or key == "right" then
    self.right = false
  -- Special keys
  elseif key == "escape" then
    self.pause = false
  end
end

-- Get movement direction as normalized vector
-- @return dx, dy - Direction vector (-1, 0, or 1 for each component)
function Input:getMovementDirection()
  local dx, dy = 0, 0
  
  if self.left then dx = dx - 1 end
  if self.right then dx = dx + 1 end
  if self.up then dy = dy - 1 end
  if self.down then dy = dy + 1 end
  
  -- Normalize diagonal movement
  if dx ~= 0 and dy ~= 0 then
    local len = math.sqrt(dx * dx + dy * dy)
    dx = dx / len
    dy = dy / len
  end
  
  return dx, dy
end

-- Get aim direction as a vector from player to mouse
-- @param playerX - Player X position in world coordinates
-- @param playerY - Player Y position in world coordinates
-- @param camera - Optional camera reference for coordinate conversion
-- @return dx, dy - Direction vector from player to mouse (normalized)
function Input:getAimDirection(playerX, playerY, camera)
  local targetX, targetY = self.mouseX, self.mouseY
  
  -- Convert screen mouse coordinates to world coordinates if camera is provided
  if camera then
    targetX, targetY = camera:screenToWorld(self.mouseX, self.mouseY)
  end
  
  -- Get direction vector from player to target
  local dx = targetX - playerX
  local dy = targetY - playerY
  
  -- Normalize the vector
  local len = math.sqrt(dx * dx + dy * dy)
  if len > 0 then
    dx = dx / len
    dy = dy / len
  else
    -- Default to right direction if mouse is exactly on player
    dx, dy = 1, 0
  end
  
  return dx, dy
end

-- Check if escape key was just pressed
-- @return true if pause key was just pressed
function Input:isPausePressed()
  local wasPressed = self.pause
  self.pause = false
  return wasPressed
end

-- Handle mouse press events
-- @param button - Mouse button that was pressed (1 = left, 2 = right)
function Input:mousepressed(button)
  if button == 1 then
    self.mouseButton1 = true
  elseif button == 2 then
    self.mouseButton2 = true
  end
end

-- Handle mouse release events
-- @param button - Mouse button that was released (1 = left, 2 = right)
function Input:mousereleased(button)
  if button == 1 then
    self.mouseButton1 = false
  elseif button == 2 then
    self.mouseButton2 = false
  end
end

-- Check if fire button (left mouse) is pressed
-- @return true if fire button is pressed
function Input:isFirePressed()
  return self.mouseButton1
end

-- Return the module
return Input
