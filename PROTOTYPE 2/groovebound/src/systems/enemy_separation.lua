-- Enemy Separation System
-- Prevents enemies from overlapping with each other

local EnemySeparation = {}

-- Initialize the enemy separation system
-- @return The enemy separation system object
function EnemySeparation:init()
  -- Log initialization
  if Debug and Debug.log then
    Debug.log("SYSTEM", "Enemy separation system initialized")
  end
  
  -- Return self for chaining
  return self
end

-- Apply separation forces to prevent enemies from overlapping
-- @param enemies - Array of enemy entities
-- @param dt - Delta time for physics calculations
function EnemySeparation:update(enemies, dt)
  -- Skip if no enemies or just one enemy
  if not enemies or #enemies < 2 then
    return
  end
  
  -- The minimum distance between enemy centers (sum of their radii plus a small buffer)
  local minDistance = 64 -- Can be tuned based on enemy sizes
  
  -- Loop through all pairs of enemies
  for i = 1, #enemies do
    local enemy1 = enemies[i]
    
    -- Skip dead enemies
    if enemy1.isDead then goto continue_outer end
    
    for j = i+1, #enemies do
      local enemy2 = enemies[j]
      
      -- Skip dead enemies
      if enemy2.isDead then goto continue_inner end
      
      -- Calculate distance between enemies
      local dx = enemy2.x - enemy1.x
      local dy = enemy2.y - enemy1.y
      local distSquared = dx*dx + dy*dy
      
      -- Skip if already far enough apart
      if distSquared >= minDistance*minDistance then
        goto continue_inner
      end
      
      -- Calculate actual distance
      local distance = math.sqrt(distSquared)
      
      -- Calculate overlap
      local overlap = minDistance - distance
      
      -- Normalize direction vector
      if distance > 0 then
        dx = dx / distance
        dy = dy / distance
      else
        -- If they're exactly at the same position, use a random direction
        local angle = math.random() * math.pi * 2
        dx = math.cos(angle)
        dy = math.sin(angle)
      end
      
      -- Calculate separation force (half for each enemy)
      local moveX = dx * overlap * 0.5
      local moveY = dy * overlap * 0.5
      
      -- Apply movement (push enemies apart)
      enemy1.x = enemy1.x - moveX
      enemy1.y = enemy1.y - moveY
      enemy2.x = enemy2.x + moveX
      enemy2.y = enemy2.y + moveY
      
      ::continue_inner::
    end
    
    ::continue_outer::
  end
end

-- Debug draw function to visualize separation
-- @param enemies - Array of enemy entities
function EnemySeparation:drawDebug(enemies)
  -- Skip if debug display is not enabled
  if not (Settings and Settings.debug_display and Settings.debug_display.enabled) then
    return
  end
  
  -- Save current graphics state
  love.graphics.push("all")
  
  -- Draw separation radius for each enemy
  love.graphics.setColor(0, 1, 0, 0.2)
  for _, enemy in ipairs(enemies) do
    if not enemy.isDead then
      love.graphics.circle("line", enemy.x, enemy.y, 32)
    end
  end
  
  -- Restore graphics state
  love.graphics.pop()
end

-- Return the enemy separation module
return EnemySeparation
