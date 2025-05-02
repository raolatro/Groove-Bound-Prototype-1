-- Options Menu state
-- Displays and handles game options settings

local OptionsMenuState = {}

-- Define options with their labels and grid positions
local options = {
  { label = "Master Volume", col = 11, row = 8, width = 10, height = 2, value = 100, min = 0, max = 100, step = 10 },
  { label = "Music Volume", col = 11, row = 11, width = 10, height = 2, value = 100, min = 0, max = 100, step = 10 }
}

-- Define close button
local closeButton = { label = "Close", col = 11, row = 14, width = 10, height = 2 }

-- Track active slider when dragging
local activeOption = nil
local valuesChanged = false

-- Called when entering this state
function OptionsMenuState:enter()
  -- Log state entry
  Debug.log("STATE", "Options menu state entered")
  
  -- Initialize slider values from settings
  -- In a full implementation, these would come from settings file
  -- but for now we'll use placeholder values
  options[1].value = 100 -- Master volume default
  options[2].value = 100 -- Music volume default
  
  -- Reset changed flag
  valuesChanged = false
end

-- Handle mouse press
-- @param x - Mouse X coordinate
-- @param y - Mouse Y coordinate
function OptionsMenuState:mousepressed(x, y, button)
  -- Only process left mouse button clicks
  if button ~= 1 then return end
  
  -- Check if close button was clicked
  if BlockGrid:isPointInGrid(x, y, closeButton.col, closeButton.row, closeButton.width, closeButton.height) then
    -- Save settings if changed
    if valuesChanged then
      Debug.log("OPTIONS", "Volumes changed")
      -- Actually save settings here if this was a complete implementation
    end
    
    -- Pop back to previous state
    StateStack:pop()
    return
  end
  
  -- Check if any slider was clicked
  for i, opt in ipairs(options) do
    local sliderX, sliderY, sliderWidth, sliderHeight = BlockGrid:grid(opt.col, opt.row, opt.width, opt.height)
    
    if y >= sliderY and y <= sliderY + sliderHeight then
      -- Calculate relative position (0-1) along the slider
      local relativeX = (x - sliderX) / sliderWidth
      relativeX = math.max(0, math.min(1, relativeX))
      
      -- Update option value based on position
      local range = opt.max - opt.min
      local newValue = opt.min + math.floor(range * relativeX / opt.step) * opt.step
      
      -- Only mark as changed if value actually changed
      if opt.value ~= newValue then
        opt.value = newValue
        valuesChanged = true
      end
      
      -- Set active option for dragging
      activeOption = i
      break
    end
  end
end

-- Handle mouse release
function OptionsMenuState:mousereleased(x, y, button)
  -- Reset active option when mouse is released
  activeOption = nil
end

-- Handle mouse movement
-- @param x - Mouse X coordinate
-- @param y - Mouse Y coordinate
function OptionsMenuState:mousemoved(x, y)
  -- Update active slider if dragging
  if activeOption then
    local opt = options[activeOption]
    local sliderX, sliderY, sliderWidth = BlockGrid:grid(opt.col, opt.row, opt.width, opt.height)
    
    -- Calculate relative position (0-1) along the slider
    local relativeX = (x - sliderX) / sliderWidth
    relativeX = math.max(0, math.min(1, relativeX))
    
    -- Update option value based on position
    local range = opt.max - opt.min
    local newValue = opt.min + math.floor(range * relativeX / opt.step) * opt.step
    
    -- Only mark as changed if value actually changed
    if opt.value ~= newValue then
      opt.value = newValue
      valuesChanged = true
    end
  end
end

-- Handle key press
-- @param key - The key that was pressed
function OptionsMenuState:keypressed(key)
  if key == "escape" then
    -- Save settings if changed
    if valuesChanged then
      Debug.log("OPTIONS", "Volumes changed")
      -- Actually save settings here if this was a complete implementation
    end
    
    -- Pop back to previous state
    StateStack:pop()
  end
end

-- Update function
-- @param dt - Delta time since last update
function OptionsMenuState:update(dt)
  -- No continuous update logic needed for options menu
end

-- Draw function
function OptionsMenuState:draw()
  -- Save current graphics state
  love.graphics.push("all")
  
  -- Draw semi-transparent background
  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  
  -- Draw modal window background
  local x, y, width, height = BlockGrid:grid(10, 6, 12, 10)
  love.graphics.setColor(0.2, 0.2, 0.2, 1)
  love.graphics.rectangle("fill", x, y, width, height)
  love.graphics.setColor(0.8, 0.8, 0.8, 1)
  love.graphics.rectangle("line", x, y, width, height)
  
  -- Draw title
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf("OPTIONS", x, y + BlockGrid.unit, width, "center")
  
  -- Draw sliders
  for _, opt in ipairs(options) do
    local sliderX, sliderY, sliderWidth, sliderHeight = BlockGrid:grid(opt.col, opt.row, opt.width, opt.height)
    
    -- Draw label
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(opt.label, sliderX, sliderY - BlockGrid.unit)
    
    -- Draw value
    love.graphics.print(opt.value .. "%", sliderX + sliderWidth - 30, sliderY - BlockGrid.unit)
    
    -- Draw slider track
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.rectangle("fill", sliderX, sliderY + sliderHeight/2 - 2, sliderWidth, 4)
    
    -- Draw slider handle
    local handlePos = sliderX + (opt.value - opt.min) / (opt.max - opt.min) * sliderWidth
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.rectangle("fill", handlePos - 5, sliderY + sliderHeight/2 - 10, 10, 20)
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("line", handlePos - 5, sliderY + sliderHeight/2 - 10, 10, 20)
  end
  
  -- Draw close button
  local btnX, btnY, btnWidth, btnHeight = BlockGrid:grid(closeButton.col, closeButton.row, closeButton.width, closeButton.height)
  love.graphics.setColor(0.3, 0.3, 0.3, 1)
  love.graphics.rectangle("fill", btnX, btnY, btnWidth, btnHeight)
  love.graphics.setColor(0.8, 0.8, 0.8, 1)
  love.graphics.rectangle("line", btnX, btnY, btnWidth, btnHeight)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf(closeButton.label, btnX, btnY + btnHeight/3, btnWidth, "center")
  
  -- Restore graphics state
  love.graphics.pop()
end

-- Return the state
return OptionsMenuState
