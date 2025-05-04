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

-- Load settings with defaults
local Settings = safeRequire("src/core/settings")

-- Default settings to use if the settings module fails to load
local DEFAULT_SETTINGS = {
  debug = {
    enabled = true,
    display = {
      max_rows = 30,
      ttl_secs = 20,
      font_size = 20,
      font_color = {1, 0, 0, 1},
      bg_color = {0, 0, 0, 0.5},
      enabled = true,
      position = {x = 10, y = 10}
    }
  }
}

-- Helper function to safely get a setting or use default
local function getSetting(path, default)
  local parts = {}
  for part in string.gmatch(path, "[^%.]+") do
    table.insert(parts, part)
  end
  
  local current = Settings
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
function Debug.init()
  -- Ensure we have a messages table
  Debug.messages = {}
  Debug.lastTime = love.timer.getTime()
  
  -- Create a small font for debug messages
  local fontSize = getSetting("debug.display.font_size", 10)
  Debug.font = love.graphics.newFont(fontSize)
  
  -- Store master debug enabled state
  Debug.enabled = getSetting("debug.enabled", true)
  
  -- Process any pending logs that were created before Debug was initialized
  if _G.pendingLogs and #_G.pendingLogs > 0 then
    print("Processing " .. #_G.pendingLogs .. " pending debug log entries")
    for _, logEntry in ipairs(_G.pendingLogs) do
      Debug.log(logEntry.tag, logEntry.message)
    end
    -- Clear pending logs after processing
    _G.pendingLogs = {}
  end
  
  -- Replace the temporary global log function with the real one
  if _G.SafeLog then
    _G.Debug = Debug
  end
  
  print("Debug display initialized successfully")
  return Debug
end

-- Add a log message to the debug display
-- @param tag - Category tag for the message
-- @param message - The message content
-- @param fileKey - Optional file-specific debug key to check (e.g., 'player', 'bullet')
function Debug.log(tag, message, fileKey)
  -- Always log to console for safety
  print(string.format("[%s] %s: %s", os.date("%H:%M:%S"), tag, message))
  
  -- Check if debug is enabled globally
  local debugEnabled = getSetting("debug.enabled", true)
  if not debugEnabled then return end
  
  -- Check file-specific debug flag if provided
  if fileKey and not getSetting("debug.files." .. fileKey, true) then
    return -- Skip this log if file-specific debugging is disabled
  end
  
  -- Add to emergency log (globally accessible)
  if _G.emergency_log then
    table.insert(_G.emergency_log, {
      message = string.format("[%s] %s", tag, message),
      time = os.time()
    })
    
    -- Keep emergency log size reasonable
    while #_G.emergency_log > 50 do
      table.remove(_G.emergency_log, 1)
    end
  end
  
  -- Then try to add to the regular messages table
  if Debug.messages then
    -- Add new message with current time
    table.insert(Debug.messages, {
      tag = tag,
      text = tostring(message),
      time = love.timer.getTime(),
      color = getSetting("debug_display.font_color", {1, 0, 0, 1})
    })
    
    -- Keep only the most recent messages
    local maxRows = getSetting("debug_display.max_rows", 20)
    while #Debug.messages > maxRows do
      table.remove(Debug.messages, 1)
    end
  end
end

-- Update the debug display (remove expired messages)
-- @param dt - Delta time since last update
function Debug.update(dt)
  -- Skip if debug display is not initialized
  if not Debug.messages then return end
  
  -- Skip if debug display is disabled
  if not getSetting("debug.display.enabled", true) then return end
  
  -- Update time
  Debug.lastTime = love.timer.getTime()
  
  -- Get max time-to-live for messages
  local ttl = getSetting("debug.display.ttl_secs", 20)
  
  -- Remove expired messages
  for i = #Debug.messages, 1, -1 do
    local msg = Debug.messages[i]
    if Debug.lastTime - msg.time > ttl then
      table.remove(Debug.messages, i)
    end
  end
end

-- Draw the debug overlay
function Debug.draw()
  -- Skip if debug display is not initialized
  if not Debug.messages then return end
  
  -- Skip if debug display is disabled
  if not getSetting("debug.display.enabled", true) then return end
  
  -- Skip if master debug flag is disabled
  if not getSetting("debug.enabled", true) then return end
  
  -- Save current graphics state
  love.graphics.push("all")
  
  -- Set font for debug messages
  love.graphics.setFont(Debug.font)
  
  -- Define size constraints for debug overlay
  local maxWidth = 350 -- Maximum width for debug overlay
  local maxHeight = 200 -- Maximum height to ensure it doesn't take over the screen
  local lineHeight = getSetting("debug.display.font_size", 10) + 2 -- Line height with spacing
  
  -- Calculate how many messages we can display based on max height
  local maxVisibleMessages = math.floor((maxHeight - 4) / lineHeight)
  local messageCount = math.min(#Debug.messages, maxVisibleMessages)
  
  -- Calculate actual width and height
  local width = maxWidth
  local height = messageCount * lineHeight + 4
  
  -- Get background color with fallback to semi-transparent black
  local bgColor = getSetting("debug.display.bg_color", {0, 0, 0, 0.5})
  love.graphics.setColor(bgColor)
  
  -- Draw background with rounded corners for better appearance
  love.graphics.rectangle("fill", 4, 4, width, height, 4, 4)
  
  -- Get only the most recent messages that fit in our display area
  local visibleMessages = {}
  for i = math.max(1, #Debug.messages - maxVisibleMessages + 1), #Debug.messages do
    table.insert(visibleMessages, Debug.messages[i])
  end
  
  -- Display overflow indicator if needed
  if #Debug.messages > maxVisibleMessages then
    local overflowCount = #Debug.messages - maxVisibleMessages
    local indicatorColor = getSetting("debug.display.font_color", {1, 0.5, 0, 1})
    love.graphics.setColor(indicatorColor[1], indicatorColor[2], indicatorColor[3], 0.5)
    love.graphics.print("+ " .. overflowCount .. " more", 8, 6)
  end
  
  -- Draw each visible message
  local y = 6
  for i, message in ipairs(visibleMessages) do
    -- Set message color
    local fontColor = getSetting("debug.display.font_color", {1, 0.5, 0, 1})
    love.graphics.setColor(fontColor)
    
    -- Format message with tag
    local text = string.format("[%s] %s", message.tag, message.text)
    
    -- Truncate message if it's too long for the display
    if love.graphics.getFont():getWidth(text) > maxWidth - 10 then
      -- Find the maximum number of characters that will fit
      local maxChars = 0
      for i = 1, #text do
        if love.graphics.getFont():getWidth(text:sub(1, i)) > maxWidth - 10 then
          maxChars = i - 4 -- Allow space for ellipsis
          break
        end
      end
      
      -- Truncate and add ellipsis
      if maxChars > 0 then
        text = text:sub(1, maxChars) .. "..."
      end
    end
    
    -- Draw the message
    love.graphics.print(text, 8, y)
    
    -- Move to next line
    y = y + lineHeight
  end
  
  -- Restore graphics state
  love.graphics.pop()
end

-- Return the Debug module
return Debug
