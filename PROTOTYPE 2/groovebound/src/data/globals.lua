-- Globals module
-- Mirrors settings.globals for hot-reloading
-- This allows globals to be modified during runtime

-- Initialize by copying values from settings.globals
local globals = {}

-- Function to reload globals from settings
local function reload()
  -- Get settings module
  local settings = require("src.core.settings")
  
  -- Clear current globals
  for k in pairs(globals) do
    globals[k] = nil
  end
  
  -- Copy globals from settings
  for k, v in pairs(settings.globals) do
    globals[k] = v
  end
end

-- Load globals on initialization
reload()

-- Function to get a global value
-- @param key - The global setting key
-- @return The value of the global setting
function globals.get(key)
  return globals[key]
end

-- Function to set a global value
-- @param key - The global setting key
-- @param value - The new value
function globals.set(key, value)
  globals[key] = value
end

-- Function to reload globals from settings
function globals.reload()
  reload()
end

-- Return the module
return globals
