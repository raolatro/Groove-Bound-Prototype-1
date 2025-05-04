-- Run state
-- Main gameplay state where the actual game run happens

-- Import required modules
local Player = require("src/entities/player")
local Enemy = require("src/entities/enemy")
local XPGem = require("src/entities/xp_gem")
local Spawner = require("src/systems/spawner")
local XPSystem = require("src/systems/xp_system")
local UpgradeManager = require("src/systems/upgrade_manager")
local LevelUpModal = require("src/ui/levelup_modal")
local Camera = require("src/core/camera")
local ArenaManager = require("src/systems/arena_manager")
local CollisionSystem = require("src/systems/collision_system")
local EnemySeparation = require("src/systems/enemy_separation")
local HUDInventory = require("src/ui/hud_inventory")
local Settings = require("src/core/settings")

local RunState = {
  paused = false,           -- Pause state flag
  gameTimer = 0,            -- Game time in seconds
  xpGems = {},              -- Active XP gems
  isLevelingUp = false,     -- Flag for level-up state
  arenaSize = {             -- Size of game arena
    width = Settings.arena.width,
    height = Settings.arena.height
  },
  enemyCollisionsEnabled = Settings.collision.enable_enemy_player, -- Whether enemies damage player on collision
  showHitboxes = Settings.collision.show_hitboxes                 -- Debug flag for showing collision hitboxes
}

-- Called when entering this state
function RunState:enter()
  -- Log state entry 
  if Debug and Debug.log then
    Debug.log("STATE", "Run state entered")
  end
  
  -- Initialize arena with boundaries
  self.arenaManager = ArenaManager:init()
  
  -- Initialize camera system
  self.camera = Camera:init()
  
  -- Initialize collision system
  self.collisionSystem = CollisionSystem:init()
  
  -- Initialize enemy separation system
  self.enemySeparation = EnemySeparation:init()
  
  -- Initialize player at the center of the arena
  local centerX, centerY = self.arenaManager:getCenter()
  self.player = Player.new(centerX, centerY, self.arenaManager)
  
  -- Set camera reference in player for proper aiming
  self.player.camera = self.camera
  
  -- Tell camera to follow player
  self.camera:setTarget(self.player.x, self.player.y)
  
  -- Reset game state
  self.paused = false
  self.gameTimer = 0
  self.xpGems = {}
  self.isLevelingUp = false
  
  -- Initialize spawner system with arena manager
  self.spawner = Spawner.new(self.player, self.arenaManager)
  
  -- Initialize XP system
  self.xpSystem = XPSystem.new()
  
  -- Initialize upgrade manager
  self.upgradeManager = UpgradeManager.new(self.player)
  
  -- Initialize inventory display for HUD
  self.inventoryHUD = HUDInventory.new(self.player)
  
  -- Register event listeners
  if EventBus then
    -- Listen for player death event
    EventBus:on("PLAYER_DIED", function()
      -- Brief delay before showing game over
      self:scheduleGameOver(0.5)
    end)
  end
  
  -- Register event handlers
  EventBus:on("ENEMY_KILLED", function(data)
    -- Create XP gem at enemy position
    local gem = XPGem.new(data.x, data.y, data.xp)
    table.insert(self.xpGems, gem)
    
    -- Log the event
    Debug.log("ENEMY", "Enemy killed at (" .. math.floor(data.x) .. ", " .. math.floor(data.y) .. ")")
  end)
  
  EventBus:on("PLAYER_LEVEL_UP", function(data)
    -- Log the level up
    Debug.log("LEVEL", "Player reached level " .. data.level)
    
    -- Pause the game
    self.paused = true
    self.isLevelingUp = true
    
    -- Create level-up modal with the player reference
    self.levelUpModal = LevelUpModal.new(self.player, function()
      -- On modal close
      self.isLevelingUp = false
      self.paused = false
    end)
  end)
  
  -- Pause menu buttons
  self.pauseButtons = {
    { label = "Resume", col = 11, row = 8, width = 10, height = 2 },
    { label = "Quit to Title", col = 11, row = 11, width = 10, height = 2 }
  }
  
  -- Add Dev Tuning button if debug is enabled
  -- This would be controlled by a debug flag in a complete implementation
  table.insert(self.pauseButtons, { label = "Dev Tuning", col = 11, row = 14, width = 10, height = 2 })
  
  -- Reset input state to avoid lingering inputs
  Input:reset()
end

-- Handle mouse press for UI interactions
-- @param x - Mouse X coordinate
-- @param y - Mouse Y coordinate
-- @param button - Mouse button that was pressed
function RunState:mousepressed(x, y, button)
  -- Check if we're in level-up modal
  if self.isLevelingUp and self.levelUpModal then
    self.levelUpModal:mousepressed(x, y, button)
    return
  end
  
  -- Only process UI clicks when paused
  if not self.paused or button ~= 1 then return end
  
  -- Check pause menu button clicks
  for _, btn in ipairs(self.pauseButtons) do
    if BlockGrid:isPointInGrid(x, y, btn.col, btn.row, btn.width, btn.height) then
      if btn.label == "Resume" then
        -- Resume the game (unpause)
        self:resume()
      elseif btn.label == "Quit to Title" then
        -- Return to title screen
        Debug.log("PAUSE", "Quit to title")
        local TitleState = require("src/ui/states/title")
        StateStack:pop() -- Remove run state
        StateStack:push(TitleState)
      elseif btn.label == "Dev Tuning" then
        -- Dev tuning would be implemented in a complete version
        Debug.log("PAUSE", "Dev tuning requested (not implemented)")
      end
      break
    end
  end
end

-- Handle key press events
-- @param key - The key that was pressed
function RunState:keypressed(key)
  -- If level-up modal is open, pass key to it
  if self.isLevelingUp and self.levelUpModal then
    self.levelUpModal:keypressed(key)
    return
  end
  
  -- Toggle pause when Escape is pressed
  if key == "escape" then
    self.paused = not self.paused
    if self.paused then
      Debug.log("PAUSE", "Game paused")
    else
      Debug.log("PAUSE", "Game resumed")
    end
  end
end

-- Update function
-- @param dt - Delta time since last update
function RunState:update(dt)
  -- Always update debug system to ensure messages are processed
  if Debug and Debug.update then
    Debug.update(dt)
  end
  
  -- Handle game over countdown if active
  if self.gameOverTimer then
    self.gameOverTimer = self.gameOverTimer - dt
    if self.gameOverTimer <= 0 then
      self:showGameOver()
      return
    end
  end
  
  -- Skip updates if paused or in level-up state
  if self.paused or self.isLevelingUp then return end
  
  -- Update game timer
  self.gameTimer = self.gameTimer + dt
  
  -- Update camera first (to track player movement)
  self.camera:update(dt)
  
  -- Update player
  self.player:update(dt)
  
  -- Set camera to follow player
  self.camera:setTarget(self.player.x, self.player.y)
  
  -- Update spawner system
  self.spawner:update(dt)
  
  -- Apply enemy separation to prevent overlapping
  local enemies = self.spawner:getEnemies()
  self.enemySeparation:update(enemies, dt)
  
  -- Update inventory HUD
  if self.inventoryHUD then
    self.inventoryHUD:update(dt)
  end
  
  -- Update XP gems
  for i = #self.xpGems, 1, -1 do
    local gem = self.xpGems[i]
    gem:update(dt, self.player)
    
    -- Check if gem was collected using collision system
    if self.collisionSystem:checkPlayerGemCollision(self.player, gem) then
      -- Mark as collected
      gem.isCollected = true
      
      -- Give XP to player
      self.xpSystem:addXP(gem.value)
      
      -- Log collection
      if Debug and Debug.log then
        Debug.log("XP", "Collected XP gem: +" .. gem.value .. " XP")
      end
    end
    
    -- Remove collected gems
    if gem.isCollected then
      table.remove(self.xpGems, i)
    end
  end
  
  -- Check for player leveling up
  if self.xpSystem:checkLevelUp() then
    -- Show level up modal
    self.isLevelingUp = true
    self.levelUpModal = LevelUpModal.new(self.upgradeManager:getAvailableUpgrades(3))
    
    -- Log the level up
    if Debug and Debug.log then
      Debug.log("XP", "Player reached level " .. self.xpSystem:getLevel())
    end
  end
  
  -- Handle player-enemy collisions
  if self.enemyCollisionsEnabled then
    local enemies = self.spawner:getEnemies()
    
    for _, enemy in ipairs(enemies) do
      -- Skip dead enemies
      if enemy.isDead then goto continue_enemy end
      
      -- Check collision between player and enemy
      if self.collisionSystem:checkPlayerEnemyCollision(self.player, enemy) then
        -- Calculate knockback direction (away from enemy)
        local dx = self.player.x - enemy.x
        local dy = self.player.y - enemy.y
        
        -- Normalize direction
        local length = math.sqrt(dx * dx + dy * dy)
        if length > 0 then
          dx = dx / length * Settings.collision.knockback_force
          dy = dy / length * Settings.collision.knockback_force
        end
        
        -- Handle collision with enemy
        self.collisionSystem:handlePlayerEnemyCollision(self.player, enemy, self.camera)
      end
      
      ::continue_enemy::
    end
  end
  
  -- Check bullet-enemy collisions
  if self.player.bullets and #self.player.bullets > 0 then
    local enemies = self.spawner:getEnemies()
    
    for _, bullet in ipairs(self.player.bullets) do
      for _, enemy in ipairs(enemies) do
        -- Skip dead enemies
        if enemy.isDead then goto continue_bullet end
        
        -- Check collision using collision system
        if self.collisionSystem:checkBulletEnemyCollision(bullet, enemy) then
          -- Calculate knockback direction (away from bullet)
          local knockbackX = enemy.x - bullet.x
          local knockbackY = enemy.y - bullet.y
          
          -- Normalize and scale knockback
          local length = math.sqrt(knockbackX * knockbackX + knockbackY * knockbackY)
          if length > 0 then
            knockbackX = knockbackX / length * 200 -- Knockback force
            knockbackY = knockbackY / length * 200
          end
          
          -- Apply damage with knockback
          local killed = enemy:takeDamage(bullet.damage, knockbackX, knockbackY)
          
          -- Mark bullet for removal
          bullet.remove = true
          
          -- Break once a collision is found for this bullet
          break
        end
        
        ::continue_bullet::
      end
    end
  end
end

-- Draw function
function RunState:draw()
  -- Clear the screen with a dark background
  love.graphics.clear(0.05, 0.05, 0.1, 1)
  
  -- Apply camera transformations - everything drawn after this will be affected by camera
  self.camera:apply()
  
  -- Draw arena boundaries first
  self.arenaManager:draw()
  
  -- Draw XP gems
  for _, gem in ipairs(self.xpGems) do
    gem:draw()
  end
  
  -- Draw enemies
  self.spawner:draw()
  
  -- Draw player (after enemies so player is on top)
  self.player:draw()
  
  -- Draw enemy separation debug visuals if enabled
  if self.showHitboxes and self.enemySeparation then
    self.enemySeparation:drawDebug(self.spawner:getEnemies())
  end
  
  -- Draw collision hitboxes if debug mode is enabled
  if self.showHitboxes then
    -- Get all collidable objects
    local collidables = {}
    
    -- Add player to collidables
    table.insert(collidables, self.player)
    
    -- Add all enemies
    for _, enemy in ipairs(self.spawner:getEnemies()) do
      table.insert(collidables, enemy)
    end
    
    -- Add all bullets
    for _, bullet in ipairs(self.player.bullets) do
      table.insert(collidables, bullet)
    end
    
    -- Draw hitboxes for all collidables
    self.collisionSystem:drawDebug(collidables)
  end
  
  -- Revert camera transformations before drawing UI
  self.camera:revert()
  
  -- Draw UI elements (not affected by camera)
  self:drawHUD()
  
  -- Draw inventory HUD
  if self.inventoryHUD then
    self.inventoryHUD:draw()
  end
  
  -- Draw level up modal if active
  if self.isLevelingUp and self.levelUpModal then
    self.levelUpModal:draw()
  end
  
  -- Draw pause menu if paused
  if self.paused and not self.isLevelingUp then
    self:drawPauseMenu()
  end
  
  -- Always draw debug overlay last so it's on top of everything
  if Debug and Debug.draw then
    Debug.draw()
  end
end

-- Draw the HUD (health bar, XP bar, timer)
function RunState:drawHUD()
  -- Save graphics state
  love.graphics.push("all")
  
  -- HP bar (top-left)
  local hpX, hpY, hpWidth, hpHeight = BlockGrid:grid(2, 1, 12, 1)
  
  -- HP bar background
  love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
  love.graphics.rectangle("fill", hpX, hpY, hpWidth, hpHeight)
  
  -- HP bar fill (red)
  local hpPercent = self.player.hp / self.player.maxHp
  love.graphics.setColor(0.8, 0.2, 0.2, 1)
  love.graphics.rectangle("fill", hpX, hpY, hpWidth * hpPercent, hpHeight)
  
  -- HP bar border
  love.graphics.setColor(0.7, 0.7, 0.7, 1)
  love.graphics.rectangle("line", hpX, hpY, hpWidth, hpHeight)
  
  -- HP text
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("HP: " .. math.floor(self.player.hp) .. "/" .. self.player.maxHp, 
    hpX + 5, hpY + hpHeight/4)
  
  -- XP bar (below HP bar)
  local xpX, xpY, xpWidth, xpHeight = BlockGrid:grid(2, 2, 12, 1)
  
  -- XP bar background
  love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
  love.graphics.rectangle("fill", xpX, xpY, xpWidth, xpHeight)
  
  -- XP bar fill (blue)
  local xpProgress = self.xpSystem:getLevelProgress()
  love.graphics.setColor(0.2, 0.4, 0.8, 1)
  love.graphics.rectangle("fill", xpX, xpY, xpWidth * xpProgress, xpHeight)
  
  -- XP bar border
  love.graphics.setColor(0.7, 0.7, 0.7, 1)
  love.graphics.rectangle("line", xpX, xpY, xpWidth, xpHeight)
  
  -- XP text
  love.graphics.setColor(1, 1, 1, 1)
  local currentXP = self.xpSystem:getXP()
  local nextThreshold = self.xpSystem:getNextLevelThreshold()
  love.graphics.print("XP: " .. currentXP .. "/" .. nextThreshold .. " (Level " .. self.xpSystem:getLevel() .. ")", 
    xpX + 5, xpY + xpHeight/4)
  
  -- Timer (top-right)
  local timerX, timerY, timerWidth, timerHeight = BlockGrid:grid(25, 1, 6, 1)
  love.graphics.setColor(1, 1, 1, 1)
  
  -- Format time as minutes:seconds
  local minutes = math.floor(self.gameTimer / 60)
  local seconds = math.floor(self.gameTimer % 60)
  local timeText = string.format("%02d:%02d", minutes, seconds)
  
  -- Draw timer background
  love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
  love.graphics.rectangle("fill", timerX, timerY, timerWidth, timerHeight)
  
  -- Draw timer border
  love.graphics.setColor(0.7, 0.7, 0.7, 1)
  love.graphics.rectangle("line", timerX, timerY, timerWidth, timerHeight)
  
  -- Draw timer text
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf(timeText, timerX, timerY + timerHeight/4, timerWidth, "center")
  
  -- Restore graphics state
  love.graphics.pop()
end

-- Draw the pause menu
function RunState:drawPauseMenu()
  -- Save graphics state
  love.graphics.push("all")
  
  -- Dim the screen with a semi-transparent overlay
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  
  -- Draw pause menu title
  love.graphics.setColor(1, 1, 1, 1)
  local titleX, titleY = BlockGrid:toPixels(15, 4)
  love.graphics.print("PAUSED", titleX, titleY)
  
  -- Draw buttons
  for _, btn in ipairs(self.pauseButtons) do
    -- Get button position and size
    local x, y, width, height = BlockGrid:grid(btn.col, btn.row, btn.width, btn.height)
    
    -- Draw button background
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Draw button border
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Draw button label
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(btn.label, x, y + height/3, width, "center")
  end
  
  -- Restore graphics state
  love.graphics.pop()
end

-- Check for bullet-enemy collisions
function RunState:checkBulletEnemyCollisions()
  local bullets = self.player:getBullets()
  local enemies = self.spawner:getEnemies()
  
  -- Loop through all bullets
  for _, bullet in ipairs(bullets) do
    -- Skip if bullet is already dead
    if not bullet:isDead() then
      -- Loop through all enemies
      for _, enemy in ipairs(enemies) do
        -- Skip if enemy is already dead
        if not enemy.isDead then
          -- Check for collision (simple box collision)
          local dx = bullet.x - enemy.x
          local dy = bullet.y - enemy.y
          local distance = math.sqrt(dx * dx + dy * dy)
          
          -- If distance is less than sum of half sizes, collision occurred
          if distance < (bullet.size / 2 + enemy.rectSize / 2) then
            -- Apply damage to enemy
            local killed = enemy:takeDamage(bullet.damage)
            
            -- Mark bullet as hit
            bullet:hit()
            
            -- Log the hit
            if killed then
              Debug.log("COMBAT", "Enemy killed by bullet")
            else
              Debug.log("COMBAT", "Enemy hit by bullet (" .. enemy.hp .. " HP left)")
            end
            
            -- Break inner loop since bullet can only hit one enemy
            break
          end
        end
      end
    end
  end
end

-- Schedule game over after a delay
-- @param delay - Time in seconds to wait before showing game over screen
function RunState:scheduleGameOver(delay)
  self.gameOverTimer = delay or 0.5
  
  -- Log game over scheduled
  if Debug and Debug.log then
    Debug.log("GAME", "Game over scheduled in " .. delay .. " seconds")
  end
end

-- Show game over screen
function RunState:showGameOver()
  -- Log game over
  if Debug and Debug.log then
    Debug.log("GAME", "Game over screen shown")
  end
  
  -- Push game over state onto the state stack
  StateStack:push(require("src/ui/states/game_over"))
end

-- Return the run state module
return RunState
