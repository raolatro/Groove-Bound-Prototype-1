-- XP System
-- Handles player XP, leveling, and level-up events

local XPSystem = {}

-- Create a new XP system
-- @return A new XP system object
function XPSystem.new()
  local self = {
    xp = 0,                  -- Current XP amount
    level = 1,               -- Current player level
    xpLevels = {10, 20, 30, 40, 50, 60}, -- XP thresholds for leveling up
    nextLevelThreshold = 10, -- XP needed for next level (will be updated)
    onLevelUp = nil          -- Optional callback function for level up
  }
  
  -- Set the metatable for the XP system object
  setmetatable(self, {__index = XPSystem})
  
  -- Get XP levels from settings if available
  if Settings and Settings.globals and Settings.globals.xp_levels then
    self.xpLevels = Settings.globals.xp_levels
    self.nextLevelThreshold = self.xpLevels[1]
  end
  
  -- Register for XP pickup events
  if EventBus then
    EventBus:on("XP_PICKED", function(data)
      self:addXP(data.xp)
    end)
  end
  
  return self
end

-- Add XP to the player and check for level up
-- @param amount - Amount of XP to add
-- @return true if the player leveled up, false otherwise
function XPSystem:addXP(amount)
  -- Add XP
  self.xp = self.xp + amount
  
  -- Check if player leveled up
  if self.xp >= self.nextLevelThreshold then
    -- Increase level
    self.level = self.level + 1
    
    -- Log the level up
    if Debug then
      Debug.log("XP", "Player reached level " .. self.level)
    end
    
    -- Emit level up event
    if EventBus then
      EventBus:emit("PLAYER_LEVEL_UP", {
        level = self.level,
        xp = self.xp
      })
    end
    
    -- Call level up callback if provided
    if self.onLevelUp then
      self.onLevelUp(self.level)
    end
    
    -- Update next level threshold
    if self.level <= #self.xpLevels then
      self.nextLevelThreshold = self.xpLevels[self.level]
    else
      -- If we've gone beyond defined levels, use a formula
      local lastThreshold = self.xpLevels[#self.xpLevels]
      self.nextLevelThreshold = lastThreshold + (lastThreshold * 0.5 * (self.level - #self.xpLevels))
    end
    
    return true
  end
  
  return false
end

-- Get the current level
-- @return Current level
function XPSystem:getLevel()
  return self.level
end

-- Get the current XP
-- @return Current XP amount
function XPSystem:getXP()
  return self.xp
end

-- Get the XP required for the next level
-- @return XP required for next level
function XPSystem:getNextLevelThreshold()
  return self.nextLevelThreshold
end

-- Get the XP progress as a percentage toward next level
-- @return Percentage (0-1) toward next level
function XPSystem:getLevelProgress()
  local prevThreshold = 0
  if self.level > 1 and self.level <= #self.xpLevels + 1 then
    prevThreshold = self.xpLevels[self.level - 1]
  elseif self.level > #self.xpLevels + 1 then
    -- Calculate previous threshold for levels beyond the defined table
    local lastThreshold = self.xpLevels[#self.xpLevels]
    prevThreshold = lastThreshold + (lastThreshold * 0.5 * (self.level - 1 - #self.xpLevels))
  end
  
  return (self.xp - prevThreshold) / (self.nextLevelThreshold - prevThreshold)
end

-- Set callback function to be called when player levels up
-- @param callback - Function to call on level up
function XPSystem:setLevelUpCallback(callback)
  self.onLevelUp = callback
end

-- Return the XP system module
return XPSystem
