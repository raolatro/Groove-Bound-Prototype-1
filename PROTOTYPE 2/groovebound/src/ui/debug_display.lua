-- Debug Display module
-- Shows debug information overlay in the top-left corner
-- Maintains a queue of debug messages with timestamps and categories

-- Create a fallback emergency log in the global scope
-- This ensures we always have somewhere to log even if initialization fails
if not _G.emergency_log then
  _G.emergency_log = {}
end

-- Safe require function that won't crash if the module isn't found
local function safeRequire(modulePath)
  local success, module = pcall(require, modulePath)
  if success then
    return module
  else
    print("WARNING: Could not load module: " .. modulePath)
    return {}
  end
end

-- Safely get settings with defaults
local settings = safeRequire("src/core/settings")

-- Default settings to use if the settings module fails to load
local DEFAULT_SETTINGS = {
  debug_display = {
    max_rows = 20,
    ttl_secs = 10,
    font_size = 10,
    font_color = {1, 0, 0, 1},
    bg_color = {0, 0, 0, 0.5}
  }
}

-- Helper function to safely get a setting or use default
local function getSetting(path, default)
  local parts = {}
  for part in string.gmatch(path, "[^%.]+") do
    table.insert(parts, part)
  end
  
  local current = settings
  for _, part in ipairs(parts) do
    if current and type(current) == "table" and current[part] ~= nil then
      current = current[part]
    else
      -- Fallback to default settings
      current = nil
      break
    end
  end
  
  if current ~= nil then
    return current
  end
  
  -- Try to get from default settings
  current = DEFAULT_SETTINGS
  for _, part in ipairs(parts) do
    if current and type(current) == "table" and current[part] ~= nil then
      current = current[part]
    else
      return default
    end
  end
  
  return current or default
end

-- Initialize the Debug module
local Debug = {}

-- Initialize the debug display
function Debug:init()
  -- Ensure we have a messages table
  self.messages = {}
  self.lastTime = love.timer.getTime()
  
  -- Create a small font for debug messages
  local fontSize = getSetting("debug_display.font_size", 10)
  self.font = love.graphics.newFont(fontSize)
  
  -- Process any pending logs that were created before Debug was initialized
  if _G.pendingLogs and #_G.pendingLogs > 0 then
    print("Processing " .. #_G.pendingLogs .. " pending debug log entries")
    for _, logEntry in ipairs(_G.pendingLogs) do
      self:log(logEntry.tag, logEntry.message)
    end
    -- Clear pending logs after processing
    _G.pendingLogs = {}
  end
  
  -- Replace the temporary global log function with the real one
  if _G.SafeLog then
    _G.Debug = self
  end
  
  print("Debug display initialized successfully")
end

-- Add a log message to the debug display
-- @param tag - Category tag for the message
-- @param message - The message content
function Debug:log(tag, message)
  -- Always log to console for safety
  print(string.format("[%s] %s: %s", os.date("%H:%M:%S"), tag, message))
  
  -- Add to emergency log (globally accessible)
  table.insert(_G.emergency_log, {
    message = string.format("[%s] %s", tag, message),
    time = os.time()
  })
  
  -- Keep emergency log size reasonable
  while #_G.emergency_log > 50 do
    table.remove(_G.emergency_log, 1)
  end
  
  -- Then try to add to the regular messages table
  if self.messages then
    -- Add new message with current time
    table.insert(self.messages, {
      tag = tag,
      text = tostring(message),
      time = love.timer.getTime(),
      color = getSetting("debug_display.font_color", {1, 0, 0, 1})
    })
    
    -- Keep only the most recent messages
    local maxRows = getSetting("debug_display.max_rows", 20)
    while #self.messages > maxRows do
      table.remove(self.messages, 1)
    end
  end
end

-- Update the debug display (remove expired messages)
-- @param dt - Delta time since last update
function Debug:update(dt)
  -- Skip if messages table doesn't exist
  if not self.messages then
    self.messages = {}
    return
  end
  
  local currentTime = love.timer.getTime()
  local ttl = getSetting("debug_display.ttl_secs", 10)
  
  -- Remove messages older than the TTL
  local i = 1
  while i <= #self.messages do
    if currentTime - self.messages[i].time > ttl then
      table.remove(self.messages, i)
    else
      i = i + 1
    end
  end
  
  self.lastTime = currentTime
end

-- Draw the debug overlay
function Debug:draw()
  -- Skip if no messages to display
  if not self.messages or #self.messages == 0 then
    return
  end
  
  -- Create font if it doesn't exist
  if not self.font then
    local fontSize = getSetting("debug_display.font_size", 10)
    self.font = love.graphics.newFont(fontSize)
  end
  
  -- Save current graphics state
  love.graphics.push("all")
  
  -- Set font for debug messages
  love.graphics.setFont(self.font)
  
  -- Define size constraints for debug overlay
  local maxWidth = 350 -- Maximum width for debug overlay
  local maxHeight = 200 -- Maximum height to ensure it doesn't take over the screen
  local lineHeight = getSetting("debug_display.font_size", 10) + 2 -- Line height with spacing
  
  -- Calculate how many messages we can display based on max height
  local maxVisibleMessages = math.floor((maxHeight - 4) / lineHeight)
  local messageCount = math.min(#self.messages, maxVisibleMessages)
  
  -- Calculate actual width and height
  local width = maxWidth
  local height = messageCount * lineHeight + 4
  
  -- Get background color with fallback to semi-transparent black
  local bgColor = getSetting("debug_display.bg_color", {0, 0, 0, 0.5})
  love.graphics.setColor(bgColor)
  
  -- Draw background with rounded corners for better appearance
  love.graphics.rectangle("fill", 4, 4, width, height, 4, 4)
  
  -- Get only the most recent messages that fit in our display area
  local visibleMessages = {}
  local count = #self.messages
  local startIdx = math.max(1, count - maxVisibleMessages + 1)
  
  -- Collect the most recent messages that will fit in our display
  for i = startIdx, count do
    table.insert(visibleMessages, self.messages[i])
  end
  
  -- Draw messages with fade effect
  for i, msg in ipairs(visibleMessages) do
    -- Calculate alpha based on remaining time for fade-out effect
    local alpha = 1.0
    local elapsed = love.timer.getTime() - msg.time
    local ttl = getSetting("debug_display.ttl_secs", 10)
    
    -- Fade out in the last 2 seconds of display time
    if elapsed > (ttl - 2) then
      alpha = math.max(0, (ttl - elapsed) / 2)
    end
    
    -- Set color with calculated alpha, safely handling missing color values
    local color = msg.color or {1, 0, 0, 1} -- Default to red if color missing
    -- Ensure color has all four components
    if not color[4] then color[4] = 1 end
    
    -- Apply the color with alpha
    love.graphics.setColor(color[1], color[2], color[3], color[4] * alpha)
    
    -- Draw message text with tag prefix
    local y = 4 + (i - 1) * lineHeight
    local tagText = msg.tag and ("[" .. msg.tag .. "] ") or ""
    local displayText = tagText .. (msg.text or "")
    
    -- Truncate long messages to fit within width
    if self.font:getWidth(displayText) > (width - 16) then
      -- Try to fit as much text as possible
      local truncated = ""
      for j = 1, #displayText do
        local testText = string.sub(displayText, 1, j) .. "..."
        if self.font:getWidth(testText) > (width - 16) then
          truncated = string.sub(displayText, 1, j-1) .. "..."
          break
        end
      end
      displayText = truncated
    end
    
    -- Draw the message
    love.graphics.print(displayText, 8, y)  
  end
  
  -- Draw message count indicator if there are more messages than we can show
  if count > maxVisibleMessages then
    local hiddenCount = count - maxVisibleMessages
    love.graphics.setColor(1, 0.7, 0, 0.8) -- Orange color for indicator
    love.graphics.print("+ " .. hiddenCount .. " more", width - 70, height - lineHeight)  
  end
  
  -- Restore previous graphics state
  love.graphics.pop()
end

-- Return the module
return Debug
