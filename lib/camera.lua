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
        forceReset = false, -- Flag to force camera to snap to target
        
        -- Transition animation properties
        isTransitioning = false,
        transitionStartX = 0,
        transitionStartY = 0,
        transitionTargetX = 0,
        transitionTargetY = 0,
        transitionDuration = 1.0, -- 1 second transition
        transitionTimer = 0,
        transitionComplete = false,
        
        -- Shake properties
        shakeIntensity = 0,
        shakeDuration = 0,
        shakeX = 0,
        shakeY = 0
    }
    
    return setmetatable(instance, self)
end

-- Start a camera transition animation to a new target position
function Camera:startTransition(targetX, targetY, duration)
    -- Set transition properties
    self.isTransitioning = true
    self.transitionStartX = self.x
    self.transitionStartY = self.y
    
    -- Calculate target camera position (centered on target)
    self.transitionTargetX = targetX - self.viewportWidth / 2
    self.transitionTargetY = targetY - self.viewportHeight / 2
    
    -- Set duration and reset timer
    self.transitionDuration = duration or 1.0
    self.transitionTimer = 0
    self.transitionComplete = false
    
    -- Store final target for regular camera following after transition
    self.targetX = targetX
    self.targetY = targetY
    
    -- Debug output
    if DEV.DEBUG_MASTER then
        print("Starting camera transition to: " .. targetX .. "," .. targetY .. " over " .. self.transitionDuration .. " seconds")
    end
    
    return self
end

-- Update camera position with smooth following
function Camera:update(dt, targetX, targetY)
    -- If not transitioning, handle normal camera following
    if not self.isTransitioning then
        -- Save target position
        self.targetX = targetX or self.targetX
        self.targetY = targetY or self.targetY
        
        -- Calculate center of screen position
        local tx = self.targetX - self.viewportWidth / 2
        local ty = self.targetY - self.viewportHeight / 2
        
        -- Apply exponential lerp smoothing with lag factor
        local lag = UI.CAMERA.lag
        self.x = self.x + (tx - self.x) * lag
        self.y = self.y + (ty - self.y) * lag
    else
        -- Handle transition animation
        self.transitionTimer = self.transitionTimer + dt
        
        if self.transitionTimer >= self.transitionDuration then
            -- Transition complete - snap to final position
            self.x = self.transitionTargetX
            self.y = self.transitionTargetY
            self.isTransitioning = false
            self.transitionComplete = true
            
            -- Debug output
            if DEV.DEBUG_MASTER then
                print("Camera transition complete")
            end
        else
            -- Calculate transition progress (0 to 1)
            local progress = self.transitionTimer / self.transitionDuration
            
            -- Use a smooth ease-in-out function
            progress = self:easeInOutCubic(progress)
            
            -- Interpolate between start and target positions
            self.x = self.transitionStartX + (self.transitionTargetX - self.transitionStartX) * progress
            self.y = self.transitionStartY + (self.transitionTargetY - self.transitionStartY) * progress
        end
    end
    
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

-- Cubic ease-in-out function for smooth animation
function Camera:easeInOutCubic(x)
    if x < 0.5 then
        return 4 * x * x * x
    else
        return 1 - math.pow(-2 * x + 2, 3) / 2
    end
end

-- Reset camera position with immediate or animated transition
function Camera:resetPosition(targetX, targetY, animated, duration)
    -- Save target position
    self.targetX = targetX or self.targetX
    self.targetY = targetY or self.targetY
    
    -- Clear any shaking effects
    self.shakeX = 0
    self.shakeY = 0
    self.shakeIntensity = 0
    self.shakeDuration = 0
    
    -- If animated transition is requested
    if animated then
        -- Start a smooth transition animation
        self:startTransition(self.targetX, self.targetY, duration or 1.0)
        
        -- Debug output
        if DEV.DEBUG_MASTER then
            print("Camera starting ANIMATED transition to: " .. self.targetX .. "," .. self.targetY)
        end
    else
        -- Calculate center position (where camera should be)
        local tx = self.targetX - self.viewportWidth / 2
        local ty = self.targetY - self.viewportHeight / 2
        
        -- Immediately set position (no smoothing)
        self.x = tx
        self.y = ty
        
        -- Cancel any ongoing transition
        self.isTransitioning = false
        
        -- Set force reset flag for next frame's rendering
        self.forceReset = true
        
        -- Debug output
        if DEV.DEBUG_MASTER then
            print("Camera position HARD RESET to: " .. self.targetX .. "," .. self.targetY)
        end
    end
    
    -- Make sure we're still in bounds
    self:clampPosition()
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

-- Attach camera transformation (for drawing world objects)
function Camera:attach()
    -- Push graphics state
    love.graphics.push()
    
    -- Check if we need to force a camera snap
    if self.forceReset then
        -- Force camera to exactly match target with no smoothing or shake
        local tx = self.targetX - self.viewportWidth / 2
        local ty = self.targetY - self.viewportHeight / 2
        
        -- Directly set camera position
        self.x = tx
        self.y = ty
        
        -- Clear any shake effects
        self.shakeX = 0
        self.shakeY = 0
        self.shakeIntensity = 0
        self.shakeDuration = 0
        
        -- Log the forced reset
        if DEV.DEBUG_MASTER then
            print("FORCED camera position: " .. self.targetX .. "," .. self.targetY)
        end
        
        -- Turn off the flag
        self.forceReset = false
    end
    
    -- Apply camera transformation
    love.graphics.translate(
        -self.x + self.shakeX, 
        -self.y + self.shakeY
    )
    
    -- Apply camera zoom
    love.graphics.scale(self.scaleX, self.scaleY)
    
    -- Apply rotation if needed
    if self.rotation ~= 0 then
        love.graphics.rotate(self.rotation)
    end
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
