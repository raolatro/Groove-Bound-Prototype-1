-- Camera module for Groove Bound
-- Provides smooth following and screen shake functionality

local UI = require("config.ui")
local Config = require("config.settings")

-- Get global Debug instance
local Debug = _G.Debug

-- Shorthand for readability
local DEV = Config.DEV

-- Camera module
local Camera = {}
Camera.__index = Camera

-- Create a new camera
function Camera:new(worldWidth, worldHeight)
    local instance = {
        x = 0,
        y = 0,
        targetX = 0,
        targetY = 0,
        scaleX = 1,
        scaleY = 1,
        rotation = 0,
        worldWidth = worldWidth or UI.ARENA.w,
        worldHeight = worldHeight or UI.ARENA.h,
        
        -- Screen dimensions 
        viewportWidth = love.graphics.getWidth(),
        viewportHeight = love.graphics.getHeight(),
        
        -- Camera settings
        lag = UI.CAMERA.lag,
        
        -- Shake properties
        shakeIntensity = 0,
        shakeDuration = 0,
        shakeX = 0,
        shakeY = 0
    }
    
    return setmetatable(instance, self)
end

-- Update camera position with smooth following
function Camera:update(dt, targetX, targetY)
    -- Save target position
    self.targetX = targetX or self.targetX
    self.targetY = targetY or self.targetY
    
    -- Calculate center of screen position
    local tx = self.targetX - self.viewportWidth / 2
    local ty = self.targetY - self.viewportHeight / 2
    
    -- Apply exponential lerp smoothing with lag factor
    -- (lag 0.15 = take 15% of the way there each frame)
    local lag = UI.CAMERA.lag
    self.x = self.x + (tx - self.x) * lag
    self.y = self.y + (ty - self.y) * lag
    
    -- Debug print camera target position (once per second)
    if DEV.DEBUG_CAMERA and DEV.DEBUG_MASTER then
        self.debugTimer = (self.debugTimer or 0) - dt
        if self.debugTimer <= 0 then
            self.debugTimer = 1 -- Reset to 1 second
            -- Debug.log("Camera target " .. self.targetX .. "," .. self.targetY)
        end
    end
    
    self:clampPosition()
    
    -- Update screen shake
    if self.shakeDuration > 0 then
        self.shakeDuration = self.shakeDuration - dt
        if self.shakeDuration <= 0 then
            -- Reset shake when duration is over
            self.shakeX = 0
            self.shakeY = 0
            self.shakeIntensity = 0
        else
            -- Random shake offset
            self.shakeX = love.math.random(-self.shakeIntensity, self.shakeIntensity)
            self.shakeY = love.math.random(-self.shakeIntensity, self.shakeIntensity)
        end
    end
end

-- Clamp camera position to keep world in view
function Camera:clampPosition()
    local halfWidth = self.viewportWidth / (2 * self.scaleX)
    local halfHeight = self.viewportHeight / (2 * self.scaleY)
    
    -- Calculate bounds
    local minX = halfWidth
    local maxX = self.worldWidth - halfWidth
    local minY = halfHeight
    local maxY = self.worldHeight - halfHeight
    
    -- Adjust bounds if the world is smaller than the viewport
    if self.worldWidth < self.viewportWidth / self.scaleX then
        self.x = self.worldWidth / 2
    else
        self.x = math.max(minX, math.min(self.x, maxX))
    end
    
    if self.worldHeight < self.viewportHeight / self.scaleY then
        self.y = self.worldHeight / 2
    else
        self.y = math.max(minY, math.min(self.y, maxY))
    end
end

-- Update screen shake effect
function Camera:updateShake(dt)
    -- Removed, now handled in Camera:update
end

-- Start a screen shake effect
function Camera:shake(intensity, duration)
    self.shakeIntensity = intensity
    self.shakeDuration = duration
end

-- Set zoom level
function Camera:setZoom(zoom)
    self.scaleX = zoom
    self.scaleY = zoom
end

-- Attach camera transformation (push)
function Camera:attach()
    love.graphics.push()
    
    -- Apply camera transform: translate to camera position
    love.graphics.translate(-self.x, -self.y)
    
    -- Apply screen shake if active
    if self.shakeDuration > 0 then
        love.graphics.translate(self.shakeX, self.shakeY)
    end
    
    -- Apply additional transformations
    love.graphics.scale(self.scaleX, self.scaleY)
    love.graphics.rotate(self.rotation)
end

-- Detach camera transformation (pop)
function Camera:detach()
    love.graphics.pop()
end

-- Convert screen coordinates to world coordinates
function Camera:screenToWorld(screenX, screenY)
    local x, y = screenX, screenY
    
    -- Apply inverse transformations in reverse order
    x = x - self.viewportWidth / 2
    y = y - self.viewportHeight / 2
    
    x = x / self.scaleX
    y = y / self.scaleY
    
    -- Apply inverse rotation
    if self.rotation ~= 0 then
        local cosRot = math.cos(-self.rotation)
        local sinRot = math.sin(-self.rotation)
        local tempX = x * cosRot - y * sinRot
        local tempY = x * sinRot + y * cosRot
        x, y = tempX, tempY
    end
    
    x = x + self.x
    y = y + self.y
    
    return x, y
end

-- Convert world coordinates to screen coordinates
function Camera:worldToScreen(worldX, worldY)
    local x, y = worldX - self.x, worldY - self.y
    
    -- Apply rotation
    if self.rotation ~= 0 then
        local cosRot = math.cos(self.rotation)
        local sinRot = math.sin(self.rotation)
        local tempX = x * cosRot - y * sinRot
        local tempY = x * sinRot + y * cosRot
        x, y = tempX, tempY
    end
    
    -- Apply translation
    x = x + self.viewportWidth / 2
    y = y + self.viewportHeight / 2
    
    return x, y
end

-- Convert screen coordinates to world coordinates
function Camera:screenToWorld(screenX, screenY)
    local x, y = screenX, screenY
    
    -- Remove screen center offset
    x = x - self.viewportWidth / 2
    y = y - self.viewportHeight / 2
    
    -- Apply rotation (inverse)
    if self.rotation ~= 0 then
        local cosRot = math.cos(-self.rotation)
        local sinRot = math.sin(-self.rotation)
        local tempX = x * cosRot - y * sinRot
        local tempY = x * sinRot + y * cosRot
        x, y = tempX, tempY
    end
    
    -- Apply translation
    x = x + self.x
    y = y + self.y
    
    return x, y
end

-- Handle key press
function Camera:keypressed(key)
    -- No toggles needed - debug is always on in prototype phase
end

return Camera
