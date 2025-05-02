-- Level Up Modal
-- Displays when player levels up, showing ability choices

local LevelUpModal = {}

-- Create a new level up modal
-- @param onClose - Callback function to call when modal is closed
-- @return A new level up modal object
function LevelUpModal.new(onClose)
  -- Default upgrade options if none provided
  local options = {
    "Power Chord Lv2",  -- Increases weapon damage
    "Bass Drop",        -- Area effect weapon
    "Speed Up"          -- Movement speed increase
  }
  
  local self = {
    width = 600,                 -- Modal width
    height = 400,                -- Modal height
    cardWidth = 160,             -- Card width
    cardHeight = 200,            -- Card height
    cardSpacing = 20,            -- Space between cards
    options = options,           -- Upgrade options
    selectedOption = nil,        -- Currently selected option
    onClose = onClose or function() end, -- Callback when modal closes
    visible = true,              -- Whether modal is visible
    blockGrid = nil,             -- Reference to block grid for positioning
    title = "LEVEL UP!"          -- Modal title
  }
  
  -- Set the metatable for the modal object
  setmetatable(self, {__index = LevelUpModal})
  
  -- Get block grid if available
  if _G.BlockGrid then
    self.blockGrid = _G.BlockGrid
  end
  
  return self
end

-- Update the level up modal
-- @param dt - Delta time since last update
function LevelUpModal:update(dt)
  -- Nothing to update if not visible
  if not self.visible then return end
  
  -- Animation updates could go here
end

-- Draw the level up modal
function LevelUpModal:draw()
  -- Skip if not visible
  if not self.visible then return end
  
  -- Save current graphics state
  love.graphics.push("all")
  
  -- Get screen dimensions
  local screenWidth, screenHeight = love.graphics.getDimensions()
  
  -- Calculate modal position (centered)
  local x = (screenWidth - self.width) / 2
  local y = (screenHeight - self.height) / 2
  
  -- Draw semi-transparent background overlay
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
  
  -- Draw modal background
  love.graphics.setColor(0.2, 0.2, 0.25, 0.95)
  love.graphics.rectangle("fill", x, y, self.width, self.height, 10, 10)
  love.graphics.setColor(0.5, 0.5, 0.6, 1)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", x, y, self.width, self.height, 10, 10)
  
  -- Draw title
  love.graphics.setColor(1, 0.8, 0.2, 1)
  love.graphics.setFont(love.graphics.newFont(32))
  local titleWidth = love.graphics.getFont():getWidth(self.title)
  love.graphics.print(self.title, x + (self.width - titleWidth) / 2, y + 30)
  
  -- Draw subtitle
  love.graphics.setColor(0.9, 0.9, 0.9, 1)
  love.graphics.setFont(love.graphics.newFont(18))
  local subtitle = "Choose an upgrade:"
  local subtitleWidth = love.graphics.getFont():getWidth(subtitle)
  love.graphics.print(subtitle, x + (self.width - subtitleWidth) / 2, y + 80)
  
  -- Calculate card positions
  local totalCardsWidth = (#self.options * self.cardWidth) + ((#self.options - 1) * self.cardSpacing)
  local startX = x + (self.width - totalCardsWidth) / 2
  local cardY = y + 120
  
  -- Draw each option card
  for i, option in ipairs(self.options) do
    local cardX = startX + (i-1) * (self.cardWidth + self.cardSpacing)
    
    -- Draw card background
    if self.selectedOption == i then
      -- Highlighted card
      love.graphics.setColor(0.3, 0.6, 0.9, 0.8)
    else
      -- Normal card
      love.graphics.setColor(0.3, 0.3, 0.4, 0.8)
    end
    love.graphics.rectangle("fill", cardX, cardY, self.cardWidth, self.cardHeight, 5, 5)
    
    -- Card border
    love.graphics.setColor(0.5, 0.5, 0.6, 1)
    love.graphics.rectangle("line", cardX, cardY, self.cardWidth, self.cardHeight, 5, 5)
    
    -- Draw option number
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(36))
    love.graphics.printf(i, cardX, cardY + 20, self.cardWidth, "center")
    
    -- Draw option name (split into multiple lines if needed)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf(option, cardX + 10, cardY + 80, self.cardWidth - 20, "center")
    
    -- Draw hint to select
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
    love.graphics.printf("Press " .. i .. " or click", cardX + 10, cardY + self.cardHeight - 30, self.cardWidth - 20, "center")
  end
  
  -- Restore graphics state
  love.graphics.pop()
end

-- Handle key press events
-- @param key - Key that was pressed
function LevelUpModal:keypressed(key)
  -- Skip if not visible
  if not self.visible then return end
  
  -- Check for number keys
  local num = tonumber(key)
  if num and num >= 1 and num <= #self.options then
    self:selectOption(num)
  end
  
  -- Check for escape key to close without selecting
  if key == "escape" then
    self:close()
  end
end

-- Handle mouse press events
-- @param x - Mouse X position
-- @param y - Mouse Y position
-- @param button - Mouse button that was pressed
function LevelUpModal:mousepressed(x, y, button)
  -- Skip if not visible
  if not self.visible then return end
  
  -- Only handle left mouse button
  if button ~= 1 then return end
  
  -- Calculate modal position
  local screenWidth, screenHeight = love.graphics.getDimensions()
  local modalX = (screenWidth - self.width) / 2
  local modalY = (screenHeight - self.height) / 2
  
  -- Calculate card positions
  local totalCardsWidth = (#self.options * self.cardWidth) + ((#self.options - 1) * self.cardSpacing)
  local startX = modalX + (self.width - totalCardsWidth) / 2
  local cardY = modalY + 120
  
  -- Check each card
  for i = 1, #self.options do
    local cardX = startX + (i-1) * (self.cardWidth + self.cardSpacing)
    
    -- Check if click is inside card
    if x >= cardX and x <= cardX + self.cardWidth and
       y >= cardY and y <= cardY + self.cardHeight then
      self:selectOption(i)
      return
    end
  end
end

-- Select an upgrade option
-- @param index - Index of the option to select
function LevelUpModal:selectOption(index)
  -- Check if index is valid
  if index < 1 or index > #self.options then
    return
  end
  
  -- Set selected option
  self.selectedOption = index
  local selectedCard = self.options[index]
  
  -- Log the selection
  if Debug then
    Debug.log("LEVEL", "Selected upgrade: " .. selectedCard)
  end
  
  -- Send event for the selected card
  if EventBus then
    EventBus:emit("CARD_PICKED", {
      card = selectedCard
    })
  end
  
  -- Close the modal
  self:close()
end

-- Close the modal
function LevelUpModal:close()
  self.visible = false
  
  -- Call the close callback
  if self.onClose then
    self.onClose(self.selectedOption)
  end
end

-- Return the level up modal module
return LevelUpModal
