-- Boot Splash state
-- Displays during game initialization and waits 1s before transitioning to Title state

-- Create the state object with default values
local BootSplash = {
  timer = 0,         -- Timer for state transition
  waitTime = 1,      -- Time to wait before transitioning (seconds)
  initialized = false -- Flag to track if we've been initialized
}

-- Called when entering this state
function BootSplash:enter()
  -- Always print to console for debugging
  print("Boot splash state entered")
  
  -- Use SafeLog if available, otherwise use direct print
  -- This ensures we don't crash if Debug.log isn't available yet
  if _G.SafeLog then
    SafeLog("BOOT", "Boot state entered")
  elseif Debug and Debug.log then
    Debug.log("BOOT", "Boot state entered")
  end
  
  -- Reset timer for state transition
  self.timer = 0
  self.initialized = true
end

-- Update function
-- @param dt - Delta time since last update
function BootSplash:update(dt)
  -- Skip if not initialized
  if not self.initialized then return end
  
  -- Update timer
  self.timer = self.timer + dt
  
  -- Transition to Title state after wait time
  if self.timer >= self.waitTime then
    -- Log boot complete message using safe logging
    if _G.SafeLog then
      SafeLog("BOOT", "Boot complete, transitioning to title screen")
    elseif Debug and Debug.log then
      Debug.log("BOOT", "Boot complete, transitioning to title screen")
    else
      print("Boot complete, transitioning to title screen")
    end
    
    -- Transition to Title state with error handling
    local success, TitleState = pcall(require, "src/ui/states/title")
    if success and TitleState then
      -- Flag that we've transitioned to prevent multiple transitions
      self.initialized = false
      StateStack:push(TitleState)
    else
      -- Log error if title state couldn't be loaded
      print("ERROR: Failed to load title state: " .. tostring(TitleState))
    end
  end
end

-- Draw function
function BootSplash:draw()
  -- Clear the screen with black
  love.graphics.clear(0, 0, 0, 1)
  
  -- Draw a more informative loading text
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Groove Bound Loading...", 10, 10)
  
  -- Show loading progress based on timer
  if self.initialized then
    local progress = math.min(1.0, self.timer / self.waitTime)
    love.graphics.rectangle("fill", 10, 30, 200 * progress, 20)
    love.graphics.rectangle("line", 10, 30, 200, 20)
  end
end

-- Return the state
return BootSplash
