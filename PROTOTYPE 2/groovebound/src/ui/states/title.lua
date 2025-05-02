-- Title state
-- Displays the main title screen with game options and game title

-- Create the title state object with default properties
local TitleState = {
  -- Track if this state is initialized correctly
  initialized = false,
  -- Title text to display
  titleText = "GROOVE BOUND",
  -- Subtitle/tagline
  subtitleText = "A Rhythm-Based Roguelike Experience"
}

-- Define buttons with their labels and grid positions
-- Each button has label, position (col/row), and size (width/height)
local buttons = {
  { label = "Play", col = 11, row = 8, width = 10, height = 2 },
  { label = "Options", col = 11, row = 11, width = 10, height = 2 },
  { label = "Quit", col = 11, row = 14, width = 10, height = 2 }
}

-- Called when entering this state
-- Initializes the title screen
function TitleState:enter()
  -- Use safe logging system
  if _G.SafeLog then
    SafeLog("STATE", "Title state entered")
  elseif Debug and Debug.log then
    Debug.log("STATE", "Title state entered")
  else
    print("Title state entered")
  end
  
  -- Mark as initialized
  self.initialized = true
end

-- Handle mouse press to allow interaction with menu buttons
-- @param x - Mouse X coordinate
-- @param y - Mouse Y coordinate
-- @param button - Mouse button that was pressed
function TitleState:mousepressed(x, y, button)
  -- Skip if not initialized
  if not self.initialized then return end
  
  -- Only process left mouse button clicks (button 1)
  if button ~= 1 then return end
  
  -- Safety check for BlockGrid
  if not BlockGrid or not BlockGrid.isPointInGrid then
    print("ERROR: BlockGrid is not available")
    return
  end
  
  -- Check if any button was clicked
  for _, btn in ipairs(buttons) do
    -- Use BlockGrid to determine if click is within button boundaries
    if BlockGrid:isPointInGrid(x, y, btn.col, btn.row, btn.width, btn.height) then
      -- Log the button click using safe logging
      if _G.SafeLog then
        SafeLog("TITLE", "Button " .. btn.label .. " clicked")
      elseif Debug and Debug.log then
        Debug.log("TITLE", "Button " .. btn.label .. " clicked")
      else
        print("Button " .. btn.label .. " clicked")
      end
      
      -- Handle button actions with error handling
      if btn.label == "Play" then
        -- Push character select state
        pcall(function()
          local CharacterSelect = require("src/ui/states/character_select")
          if StateStack then
            StateStack:push(CharacterSelect)
          else
            print("ERROR: StateStack is not available")
          end
        end)
      elseif btn.label == "Options" then
        -- Push options menu state
        pcall(function()
          local OptionsMenu = require("src/ui/states/options_menu")
          if StateStack then
            StateStack:push(OptionsMenu)
          else
            print("ERROR: StateStack is not available")
          end
        end)
      elseif btn.label == "Quit" then
        -- Quit the game with confirmation message
        print("Quitting game...")
        -- For this prototype, we'll just exit directly
        love.event.quit()
      end
      
      break
    end
  end
end

-- Update function
-- @param dt - Delta time since last update
function TitleState:update(dt)
  -- Title screen update logic
  -- Currently just animation timing if needed
end

-- Draw the title screen with menu options
-- Renders title, subtitle, and interactive buttons
function TitleState:draw()
  -- Save current graphics state for clean restoration later
  love.graphics.push("all")
  
  -- Clear the screen with a dark background gradient
  love.graphics.clear(0.05, 0.05, 0.1, 1)
  
  -- Safety check for BlockGrid
  if not BlockGrid or not BlockGrid.grid then
    -- Fallback rendering if BlockGrid is unavailable
    self:drawFallbackTitle()
    love.graphics.pop()
    return
  end
  
  -- Draw title text using BlockGrid for consistent layout
  love.graphics.setColor(1, 0.8, 0.2, 1) -- Golden title color
  local titleFont = love.graphics.newFont(32)
  love.graphics.setFont(titleFont)
  
  -- Get title position from grid
  local titleX, titleY, titleWidth, titleHeight = BlockGrid:grid(8, 3, 16, 3)
  love.graphics.printf(self.titleText, titleX, titleY, titleWidth, "center")
  
  -- Draw subtitle
  love.graphics.setColor(0.8, 0.8, 0.8, 1) -- Light gray subtitle color
  local subtitleFont = love.graphics.newFont(16)
  love.graphics.setFont(subtitleFont)
  love.graphics.printf(self.subtitleText, titleX, titleY + 40, titleWidth, "center")
  
  -- Draw all menu buttons
  for _, btn in ipairs(buttons) do
    -- Get button position and size in pixels using BlockGrid
    local x, y, width, height = BlockGrid:grid(btn.col, btn.row, btn.width, btn.height)
    
    -- Draw button background with gradient effect
    love.graphics.setColor(0.2, 0.2, 0.3, 0.9) -- Dark blue button background
    love.graphics.rectangle("fill", x, y, width, height, 5, 5) -- Rounded corners
    
    -- Draw button border with highlight
    love.graphics.setColor(0.5, 0.5, 0.8, 1) -- Light blue border
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height, 5, 5)
    
    -- Draw button label centered in button
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(btn.label, x, y + height/4, width, "center")
  end
  
  -- Restore previous graphics state
  love.graphics.pop()
end

-- Called when a key is pressed
-- @param key - The key that was pressed
function TitleState:keypressed(key)
  -- Exit the game if escape is pressed
  if key == "escape" then
    love.event.quit()
  end
end

-- Fallback rendering method when BlockGrid is unavailable
-- This provides a basic title screen without relying on BlockGrid
function TitleState:drawFallbackTitle()
  -- Get screen dimensions for manual positioning
  local width, height = love.graphics.getDimensions()
  
  -- Draw title with fallback positioning
  love.graphics.setColor(1, 0.8, 0.2, 1) -- Golden title color
  local titleFont = love.graphics.newFont(32)
  love.graphics.setFont(titleFont)
  love.graphics.printf(self.titleText, 0, height * 0.2, width, "center")
  
  -- Draw subtitle
  love.graphics.setColor(0.8, 0.8, 0.8, 1) -- Light gray
  local subtitleFont = love.graphics.newFont(16)
  love.graphics.setFont(subtitleFont)
  love.graphics.printf(self.subtitleText, 0, height * 0.2 + 40, width, "center")
  
  -- Draw manual buttons at fixed positions
  local buttonNames = {"Play", "Options", "Quit"}
  local buttonY = height * 0.4
  local buttonWidth = 200
  local buttonHeight = 40
  
  for i, label in ipairs(buttonNames) do
    -- Position each button vertically
    local y = buttonY + (i-1) * (buttonHeight + 20)
    local x = (width - buttonWidth) / 2
    
    -- Draw button background
    love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
    love.graphics.rectangle("fill", x, y, buttonWidth, buttonHeight, 5, 5)
    
    -- Draw button border
    love.graphics.setColor(0.5, 0.5, 0.8, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, buttonWidth, buttonHeight, 5, 5)
    
    -- Draw button label
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(label, x, y + buttonHeight/4, buttonWidth, "center")
  end
  
  -- Add a message about fallback mode
  love.graphics.setColor(1, 0.5, 0.5, 1) -- Light red warning text
  love.graphics.printf("(Fallback Mode: BlockGrid unavailable)", 0, height * 0.8, width, "center")
end

-- Return the state
return TitleState
