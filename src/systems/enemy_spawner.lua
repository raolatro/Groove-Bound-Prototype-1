-- enemy_spawner.lua
-- Handles timed spawning of enemies with safe radius logic

local L = require("lib.loader")
local Config = require("config.settings")
local PATHS = require("config.paths")
local EnemyDefs = require("src.data.enemy_defs")
local Debug = require("src.debug")

-- Constants
local TUNING = Config.TUNING.ENEMIES
local DEV = Config.DEV
local TWO_PI = math.pi * 2

-- Local references
local VecNormalize = L.utils.math.normalize

-- The EnemySpawner module
local EnemySpawner = {
    -- Spawn timer
    timer = 0,
    spawnInterval = 1 / TUNING.BASE_SPAWN_RATE,
    
    -- Reference to player and enemy system
    player = nil,
    enemySystem = nil,
    
    -- Weighted enemy table for spawn selection
    weightedEnemies = {},
    totalWeight = 0,
    
    -- State
    initialized = false,
    enabled = true,
    world = nil -- Physics world reference
}

-- Initialize the enemy spawner
function EnemySpawner:init(player, enemySystem, world)
    -- Store references
    self.player = player
    self.enemySystem = enemySystem
    self.world = world
    
    -- Calculate weighted enemy table for random selection
    self:buildWeightedTable()
    
    -- Mark as initialized
    self.initialized = true
    
    -- Debug output
    if _G.DEBUG_MASTER and _G.DEBUG_ENEMIES then
        Debug.log("Enemy Spawner initialized with " .. #EnemyDefs.enemies .. " enemy types")
    end
    
    return self
end

-- Build weighted table for random enemy selection
function EnemySpawner:buildWeightedTable()
    self.weightedEnemies = {}
    self.totalWeight = 0
    
    for _, enemy in ipairs(EnemyDefs.enemies) do
        -- Add to total weight
        self.totalWeight = self.totalWeight + enemy.spawnRate
        
        -- Add to weighted table
        table.insert(self.weightedEnemies, {
            enemyDef = enemy,
            weight = enemy.spawnRate,
            accumulatedWeight = self.totalWeight
        })
    end
    
    if _G.DEBUG_MASTER and _G.DEBUG_ENEMIES then
        Debug.log("Built weighted enemy table with total weight: " .. self.totalWeight)
    end
end

-- Randomly select an enemy based on spawn rates
function EnemySpawner:selectRandomEnemy()
    -- If no enemies defined, return nil
    if #self.weightedEnemies == 0 then
        return nil
    end
    
    -- Get a random value between 0 and total weight
    local value = math.random() * self.totalWeight
    
    -- Find the enemy whose accumulated weight exceeds the random value
    for _, entry in ipairs(self.weightedEnemies) do
        if value <= entry.accumulatedWeight then
            return entry.enemyDef
        end
    end
    
    -- Fallback to first enemy (should never happen)
    return self.weightedEnemies[1].enemyDef
end

-- Find a valid spawn position on a radius around the player
function EnemySpawner:findSpawnPosition()
    if not self.player or not self.player.collider then
        return nil
    end
    
    -- Get player position
    local playerX, playerY = self.player.collider:getPosition()
    
    -- Try to find a valid spawn position (up to 10 attempts)
    for attempt = 1, 10 do
        -- Random angle around player
        local angle = math.random() * TWO_PI
        
        -- Random distance between safe radius and safe radius + 200
        local distance = TUNING.SAFE_SPAWN_RADIUS + math.random() * 200
        
        -- Calculate position
        local spawnX = playerX + math.cos(angle) * distance
        local spawnY = playerY + math.sin(angle) * distance
        
        -- Check if position is valid (not inside a wall)
        if self:isValidSpawnPosition(spawnX, spawnY) then
            return spawnX, spawnY
        end
    end
    
    -- If all attempts failed, just return a position and hope for the best
    local fallbackAngle = math.random() * TWO_PI
    local fallbackDistance = TUNING.SAFE_SPAWN_RADIUS + 100
    
    return playerX + math.cos(fallbackAngle) * fallbackDistance,
           playerY + math.sin(fallbackAngle) * fallbackDistance
end

-- Check if a spawn position is valid (not inside a wall)
function EnemySpawner:isValidSpawnPosition(x, y)
    -- If no world, assume valid
    if not self.world then
        return true
    end
    
    -- Check for collisions with walls
    local fixtures = self.world:queryPoint(x, y)
    for _, fixture in ipairs(fixtures) do
        local collisionClass = fixture:getBody():getFixture():getUserData()
        if collisionClass and collisionClass.collision_class == "wall" then
            return false
        end
    end
    
    return true
end

-- Spawn a random enemy at a valid position
function EnemySpawner:spawnRandomEnemy()
    -- Select a random enemy
    local enemyDef = self:selectRandomEnemy()
    if not enemyDef then
        if _G.DEBUG_MASTER and _G.DEBUG_ENEMIES then
            Debug.log("No enemy definitions available to spawn")
        end
        return
    end
    
    -- Find a valid spawn position
    local spawnX, spawnY = self:findSpawnPosition()
    if not spawnX or not spawnY then
        if _G.DEBUG_MASTER and _G.DEBUG_ENEMIES then
            Debug.log("Failed to find valid spawn position")
        end
        return
    end
    
    -- Spawn the enemy
    local enemy = self.enemySystem:spawn(enemyDef, spawnX, spawnY)
    
    -- Debug output
    if _G.DEBUG_MASTER and _G.DEBUG_ENEMIES then
        Debug.log(string.format("Spawned enemy: %s at position (%d, %d)", 
            enemyDef.displayName, math.floor(spawnX), math.floor(spawnY)))
    end
    
    return enemy
end

-- Update the enemy spawner
function EnemySpawner:update(dt)
    -- Skip if not initialized or disabled
    if not self.initialized or not self.enabled then
        return
    end
    
    -- Update spawn timer
    self.timer = self.timer + dt
    
    -- Spawn enemy when timer exceeds interval
    if self.timer >= self.spawnInterval then
        self:spawnRandomEnemy()
        self.timer = self.timer - self.spawnInterval
    end
end

-- Toggle spawner enabled state
function EnemySpawner:setEnabled(enabled)
    self.enabled = enabled
end

-- Return the module
return EnemySpawner
