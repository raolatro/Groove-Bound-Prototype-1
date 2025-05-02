-- Character Select state
-- Allows player to choose a character before starting a run

local CharacterSelectState = {}

-- Character card for Joe
local characterCard = { name = "Joe", col = 8, row = 6, width = 16, height = 6, description = "Office worker chosen by the Wizard of Groove to restore rhythm to the universe." }

-- Back button
local backButton = { label = "Back", col = 8, row = 14, width = 7, height = 2 }

-- Start button
local startButton = { label = "Start Run", col = 17, row = 14, width = 7, height = 2 }

-- Called when entering this state
function CharacterSelectState:enter()
  -- Log state entry
  Debug.log("STATE", "Character select state entered")
  
  -- Only Joe is available in the prototype
  -- In a complete implementation, there would be multiple characters
end

-- Handle mouse press
-- @param x - Mouse X coordinate
-- @param y - Mouse Y coordinate
-- @param button - Mouse button that was pressed
function CharacterSelectState:mousepressed(x, y, button)
  -- Only process left mouse button clicks
  if button ~= 1 then return end
  
  -- Check if back button was clicked
  if BlockGrid:isPointInGrid(x, y, backButton.col, backButton.row, backButton.width, backButton.height) then
    -- Pop back to title screen
    StateStack:pop()
    return
  end
  
  -- Check if start button or character card was clicked
  if BlockGrid:isPointInGrid(x, y, startButton.col, startButton.row, startButton.width, startButton.height) or
     BlockGrid:isPointInGrid(x, y, characterCard.col, characterCard.row, characterCard.width, characterCard.height) then
    
    -- Log character selection
    Debug.log("CHAR", "Joe selected")
    
    -- Push run loading state
    local RunLoading = require("src/ui/states/run_loading")
    StateStack:push(RunLoading)
    return
  end
end

-- Update function
-- @param dt - Delta time since last update
function CharacterSelectState:update(dt)
  -- No continuous update logic needed for character selection
end

-- Draw function
function CharacterSelectState:draw()
  -- Clear the screen with black
  love.graphics.clear(0, 0, 0, 1)
  
  -- Draw screen title
  love.graphics.setColor(1, 1, 1, 1)
  local titleX, titleY = BlockGrid:toPixels(12, 2)
  love.graphics.print("SELECT CHARACTER", titleX, titleY)
  
  -- Draw character card
  local cardX, cardY, cardWidth, cardHeight = BlockGrid:grid(characterCard.col, characterCard.row, characterCard.width, characterCard.height)
  
  -- Card background
  love.graphics.setColor(0.3, 0.3, 0.3, 1)
  love.graphics.rectangle("fill", cardX, cardY, cardWidth, cardHeight)
  
  -- Card border
  love.graphics.setColor(0.7, 0.7, 0.7, 1)
  love.graphics.rectangle("line", cardX, cardY, cardWidth, cardHeight)
  
  -- Character name
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(characterCard.name, cardX + 20, cardY + 20)
  
  -- Character placeholder image (just a rectangle for now)
  love.graphics.setColor(0.5, 0.5, 0.5, 1)
  love.graphics.rectangle("fill", cardX + 20, cardY + 50, 100, 100)
  
  -- Character description
  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.printf(characterCard.description, cardX + 140, cardY + 50, cardWidth - 160, "left")
  
  -- Selected indicator
  love.graphics.setColor(0, 1, 0, 0.5)
  love.graphics.rectangle("line", cardX + 2, cardY + 2, cardWidth - 4, cardHeight - 4)
  
  -- Draw buttons
  -- Back button
  local backX, backY, backWidth, backHeight = BlockGrid:grid(backButton.col, backButton.row, backButton.width, backButton.height)
  love.graphics.setColor(0.3, 0.3, 0.3, 1)
  love.graphics.rectangle("fill", backX, backY, backWidth, backHeight)
  love.graphics.setColor(0.7, 0.7, 0.7, 1)
  love.graphics.rectangle("line", backX, backY, backWidth, backHeight)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf(backButton.label, backX, backY + backHeight/3, backWidth, "center")
  
  -- Start button
  local startX, startY, startWidth, startHeight = BlockGrid:grid(startButton.col, startButton.row, startButton.width, startButton.height)
  love.graphics.setColor(0.2, 0.7, 0.2, 1)
  love.graphics.rectangle("fill", startX, startY, startWidth, startHeight)
  love.graphics.setColor(0.8, 1, 0.8, 1)
  love.graphics.rectangle("line", startX, startY, startWidth, startHeight)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf(startButton.label, startX, startY + startHeight/3, startWidth, "center")
end

-- Handle key press
-- @param key - The key that was pressed
function CharacterSelectState:keypressed(key)
  -- Return to title screen if escape is pressed
  if key == "escape" then
    StateStack:pop()
  end
end

-- Return the state
return CharacterSelectState
