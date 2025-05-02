-- Logger module
-- Handles logging to both runtime and error log files
-- Provides info and error logging functions with timestamps

local Logger = {}

-- Get the current date in YYYY-MM-DD format for log filenames
local function getDateString()
  local date = os.date("*t")
  return string.format("%04d-%02d-%02d", date.year, date.month, date.day)
end

-- Initialize the logger and open log files
function Logger:init()
  -- Create logs directory if it doesn't exist
  love.filesystem.createDirectory("logs")
  
  -- Get current date for log filenames
  local dateStr = getDateString()
  
  -- Set log file paths
  local runtimeLogName = "runtime_" .. dateStr .. ".txt"
  local errorLogName = "error_" .. dateStr .. ".txt"
  
  -- Store log file names for later use
  self.runtimeLogName = runtimeLogName
  self.errorLogName = errorLogName
  
  -- Print log paths for debugging
  print("Logger initialized. Runtime log: " .. runtimeLogName)
end

-- Get current timestamp for log entries
local function getTimestamp()
  return os.date("%Y-%m-%d %H:%M:%S")
end

-- Log informational message to runtime log and debug display
-- @param msg - The message to log
function Logger:info(msg)
  local timestamp = getTimestamp()
  local logEntry = string.format("[%s] INFO: %s", timestamp, msg)
  
  -- Write to runtime log file using LÖVE's file system
  pcall(function()
    love.filesystem.append("logs/" .. self.runtimeLogName, logEntry .. "\n")
  end)
  
  -- Also print to console for debugging
  print(logEntry)
  
  -- Send to debug display if available
  if Debug and Debug.log then
    Debug.log("INFO", msg)
  end
end

-- Log error message to both runtime and error logs, and debug display
-- @param msg - The error message to log
function Logger:error(msg)
  local timestamp = getTimestamp()
  local logEntry = string.format("[%s] ERROR: %s", timestamp, msg)
  
  -- Write to runtime log file using LÖVE's file system
  pcall(function()
    love.filesystem.append("logs/" .. self.runtimeLogName, logEntry .. "\n")
  end)
  
  -- Write to error log file using LÖVE's file system
  pcall(function()
    love.filesystem.append("logs/" .. self.errorLogName, logEntry .. "\n")
  end)
  
  -- Also print to console for debugging
  print("ERROR: " .. msg)
  
  -- Send to debug display if available
  if Debug and Debug.log then
    Debug.log("ERROR", msg)
  end
end

-- Return the module
return Logger
