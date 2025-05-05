-- Weapons data module
-- Contains all weapon definitions and properties
-- Separating data from settings for better organization

local Weapons = {}

-- Default/fallback values for any missing weapon properties
Weapons.defaults = {
  damage = 10,
  fire_rate = 0.5,
  bullet_speed = 250,
  bullet_size = 8,
  bullet_lifetime = 1.0,
  bullet_color = {1, 1, 1, 1},
  bullet_count = 1,        -- Default to single bullet
  spread = {
    mode = "fixed",        -- "fixed" or "full"
    angle = 0              -- Default to straight ahead
  }
}

-- Available weapons in the game
Weapons.types = {
  -- Base pistol
  pistol = {
    id = "pistol",
    name = "Pistol",
    description = "Standard energy pistol",
    damage = 30,
    fire_rate = 2,
    bullet_speed = 300,
    bullet_size = 10,
    bullet_lifetime = 3.0,
    bullet_color = {1, 0, 0, 1},
    bullet_count = 1,
    spread = {
      mode = "fixed",
      angle = 0  -- Straight ahead
    }
  },
  
  -- Power Chord
  power_chord = {
    id = "power_chord",
    name = "Power Chord",
    description = "Rapid fire energy bursts",
    damage = 15,
    fire_rate = 1,
    bullet_speed = 450,
    bullet_size = 6,
    bullet_lifetime = 1.2,
    bullet_color = {1, 0, 1, 1},
    bullet_count = 3,
    spread = {
      mode = "fixed",
      angle = 10  -- 10 degree spread between bullets
    }
  },
  
  -- Bass Drop
  bass_drop = {
    id = "bass_drop",
    name = "Bass Drop",
    description = "Heavy damage, slow fire rate",
    damage = 25,
    fire_rate = 2,
    bullet_speed = 300,
    bullet_size = 20,
    bullet_lifetime = 0.8,
    bullet_color = {0, 1, 1, 1},
    bullet_count = 1,
    spread = {
      mode = "fixed",
      angle = 0
    }
  },
  
  -- OmniGun
  omnigun = {
    id = "omnigun",
    name = "OmniGun",
    description = "Fast, powerful bursts in all directions",
    damage = 50,
    fire_rate = 0.2,
    bullet_speed = 600,
    bullet_size = 16,
    bullet_lifetime = 0.5,
    bullet_color = {1, 1, 0, 1},
    bullet_count = 8,
    spread = {
      mode = "full" -- Spread bullets in a full 360 degree circle
    }
  }
}

-- Helper function to get a weapon by ID, with fallback to defaults for missing properties
function Weapons.get(weaponId)
  local weapon = Weapons.types[weaponId]
  
  -- If weapon doesn't exist, return the default pistol
  if not weapon then
    return Weapons.types.pistol
  end
  
  -- Create a new table to avoid modifying the original
  local result = {}
  
  -- Apply defaults for any missing properties
  for key, value in pairs(Weapons.defaults) do
    result[key] = weapon[key] or value
  end
  
  -- Copy all properties from the weapon
  for key, value in pairs(weapon) do
    result[key] = value
  end
  
  return result
end

-- Get a list of all weapon IDs
function Weapons.getAllIds()
  local ids = {}
  for id, _ in pairs(Weapons.types) do
    table.insert(ids, id)
  end
  return ids
end

-- Return the module
return Weapons
