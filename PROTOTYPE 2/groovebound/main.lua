-- Groove Bound Prototype
-- Main file that initializes all systems and runs the game loop

-- Set up a global safe logging mechanism that works before Debug is initialized
_G.pendingLogs = {}

-- SafeLog is used before Debug is fully initialized
-- Will forward messages to Debug.log once it's available
function SafeLog(tag, message)
  -- Always log to console for immediate feedback
  print(string.format("[%s] %s: %s", os.date("%H:%M:%S"), tag, message))
  
  -- Store the log to be forwarded to Debug.log once available
  table.insert(_G.pendingLogs, {tag = tag, message = message})
  
  -- If Debug has been initialized, also log there directly
  if Debug and Debug.log then
    Debug.log(tag, message)
  end
end

-- Set up a global debug accessor with fallback to SafeLog
_G.Debug = _G.Debug or {}
_G.Debug.log = _G.Debug.log or SafeLog

-- Global error handling with detailed reporting
local function errorHandler(msg)
  print("ERROR: " .. tostring(msg))
  print(debug.traceback("Stack trace:"))
  
  -- Store error message for display
  _G.error_message = msg
  
  -- Also create a minimal debug display if regular one fails
  if not _G.emergency_log then
    _G.emergency_log = {}
  end
  
  -- Add error to emergency log with timestamp
  table.insert(_G.emergency_log, { 
    message = tostring(msg), 
    time = os.time() 
  })
  
  return msg
end

-- Load core systems
local function loadCoreSystems()
  -- Set up the logs directory if it doesn't exist
  if not love.filesystem.getInfo("logs") then
    love.filesystem.createDirectory("logs")
  end

  -- Load paths first to ensure all other modules can find files
  Paths = require("src/core/paths")
  
  -- Load settings
  Settings = require("src/core/settings")
  
  -- Initialize global debug system
  Debug = require("src/ui/debug_display")
  Debug:init()
  
  -- Initialize event bus
  EventBus = require("src/core/event_bus")
  
  -- Initialize logger
  Logger = require("src/core/logger")
  Logger:init()
  Logger:info("Game started")
  
  -- Initialize state stack
  StateStack = require("src/core/state_stack")
  StateStack:init()
  
  -- Initialize input system
  Input = require("src/core/input")
  Input:init()
  
  -- Load globals
  _G.BlockGrid = require("src/ui/block_grid")
  local screenWidth, screenHeight = love.graphics.getDimensions()
  _G.BlockGrid:init(screenWidth, screenHeight)
  
  Logger:info("All core systems initialized")
end

-- Initialize the game
function love.load()
  -- Store any errors
  _G.error_message = nil
  
  -- Set up basic error handling
  xpcall(function()
    -- Load all core systems
    loadCoreSystems()
    
    -- Set background color
    love.graphics.setBackgroundColor(0.2, 0.2, 0.2)
    
    -- Push initial state
    local BootSplashState = require("src/ui/states/boot_splash")
    StateStack:push(BootSplashState)
    
    Logger:info("Game initialization complete")
  end, errorHandler)
end

-- Update game state
function love.update(dt)
  -- Skip updates if there was an error
  if _G.error_message then return end

  -- Update with error handling
  xpcall(function()
    -- Update debug overlay (if enabled)
    if Debug then Debug:update(dt) end
    
    -- Update state stack
    if StateStack then StateStack:update(dt) end
  end, errorHandler)
end

-- Draw the game
function love.draw()
  -- Draw error message if there is one
  if _G.error_message then
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.print("ERROR: " .. tostring(_G.error_message), 50, 50)
    
    -- Display emergency log if available
    if _G.emergency_log and #_G.emergency_log > 0 then
      love.graphics.print("Error Log:", 50, 80)
      for i, entry in ipairs(_G.emergency_log) do
        love.graphics.print(i .. ". " .. entry.message, 60, 80 + (i * 20))
      end
    end
    
    -- Show a hint about how to troubleshoot
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.print("Check console for detailed stack trace", 50, 300)
    return
  end
  
  -- Draw with error handling
  xpcall(function()
    -- Draw current state
    if StateStack then StateStack:draw() end
    
    -- Draw debug overlay (if enabled)
    if Debug then Debug:draw() end
  end, errorHandler)
end



-- Handle key presses
function love.keypressed(key)
  -- Skip if there was an error
  if _G.error_message then return end
  
  -- Forward to input system
  if Input then Input:keypressed(key) end
  
  -- Forward to state stack
  if StateStack then StateStack:keypressed(key) end
end

-- Handle key releases
function love.keyreleased(key)
  -- Skip if there was an error
  if _G.error_message then return end
  
  -- Forward to input system
  if Input then Input:keyreleased(key) end
  
  -- Forward to state stack
  if StateStack then StateStack:keyreleased(key) end
end

-- Handle mouse presses
function love.mousepressed(x, y, button)
  -- Skip if there was an error
  if _G.error_message then return end
  
  -- Forward to input system
  if Input then Input:mousepressed(button) end
  
  -- Forward to state stack
  if StateStack then StateStack:mousepressed(x, y, button) end
end

-- Handle mouse releases
function love.mousereleased(x, y, button)
  -- Skip if there was an error
  if _G.error_message then return end
  
  -- Forward to input system
  if Input then Input:mousereleased(button) end
  
  -- Forward to state stack
  if StateStack then StateStack:mousereleased(x, y, button) end
end

-- Handle mouse movement
function love.mousemoved(x, y, dx, dy)
  -- Skip if there was an error
  if _G.error_message then return end
  
  -- Update mouse position in input system
  if Input then Input:updateMouse(x, y) end
  
  -- Forward to state stack
  if StateStack then StateStack:mousemoved(x, y, dx, dy) end
end

-- Error handler
function love.errorhandler(msg)
  print("ERROR: " .. tostring(msg))
  print(debug.traceback())
  _G.error_message = msg
  return true
end
