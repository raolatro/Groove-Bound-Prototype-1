-- Run Loading state
-- Transition state that loads resources before starting a game run

local RunLoadingState = {}

-- Called when entering this state
function RunLoadingState:enter()
  -- Log state entry
  Debug.log("STATE", "Run loading state entered")
  
  -- In a complete implementation, this would load level resources
  -- For prototype, this is a simple transition state
  
  -- Set a short timer to simulate loading
  self.timer = 0
  self.loadTime = 0.5 -- Half second "loading" time
  
  -- Array of loading messages to cycle through
  self.loadingMessages = {
    "Loading weapons...",
    "Tuning instruments...",
    "Finding the rhythm...",
    "Building the arena..."
  }
  self.currentMessage = 1
  self.messageTime = 0
  self.messageInterval = 0.15 -- Time between message changes
end

-- Update function
-- @param dt - Delta time since last update
function RunLoadingState:update(dt)
  -- Update timer
  self.timer = self.timer + dt
  
  -- Update message cycling
  self.messageTime = self.messageTime + dt
  if self.messageTime >= self.messageInterval then
    self.messageTime = 0
    self.currentMessage = (self.currentMessage % #self.loadingMessages) + 1
  end
  
  -- Transition to Run state after load time
  if self.timer >= self.loadTime then
    -- Transition to the actual run state
    local RunState = require("src/ui/states/run")
    StateStack:push(RunState)
  end
end

-- Draw function
function RunLoadingState:draw()
  -- Clear the screen with black
  love.graphics.clear(0, 0, 0, 1)
  
  -- Get progress bar position and size using grid
  local barX, barY, barWidth, barHeight = BlockGrid:grid(9, 10, 12, 2)
  
  -- Draw loading message
  love.graphics.setColor(1, 1, 1, 1)
  local message = self.loadingMessages[self.currentMessage]
  love.graphics.printf(message, barX, barY - BlockGrid.unit * 2, barWidth, "center")
  
  -- Draw a loading bar
  local progress = self.timer / self.loadTime
  
  -- Draw bar background
  love.graphics.setColor(0.2, 0.2, 0.2, 1)
  love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
  
  -- Draw progress fill
  love.graphics.setColor(0.2, 0.6, 0.8, 1)
  love.graphics.rectangle("fill", barX, barY, barWidth * progress, barHeight)
  
  -- Draw bar border
  love.graphics.setColor(0.8, 0.8, 0.8, 1)
  love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
  
  -- Draw percentage text
  love.graphics.setColor(1, 1, 1, 1)
  local percent = math.floor(progress * 100)
  love.graphics.printf(percent .. "%", barX, barY + barHeight/4, barWidth, "center")
end

-- Handle key press
-- @param key - The key that was pressed
function RunLoadingState:keypressed(key)
  -- Skip loading if space is pressed
  if key == "space" then
    self.timer = self.loadTime
  end
end

-- Return the state
return RunLoadingState
