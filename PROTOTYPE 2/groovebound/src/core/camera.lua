-- Camera module
-- Manages camera position, movement and effects
-- Centers on player and provides shake effects

local Settings = require("src/core/settings")

-- Create camera object
local Camera = {
  x = 0,                -- X position of camera
  y = 0,                -- Y position of camera
  scale = 1,            -- Zoom level
  rotation = 0,         -- Rotation in radians
  shakeTime = 0,        -- Current shake timer
  shakeDuration = 0,    -- Total shake duration
  shakeIntensity = 0,   -- Shake intensity
  targetX = 0,          -- Target X position to follow
  targetY = 0           -- Target Y position to follow
}

-- Initialize the camera
-- @return The camera object for chaining
function Camera:init()
  -- Reset camera position and effects
  self.x = 0
  self.y = 0
  self.scale = 1
  self.rotation = 0
  self.shakeTime = 0
  self.shakeDuration = 0
  self.shakeIntensity = 0
  
  -- Log initialization if logging is available
  if _G.SafeLog then
    SafeLog("SYSTEM", "Camera system initialized")
  elseif Logger and Logger.info then
    Logger:info("Camera system initialized")
  else
    print("Camera system initialized")
  end
  
  return self
end

-- Set camera to follow a target (usually the player)
-- @param x - X position to follow
-- @param y - Y position to follow
function Camera:setTarget(x, y)
  self.targetX = x
  self.targetY = y
end

-- Update the camera position and effects
-- @param dt - Delta time in seconds
function Camera:update(dt)
  -- Get camera settings
  local lerpSpeed = Settings.camera.lerp_speed
  
  -- Smoothly move camera toward target
  if self.targetX and self.targetY then
    self.x = self.x + (self.targetX - self.x) * math.min(1, dt * lerpSpeed)
    self.y = self.y + (self.targetY - self.y) * math.min(1, dt * lerpSpeed)
  end
  
  -- Update camera shake if active
  if self.shakeTime > 0 then
    self.shakeTime = self.shakeTime - dt
    -- End shake if time is up
    if self.shakeTime <= 0 then
      self.shakeTime = 0
      self.shakeIntensity = 0
    end
  end
end

-- Start a camera shake effect
-- @param duration - Duration of shake in seconds
-- @param intensity - Intensity of shake (1.0 = strong)
function Camera:shake(duration, intensity)
  self.shakeTime = duration or Settings.camera.shake_duration
  self.shakeDuration = self.shakeTime
  self.shakeIntensity = intensity or Settings.camera.shake_intensity
end

-- Apply camera transformations for rendering
-- This should be called at the start of the draw function
function Camera:apply()
  local width, height = love.graphics.getDimensions()
  
  -- Save current transform
  love.graphics.push()
  
  -- Center the camera in the window
  love.graphics.translate(width/2, height/2)
  
  -- Apply camera scale/zoom
  love.graphics.scale(self.scale, self.scale)
  
  -- Apply camera rotation
  love.graphics.rotate(self.rotation)
  
  -- Apply camera shake
  local shakeMagnitude = 0
  if self.shakeTime > 0 then
    -- Calculate shake magnitude based on remaining time
    local shakeProgress = self.shakeTime / self.shakeDuration
    shakeMagnitude = self.shakeIntensity * 10 * shakeProgress
    
    -- Apply random offset for shake
    love.graphics.translate(
      math.random(-shakeMagnitude, shakeMagnitude),
      math.random(-shakeMagnitude, shakeMagnitude)
    )
  end
  
  -- Translate to camera position (negative because we move the world, not the camera)
  love.graphics.translate(-self.x, -self.y)
end

-- Revert camera transformations
-- This should be called at the end of the draw function
function Camera:revert()
  love.graphics.pop()
end

-- Convert screen coordinates to world coordinates
-- @param screenX - X coordinate on screen
-- @param screenY - Y coordinate on screen
-- @return worldX, worldY - Equivalent world coordinates
function Camera:screenToWorld(screenX, screenY)
  local width, height = love.graphics.getDimensions()
  local centerX, centerY = width/2, height/2
  
  -- Reverse the transformations applied in apply()
  local worldX = (screenX - centerX) / self.scale + self.x
  local worldY = (screenY - centerY) / self.scale + self.y
  
  return worldX, worldY
end

-- Convert world coordinates to screen coordinates
-- @param worldX - X coordinate in world space
-- @param worldY - Y coordinate in world space
-- @return screenX, screenY - Equivalent screen coordinates
function Camera:worldToScreen(worldX, worldY)
  local width, height = love.graphics.getDimensions()
  local centerX, centerY = width/2, height/2
  
  -- Apply the transformations from apply()
  local screenX = centerX + (worldX - self.x) * self.scale
  local screenY = centerY + (worldY - self.y) * self.scale
  
  return screenX, screenY
end

-- Return the module
return Camera
