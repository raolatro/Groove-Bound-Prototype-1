-- Spawner system
-- Handles spawning waves of enemies based on game time

local Enemy = require("src/entities/enemy")

local Spawner = {}

-- Create a new spawner
-- @param player - Reference to the player entity
-- @return A new spawner object
function Spawner.new(player)
  local self = {
    player = player,      -- Reference to the player
    gameTime = 0,         -- Current game time
    enemies = {},         -- Table of active enemies
    lastWaveTime = 0,     -- Time of the last spawned wave
    
    -- Time table for enemy spawns - {time, count} pairs
    -- Waves will spawn at these time marks with the specified count
    timetable = {
      {t = 1, count = 5},
      {t = 5, count = 10},
      {t = 10, count = 15},
      {t = 15, count = 20},
      {t = 20, count = 25},
      {t = 30, count = 30},
      {t = 40, count = 35},
      {t = 50, count = 40}
    },
    
    nextWaveIndex = 1,     -- Index to the next wave in the timetable
    runDuration = 60,      -- Game run duration (from settings)
    spawnMultiplier = 1.0  -- Tunable spawn rate multiplier
  }
  
  -- Set the metatable for the spawner object
  setmetatable(self, {__index = Spawner})
  
  -- Get run duration from settings if available
  if Settings and Settings.globals and Settings.globals.run_duration then
    self.runDuration = Settings.globals.run_duration
  end
  
  -- Get spawn multiplier if debug tuning is available
  if Settings and Settings.debug_tune and Settings.debug_tune.enemy_spawn_rate then
    self.spawnMultiplier = Settings.debug_tune.enemy_spawn_rate.value
  end
  
  return self
end

-- Update the spawner system
-- @param dt - Delta time since last update
function Spawner:update(dt)
  -- Update game time
  self.gameTime = self.gameTime + dt
  
  -- Check if we should stop spawning (5 seconds before run end)
  local stopSpawnTime = self.runDuration - 5
  
  -- For Phase 3, we'll continue spawning endlessly since boss isn't implemented yet
  -- When Phase 4 adds the boss, we'll use the stopSpawnTime logic
  
  -- Check if it's time for a new wave
  if self.nextWaveIndex <= #self.timetable then
    local nextWave = self.timetable[self.nextWaveIndex]
    
    if self.gameTime >= nextWave.t then
      -- Spawn the wave
      self:spawnWave(nextWave.count)
      
      -- Log the wave start
      if Debug then
        Debug.log("WAVE", "Wave " .. self.nextWaveIndex .. " started with " .. nextWave.count .. " enemies")
      end
      
      -- Emit wave start event
      if EventBus then
        EventBus:emit("WAVE_START", {
          wave = self.nextWaveIndex,
          count = nextWave.count
        })
      end
      
      -- Move to the next wave
      self.nextWaveIndex = self.nextWaveIndex + 1
      self.lastWaveTime = self.gameTime
    end
  else
    -- After the last scripted wave, spawn smaller waves periodically
    local timeSinceLastWave = self.gameTime - self.lastWaveTime
    
    if timeSinceLastWave > 5 then  -- Every 5 seconds
      -- Calculate count based on game time
      local count = math.floor(5 + self.gameTime / 10)
      
      -- Spawn the wave
      self:spawnWave(count)
      
      -- Log the wave start
      if Debug then
        Debug.log("WAVE", "Extra wave started with " .. count .. " enemies")
      end
      
      -- Emit wave start event
      if EventBus then
        EventBus:emit("WAVE_START", {
          wave = "extra",
          count = count
        })
      end
      
      self.lastWaveTime = self.gameTime
    end
  end
  
  -- Update all active enemies
  for i = #self.enemies, 1, -1 do
    local enemy = self.enemies[i]
    enemy:update(dt)
    
    -- Remove dead enemies
    if enemy.isDead then
      table.remove(self.enemies, i)
    end
  end
end

-- Spawn a wave of enemies
-- @param count - Number of enemies to spawn
function Spawner:spawnWave(count)
  -- Apply spawn multiplier from debug tuning
  local adjustedCount = math.floor(count * self.spawnMultiplier)
  
  -- Get screen dimensions
  local width, height = love.graphics.getDimensions()
  
  -- Spawn the requested number of enemies
  for i = 1, adjustedCount do
    -- Choose a random position on the screen edge
    local x, y = self:getSpawnPosition(width, height)
    
    -- Create a new enemy
    local enemy = Enemy.new(x, y, self.player)
    
    -- Add to active enemies list
    table.insert(self.enemies, enemy)
  end
end

-- Get a random position on the screen edge for spawning
-- @param width - Screen width
-- @param height - Screen height
-- @return x, y - Spawn coordinates
function Spawner:getSpawnPosition(width, height)
  -- Minimum distance from player to spawn
  local minDistance = 150
  
  -- Edge padding
  local padding = 20
  
  local x, y
  local validPosition = false
  
  -- Keep trying until we get a valid position
  while not validPosition do
    -- Choose which edge to spawn on (0=top, 1=right, 2=bottom, 3=left)
    local edge = math.floor(math.random() * 4)
    
    if edge == 0 then
      -- Top edge
      x = math.random(padding, width - padding)
      y = padding
    elseif edge == 1 then
      -- Right edge
      x = width - padding
      y = math.random(padding, height - padding)
    elseif edge == 2 then
      -- Bottom edge
      x = math.random(padding, width - padding)
      y = height - padding
    else
      -- Left edge
      x = padding
      y = math.random(padding, height - padding)
    end
    
    -- Check distance from player
    local dx = x - self.player.x
    local dy = y - self.player.y
    local dist = math.sqrt(dx * dx + dy * dy)
    
    if dist >= minDistance then
      validPosition = true
    end
  end
  
  return x, y
end

-- Draw all enemies
function Spawner:draw()
  for _, enemy in ipairs(self.enemies) do
    enemy:draw()
  end
end

-- Get the list of active enemies
-- @return Table of enemies
function Spawner:getEnemies()
  return self.enemies
end

-- Return the spawner module
return Spawner
