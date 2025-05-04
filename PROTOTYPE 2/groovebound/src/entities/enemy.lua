-- Enemy entity
-- Represents enemies that move toward the player and can be damaged/killed

local Settings = require("src/core/settings")

local Enemy = {}

-- Create a new enemy
-- @param x - Initial X position
-- @param y - Initial Y position
-- @param targetPlayer - Reference to the player entity (for movement)
-- @param arenaManager - Reference to the arena manager
-- @return A new enemy object
function Enemy.new(x, y, targetPlayer, arenaManager)
  -- Get enemy settings
  local enemySettings = Settings.enemies.basic
  
  -- Create enemy with settings-based properties
  local self = {
    x = x or 0,                -- X position
    y = y or 0,                -- Y position
    speed = enemySettings.speed,     -- Movement speed (pixels per second)
    hp = enemySettings.hp,           -- Health points
    damage = enemySettings.damage,   -- Damage dealt to player
    rectSize = enemySettings.size,   -- Enemy rectangle size
    xpValue = enemySettings.xp_value, -- XP value when killed
    targetPlayer = targetPlayer,     -- Reference to player for movement
    arenaManager = arenaManager,     -- Reference to arena manager
    isDead = false,                  -- Flag to track if enemy is dead
    fadeAlpha = 1.0,                 -- Fade alpha for death animation
    fadeSpeed = 3.0,                 -- Speed of fade out on death
    knockbackX = 0,                  -- X knockback velocity
    knockbackY = 0,                  -- Y knockback velocity
    knockbackResistance = 8          -- How quickly knockback diminishes
  }
  
  -- Set the metatable for the enemy object
  setmetatable(self, {__index = Enemy})
  
  return self
end

-- Update enemy position and state
-- @param dt - Delta time since last update
function Enemy:update(dt)
  -- Handle death state and fade out
  if self.isDead then
    -- Fade out animation
    self.fadeAlpha = math.max(0, self.fadeAlpha - dt * self.fadeSpeed)
    return
  end
  
  -- Apply knockback effect (if any)
  if self.knockbackX ~= 0 or self.knockbackY ~= 0 then
    -- Apply knockback to position
    self.x = self.x + self.knockbackX * dt
    self.y = self.y + self.knockbackY * dt
    
    -- Reduce knockback over time
    self.knockbackX = self.knockbackX * (1 - dt * self.knockbackResistance)
    self.knockbackY = self.knockbackY * (1 - dt * self.knockbackResistance)
    
    -- Stop tiny knockback values
    if math.abs(self.knockbackX) < 0.1 then self.knockbackX = 0 end
    if math.abs(self.knockbackY) < 0.1 then self.knockbackY = 0 end
  else
    -- Calculate direction to player
    local dx = self.targetPlayer.x - self.x
    local dy = self.targetPlayer.y - self.y
    
    -- Normalize direction vector
    local length = math.sqrt(dx * dx + dy * dy)
    if length > 0 then
      dx = dx / length
      dy = dy / length
    end
    
    -- Move toward player
    self.x = self.x + dx * self.speed * dt
    self.y = self.y + dy * self.speed * dt
  end
  
  -- Constrain to arena boundaries if arena manager is available
  if self.arenaManager then
    local padding = self.rectSize / 2
    self.x, self.y = self.arenaManager:constrain(self.x, self.y, padding + self.arenaManager.borderThickness)
  end
end

-- Draw the enemy
function Enemy:draw()
  -- Save current graphics state
  love.graphics.push("all")
  
  -- Skip rest of drawing if enemy is dead and fully faded out
  if self.isDead and self.fadeAlpha <= 0 then
    love.graphics.pop()
    return
  end
  
  -- Determine color based on state
  if self.isDead then
    -- Fading red color when dead
    love.graphics.setColor(0.8, 0.2, 0.2, self.fadeAlpha)
  else
    -- Normal red color
    love.graphics.setColor(0.8, 0.2, 0.2, 1)
  end
  
  -- Draw centered on enemy position
  local halfSize = self.rectSize / 2
  love.graphics.rectangle("fill", self.x - halfSize, self.y - halfSize, self.rectSize, self.rectSize)
  
  -- Draw health bar only if enemy is alive and damaged
  if not self.isDead and self.hp < Settings.enemies.basic.hp then
    local healthPct = math.max(0, self.hp / Settings.enemies.basic.hp)
    local barWidth = self.rectSize
    local barHeight = 3
    
    -- Background of health bar
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", 
      self.x - barWidth/2, 
      self.y - halfSize - barHeight - 2, 
      barWidth, 
      barHeight)
    
    -- Foreground of health bar (remaining health)
    love.graphics.setColor(0.1, 0.8, 0.1, 0.8)
    love.graphics.rectangle("fill", 
      self.x - barWidth/2, 
      self.y - halfSize - barHeight - 2, 
      barWidth * healthPct, 
      barHeight)
  end
  
  -- Restore graphics state
  love.graphics.pop()
end

-- Take damage and check if enemy dies
-- @param amount - Amount of damage to take
-- @param knockbackX - Optional X knockback force
-- @param knockbackY - Optional Y knockback force
-- @return true if the enemy died from this damage
function Enemy:takeDamage(amount, knockbackX, knockbackY)
  -- Skip if already dead
  if self.isDead then return false end
  
  -- Reduce HP by damage amount
  self.hp = self.hp - amount
  
  -- Apply knockback if provided
  if knockbackX and knockbackY then
    self.knockbackX = knockbackX
    self.knockbackY = knockbackY
  end
  
  -- Check if enemy died from this damage
  if self.hp <= 0 then
    -- Set dead flag
    self.isDead = true
    
    -- Emit event when enemy dies with position and XP value
    if EventBus then
      EventBus:emit("ENEMY_KILLED", {
        x = self.x, 
        y = self.y,
        xpValue = self.xpValue  -- Include XP value for gem creation
      })
    end
    
    -- Log enemy death if debug is available
    if Debug and Debug.log then
      Debug.log("ENEMY", "Enemy defeated at position (" .. math.floor(self.x) .. ", " .. math.floor(self.y) .. ")")
    end
    
    return true
  end
  
  return false
end

-- Check if this enemy should be removed from the game
-- @return boolean - True if enemy should be removed
function Enemy:shouldRemove()
  -- Remove if dead and fully faded out
  return self.isDead and self.fadeAlpha <= 0
end

-- Return the module
return Enemy
