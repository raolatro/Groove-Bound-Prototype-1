-- Game Over state
-- Displayed when the player dies
local Settings = require("src/core/settings")

local GameOverState = {
  -- Timer for transitions
  timer = 0,
  fadeDuration = 0.5 -- Duration for fade effects
}

-- Called when entering this state
function GameOverState:enter()
  -- Log state entry
  if Debug and Debug.log then
    Debug.log("STATE", "Game over state entered")
  end
  
  -- Reset timer
  self.timer = 0
  
  -- Play game over sound if available
  -- if Sound and Sound.play then
  --   Sound.play("game_over")
  -- end
end

-- Update function
-- @param dt - Delta time since last update
function GameOverState:update(dt)
  -- Update timer
  self.timer = self.timer + dt
  
  -- Check for input after a short delay to prevent accidental clicks
  if self.timer >= 0.5 then
    -- Using proper love.keyboard.isDown instead of isPressed
    if love.keyboard.isDown("space") or love.keyboard.isDown("return") then
      self:restart()
    end
    
    -- Using proper love.mouse.isDown instead of isPressed
    if love.mouse.isDown(1) then
      self:restart()
    end
  end
  
  -- Always update debug system
  if Debug and Debug.update then
    Debug.update(dt)
  end
end

-- Draw the game over screen
function GameOverState:draw()
  -- Get screen dimensions
  local width, height = love.graphics.getDimensions()
  
  -- Calculate fade alpha (fade in effect)
  local alpha = math.min(1, self.timer / self.fadeDuration)
  
  -- Draw semi-transparent black overlay
  love.graphics.setColor(0, 0, 0, 0.7 * alpha)
  love.graphics.rectangle("fill", 0, 0, width, height)
  
  -- Save current state
  love.graphics.push("all")
  
  -- Draw centered game over text
  love.graphics.setColor(1, 0.2, 0.2, alpha)
  love.graphics.setFont(love.graphics.newFont(48))
  love.graphics.printf("GAME OVER", 0, height / 3, width, "center")
  
  -- Draw score/stats if available
  -- TODO: Add score display
  
  -- Draw restart prompt
  love.graphics.setColor(1, 1, 1, alpha * math.sin(self.timer * 2) * 0.3 + 0.7)
  love.graphics.setFont(love.graphics.newFont(24))
  love.graphics.printf("Click or press SPACE to restart", 0, height * 2/3, width, "center")
  
  -- Draw return to menu prompt
  love.graphics.setColor(0.8, 0.8, 0.8, alpha * 0.8)
  love.graphics.setFont(love.graphics.newFont(18))
  love.graphics.printf("Press ESC to return to title", 0, height * 2/3 + 40, width, "center")
  
  -- Restore graphics state
  love.graphics.pop()
end

-- Handle key press events
-- @param key - The key that was pressed
function GameOverState:keypressed(key)
  if key == "escape" then
    self:returnToTitle()
  elseif key == "space" or key == "return" then
    self:restart()
  end
end

-- Handle mouse press events
-- @param x - Mouse X coordinate
-- @param y - Mouse Y coordinate
-- @param button - Mouse button that was pressed
function GameOverState:mousepressed(x, y, button)
  if button == 1 and self.timer >= 0.5 then
    self:restart()
  end
end

-- Restart the game
function GameOverState:restart()
  -- Log restart
  if Debug and Debug.log then
    Debug.log("GAME", "Restarting from game over")
  end
  
  -- Reset state stack and transition to run state
  StateStack:popAll()
  StateStack:push(require("src/ui/states/run"))
end

-- Return to title screen
function GameOverState:returnToTitle()
  -- Log return to title
  if Debug and Debug.log then
    Debug.log("GAME", "Returning to title from game over")
  end
  
  -- Reset state stack and transition to title state
  StateStack:popAll()
  StateStack:push(require("src/ui/states/title"))
end

-- Return the game over state
return GameOverState
