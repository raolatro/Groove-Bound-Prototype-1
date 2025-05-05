-- Waves data module
-- Contains enemy wave definitions and spawn patterns

local Waves = {}

-- Wave definitions for different game stages
Waves.patterns = {
  -- Early game waves (0-30 seconds)
  early = {
    {
      -- Wave 1: Basic enemies only
      duration = 10,           -- Wave duration in seconds
      enemies = {
        {
          type = "basic",      -- Enemy type to spawn
          count = 5,           -- Number of enemies to spawn during wave
          spawn_delay = 2,     -- Delay between spawns in seconds
        }
      }
    },
    {
      -- Wave 2: Increased basic enemies
      duration = 10,
      enemies = {
        {
          type = "basic",
          count = 8,
          spawn_delay = 1.5,
        }
      }
    },
    {
      -- Wave 3: Basic enemies + first intermediate
      duration = 10,
      enemies = {
        {
          type = "basic",
          count = 8,
          spawn_delay = 1.5,
        },
        {
          type = "intermediate",
          count = 1,
          spawn_delay = 5,
        }
      }
    }
  },
  
  -- Mid game waves (30-120 seconds)
  mid = {
    {
      -- Wave 4: Mix of basic and intermediate
      duration = 15,
      enemies = {
        {
          type = "basic",
          count = 12,
          spawn_delay = 1.25,
        },
        {
          type = "intermediate",
          count = 3,
          spawn_delay = 5,
        }
      }
    },
    {
      -- Wave 5: More challenging mix
      duration = 15,
      enemies = {
        {
          type = "basic",
          count = 15,
          spawn_delay = 1,
        },
        {
          type = "intermediate",
          count = 5,
          spawn_delay = 3,
        }
      }
    },
    {
      -- Wave 6: First advanced enemy
      duration = 15,
      enemies = {
        {
          type = "basic",
          count = 10,
          spawn_delay = 1.5,
        },
        {
          type = "intermediate",
          count = 5,
          spawn_delay = 2,
        },
        {
          type = "advanced",
          count = 1,
          spawn_delay = 2.5,
        }
      }
    }
  },
  
  -- Late game waves (120+ seconds)
  late = {
    {
      -- Wave 7: Heavy mix of all types
      duration = 20,
      enemies = {
        {
          type = "basic",
          count = 20,
          spawn_delay = 1,
        },
        {
          type = "intermediate",
          count = 8,
          spawn_delay = 2.5,
        },
        {
          type = "advanced",
          count = 3,
          spawn_delay = 6,
        }
      }
    },
    {
      -- Wave 8: Pre-boss challenge
      duration = 20,
      enemies = {
        {
          type = "basic",
          count = 15,
          spawn_delay = 1.3,
        },
        {
          type = "intermediate",
          count = 10,
          spawn_delay = 2,
        },
        {
          type = "advanced",
          count = 5,
          spawn_delay = 4,
        }
      }
    }
  },
  
  -- Boss encounters
  boss = {
    {
      -- Final boss wave
      duration = 30,
      enemies = {
        -- Continuous stream of basic enemies during boss fight
        {
          type = "basic",
          count = 15,
          spawn_delay = 2,
        },
        -- A few intermediate enemies
        {
          type = "intermediate",
          count = 5,
          spawn_delay = 6,
        },
        -- The boss itself
        {
          type = "boss",
          count = 1,
          spawn_delay = 1,
          spawn_position = "center"
        }
      }
    }
  }
}

-- Get wave pattern based on game time
-- @param gameTime - Current time in seconds since start of run
-- @return The appropriate wave pattern for the current time
function Waves.getWaveForTime(gameTime)
  -- Early game (0-30 seconds)
  if gameTime < 30 then
    local index = math.floor(gameTime / 10) + 1
    return Waves.patterns.early[math.min(index, #Waves.patterns.early)]
  -- Mid game (30-120 seconds)
  elseif gameTime < 120 then
    local progress = (gameTime - 30) / 90
    local index = math.floor(progress * #Waves.patterns.mid) + 1
    return Waves.patterns.mid[math.min(index, #Waves.patterns.mid)]
  -- Late game (120+ seconds)
  else
    local progress = math.min((gameTime - 120) / 60, 1)
    local index = math.floor(progress * #Waves.patterns.late) + 1
    return Waves.patterns.late[math.min(index, #Waves.patterns.late)]
  end
end

-- Check if it's time for the boss
-- @param gameTime - Current time in seconds since start of run
-- @param runDuration - Total duration of the run in seconds
-- @return true if it's boss time
function Waves.isBossTime(gameTime, runDuration)
  -- Spawn boss in the last 30 seconds of the run
  return gameTime >= (runDuration - 30)
end

-- Get the boss wave
-- @return The boss wave pattern
function Waves.getBossWave()
  return Waves.patterns.boss[1] 
end

-- Return the module
return Waves
