-- Spawner system
-- Handles spawning waves of enemies based on game time
-- Implements gradual spawning from different directions around the arena

local Enemy = require("src/entities/enemy")
local Settings = require("src/core/settings")

local Spawner = {}

-- Create a new spawner
-- @param player - Reference to the player entity
-- @param arenaManager - Reference to the arena manager for positioning
-- @return A new spawner object
function Spawner.new(player, arenaManager)
  -- Get spawner settings
  local spawnerSettings = Settings.spawner
  
  local self = {
    player = player,              -- Reference to the player
    arenaManager = arenaManager,  -- Reference to arena boundaries
    gameTime = 0,                 -- Current game time in seconds
    enemies = {},                 -- Table of active enemies
    lastWaveTime = 0,             -- Time when last wave started
    nextSpawnTime = 0,            -- Time for next individual enemy spawn
    pendingSpawns = 0,            -- Number of enemies waiting to be spawned in current wave
    waveInProgress = false,       -- Whether a wave is currently spawning
    
    -- Spawn intervals
    minSpawnInterval = spawnerSettings.min_spawn_interval, -- Minimum time between spawns
    maxSpawnInterval = spawnerSettings.max_spawn_interval, -- Maximum time between spawns
    
    -- Wave configuration - enemies per wave at different time marks
    waveConfig = {
      {time = 1,  count = spawnerSettings.wave_sizes[1]},
      {time = 15, count = spawnerSettings.wave_sizes[2]},
      {time = 30, count = spawnerSettings.wave_sizes[3]},
      {time = 45, count = spawnerSettings.wave_sizes[4]},
      {time = 60, count = spawnerSettings.wave_sizes[5]}
    },
    
    nextWaveIndex = 1,           -- Index of the next wave to spawn
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
  
  -- Check for new waves to start
  self:checkWaveStart()
  
  -- Process gradual enemy spawning
  self:processGradualSpawning(dt)
  
  -- Update all enemies
  for i = #self.enemies, 1, -1 do
    local enemy = self.enemies[i]
    enemy:update(dt)
    
    -- Remove dead enemies that have completed fadeout
    if enemy:shouldRemove() then
      table.remove(self.enemies, i)
    end
  end
end

-- Check if a new wave should start
function Spawner:checkWaveStart()
  -- Skip if no more waves or already spawning
  if self.nextWaveIndex > #self.waveConfig or self.waveInProgress then
    return
  end
  
  -- Get the next wave info
  local nextWave = self.waveConfig[self.nextWaveIndex]
  
  -- Check if it's time to start this wave
  if self.gameTime >= nextWave.time then
    -- Start a new wave
    self:startNewWave(nextWave.count)
    
    -- Move to the next wave configuration
    self.nextWaveIndex = self.nextWaveIndex + 1
    self.lastWaveTime = self.gameTime
    
    -- Log wave start if debug is available
    if Debug and Debug.log then
      Debug.log("SPAWN", "Wave " .. (self.nextWaveIndex - 1) .. " started: " .. nextWave.count .. " enemies at time " .. string.format("%.1f", self.gameTime))
    end
    
    -- Emit wave start event
    if EventBus then
      EventBus:emit("WAVE_START", {count = nextWave.count, time = self.gameTime})
    end
  end
end

-- Start a new wave
-- @param count - Number of enemies in the wave
function Spawner:startNewWave(count)
  self.pendingSpawns = count
  self.waveInProgress = true
  self.nextSpawnTime = self.gameTime
  
  -- Immediately spawn the first enemy
  self:spawnSingleEnemy()
  self.pendingSpawns = self.pendingSpawns - 1
end

-- Process gradual spawning of enemies
-- @param dt - Delta time since last update
function Spawner:processGradualSpawning(dt)
  -- Skip if no wave in progress or no pending spawns
  if not self.waveInProgress or self.pendingSpawns <= 0 then
    -- Mark wave as complete if all enemies spawned
    if self.waveInProgress and self.pendingSpawns <= 0 then
      self.waveInProgress = false
    end
    return
  end
  
  -- Check if it's time to spawn the next enemy
  if self.gameTime >= self.nextSpawnTime then
    -- Spawn an enemy
    self:spawnSingleEnemy()
    
    -- Reduce pending spawns
    self.pendingSpawns = self.pendingSpawns - 1
    
    -- Calculate time for next spawn
    local spawnInterval = self.minSpawnInterval + math.random() * (self.maxSpawnInterval - self.minSpawnInterval)
    self.nextSpawnTime = self.gameTime + spawnInterval
  end
end

-- Spawn a single enemy at a random position
function Spawner:spawnSingleEnemy()
  -- Require arena manager to determine spawn positions
  if not self.arenaManager then
    if Debug and Debug.log then
      Debug.log("ERROR", "Cannot spawn enemy: Arena manager not available")
    end
    return
  end
  
  -- Get spawn parameters
  local minDist = Settings.spawner.min_spawn_distance
  local maxDist = Settings.spawner.max_spawn_distance
  
  -- Get random position around player
  local x, y = self.arenaManager:getRandomPositionAroundTarget(
    self.player.x, 
    self.player.y, 
    minDist,
    maxDist
  )
  
  -- Create an enemy
  local enemy = Enemy.new(x, y, self.player, self.arenaManager)
  table.insert(self.enemies, enemy)
  
  -- Log spawn if debug is available
  if Debug and Debug.log then
    Debug.log("SPAWN", "Enemy spawned at " .. string.format("%.1f, %.1f", x, y))
  end
end

-- Draw all enemies
function Spawner:draw()
  -- Draw each enemy
  for _, enemy in ipairs(self.enemies) do
    enemy:draw()
  end
end

-- Get list of active enemies
-- @return Table of enemy objects
function Spawner:getEnemies()
  return self.enemies
end

-- Return the spawner module
return Spawner
