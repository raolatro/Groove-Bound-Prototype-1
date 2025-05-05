-- Passives data module
-- Contains all passive upgrades and their properties

local Passives = {}

-- Default/fallback values for any missing passive properties
Passives.defaults = {
  level = 1,                -- Default starting level
  multiplier = 1.0,         -- Default multiplier (no effect)
  description = "Passive upgrade", -- Default description
  max_level = 5             -- Maximum level a passive can reach
}

-- Available passive upgrades in the game
Passives.types = {
  -- Speed Boost
  speed_boost = {
    id = "speed_boost",
    name = "Speed Boost",
    description = "Increases player movement speed",
    base_multiplier = 1.15,     -- Starting multiplier at level 1
    level_increment = 0.15,     -- Increase per level
    max_level = 5,              -- Maximum level
    effect_type = "speed"       -- What this passive affects
  },
  
  -- Health Up
  health_up = {
    id = "health_up",
    name = "Health Up",
    description = "Increases player maximum health",
    base_multiplier = 1.2,      -- Starting multiplier at level 1
    level_increment = 0.2,      -- Increase per level
    max_level = 5,              -- Maximum level
    effect_type = "health"      -- What this passive affects
  },
  
  -- Damage Boost
  damage_boost = {
    id = "damage_boost",
    name = "Damage Boost",
    description = "Increases damage of all weapons",
    base_multiplier = 1.1,      -- Starting multiplier at level 1
    level_increment = 0.1,      -- Increase per level 
    max_level = 5,              -- Maximum level
    effect_type = "damage"      -- What this passive affects
  },
  
  -- Rhythm Shield
  rhythm_shield = {
    id = "rhythm_shield",
    name = "Rhythm Shield",
    description = "Gives chance to block incoming damage",
    base_multiplier = 0.15,     -- 15% block chance at level 1
    level_increment = 0.1,      -- +10% per level
    max_level = 3,              -- Maximum level (45% at level 3)
    effect_type = "shield"      -- What this passive affects
  }
}

-- Helper function to get a passive by ID, with fallback to defaults for missing properties
function Passives.get(passiveId)
  local passive = Passives.types[passiveId]
  
  -- If passive doesn't exist, return nil
  if not passive then
    return nil
  end
  
  -- Create a new table to avoid modifying the original
  local result = {}
  
  -- Apply defaults for any missing properties
  for key, value in pairs(Passives.defaults) do
    result[key] = passive[key] or value
  end
  
  -- Copy all properties from the passive
  for key, value in pairs(passive) do
    result[key] = value
  end
  
  return result
end

-- Get a list of all passive IDs
function Passives.getAllIds()
  local ids = {}
  for id, _ in pairs(Passives.types) do
    table.insert(ids, id)
  end
  return ids
end

-- Return the module
return Passives
