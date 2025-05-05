-- Enemies data module
-- Contains all enemy definitions and properties

local Enemies = {}

-- Default/fallback values for any missing enemy properties
Enemies.defaults = {
  hp = 20,               -- Default health points
  speed = 60,            -- Default movement speed
  size = 12,             -- Default enemy size
  damage = 10,           -- Default damage dealt to player
  spawn_distance = 400,  -- Default min spawn distance from player
  xp_value = 10,         -- Default XP dropped when killed
  color = {1, 0, 0, 1}   -- Default enemy color (red)
}

-- Available enemy types in the game
Enemies.types = {
  -- Basic enemy type
  basic = {
    id = "basic",
    name = "Basic Enemy",
    hp = 20,             -- Health points
    speed = 60,          -- Movement speed
    size = 12,           -- Enemy size
    damage = 10,         -- Damage dealt to player
    spawn_distance = 400, -- Min spawn distance from player
    xp_value = 10,       -- XP dropped when killed
    color = {1, 0, 0, 1}, -- Enemy color (red)
  },
  
  -- Intermediate enemy type
  intermediate = {
    id = "intermediate",
    name = "Intermediate Enemy",
    hp = 50,             -- Health points
    speed = 120,         -- Movement speed
    size = 24,           -- Enemy size
    damage = 20,         -- Damage dealt to player
    spawn_distance = 600, -- Min spawn distance from player
    xp_value = 20,       -- XP dropped when killed
    color = {0, 1, 1, 1}, -- Enemy color (cyan)
  },
  
  -- Advanced enemy type
  advanced = {
    id = "advanced",
    name = "Advanced Enemy",
    hp = 100,            -- Health points
    speed = 180,         -- Movement speed
    size = 36,           -- Enemy size
    damage = 30,         -- Damage dealt to player
    spawn_distance = 800, -- Min spawn distance from player
    xp_value = 30,       -- XP dropped when killed
    color = {1, 0, 1, 1}, -- Enemy color (purple)
  }
}

-- Helper function to get an enemy by ID, with fallback to defaults for missing properties
function Enemies.get(enemyId)
  local enemy = Enemies.types[enemyId]
  
  -- If enemy doesn't exist, return the default basic enemy
  if not enemy then
    return Enemies.types.basic
  end
  
  -- Create a new table to avoid modifying the original
  local result = {}
  
  -- Apply defaults for any missing properties
  for key, value in pairs(Enemies.defaults) do
    result[key] = enemy[key] or value
  end
  
  -- Copy all properties from the enemy
  for key, value in pairs(enemy) do
    result[key] = value
  end
  
  return result
end

-- Get a list of all enemy IDs
function Enemies.getAllIds()
  local ids = {}
  for id, _ in pairs(Enemies.types) do
    table.insert(ids, id)
  end
  return ids
end

-- Return the module
return Enemies
