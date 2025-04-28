-- Player module for Groove Bound
-- Handles player creation, movement, animation, and input

local L = require("lib.loader")
local Config = require("config.settings")
local PATHS = require("config.paths")

-- Shorthand for readability
local TUNING = Config.TUNING.PLAYER
local CONTROLS = Config.CONTROLS
local DEV = Config.DEV

-- Local debug flag, ANDed with master debug
local DEBUG_PLAYER = false

-- Player metatable
local Player = {}
Player.__index = Player

-- Constructor
function Player:new(x, y)
    -- Create instance
    local instance = {
        -- Position and physics
        x = x or 0,
        y = y or 0,
        vx = 0,
        vy = 0,
        speed = TUNING.MOVE_SPEED,
        -- Dimensions
        width = TUNING.SPRITE_SIZE,
        height = TUNING.SPRITE_SIZE,
        hitboxRadius = TUNING.HITBOX_RADIUS,
        -- State
        isMoving = false,
        direction = 1, -- 1 = right, -1 = left
        -- Combat
        fireTimer = 0,
        fireCooldown = TUNING.FIRE_COOLDOWN,
        -- Aim direction (normalized vector)
        aimX = 1,
        aimY = 0,
        -- Input state
        input = {
            up = false,
            down = false,
            left = false,
            right = false,
            fire = false
        },
        -- Gamepad reference if available
        gamepad = nil
    }
    
    -- Load sprite sheet
    instance.spriteSheet = love.graphics.newImage(PATHS.ASSETS.SPRITES.PLAYER)
    
    -- Get actual dimensions of the sprite sheet
    local sheetWidth = instance.spriteSheet:getWidth()
    local sheetHeight = instance.spriteSheet:getHeight()
    
    -- Calculate frame size based on expected frames
    -- Expecting 4 frames horizontally in the sheet
    local frameWidth = sheetWidth / 4
    local frameHeight = sheetHeight
    
    -- Setup animation with anim8
    local g = L.Anim8.newGrid(
        frameWidth, 
        frameHeight,
        sheetWidth,
        sheetHeight
    )
    
    if DEBUG_PLAYER and DEV.DEBUG_MASTER then
        print(string.format("Sprite sheet dimensions: %dx%d", sheetWidth, sheetHeight))
        print(string.format("Frame dimensions: %dx%d", frameWidth, frameHeight))
    end
    
    instance.animations = {
        walk = L.Anim8.newAnimation(g('1-4', 1), 0.15) -- 4 frames, 0.15s per frame
    }
    
    instance.currentAnimation = instance.animations.walk
    
    -- Return the instance with the Player metatable
    return setmetatable(instance, self)
end

-- Check for gamepad and set it as active if found
function Player:checkGamepad()
    local joysticks = love.joystick.getJoysticks()
    self.gamepad = joysticks[1] -- Use first gamepad if available
    
    if self.gamepad and DEBUG_PLAYER and DEV.DEBUG_MASTER then
        print("Gamepad connected: " .. self.gamepad:getName())
    end
end

-- Process keyboard input
function Player:processKeyboardInput()
    -- Movement keys
    self.input.up = love.keyboard.isDown(CONTROLS.KEYBOARD.MOVE.UP)
    self.input.down = love.keyboard.isDown(CONTROLS.KEYBOARD.MOVE.DOWN)
    self.input.left = love.keyboard.isDown(CONTROLS.KEYBOARD.MOVE.LEFT)
    self.input.right = love.keyboard.isDown(CONTROLS.KEYBOARD.MOVE.RIGHT)
    
    -- Fire input
    self.input.fire = love.keyboard.isDown(CONTROLS.KEYBOARD.FIRE)
    
    -- Mouse aiming when using keyboard
    local mouseX, mouseY = love.mouse.getPosition()
    self:updateAimFromPoint(mouseX, mouseY)
end

-- Process gamepad input
function Player:processGamepadInput()
    if not self.gamepad then return end
    
    -- Get left stick for movement
    local leftX = self.gamepad:getGamepadAxis(CONTROLS.GAMEPAD.MOVE_AXIS.HORIZONTAL)
    local leftY = self.gamepad:getGamepadAxis(CONTROLS.GAMEPAD.MOVE_AXIS.VERTICAL)
    
    -- Apply deadzone
    if math.abs(leftX) < CONTROLS.DEADZONE then leftX = 0 end
    if math.abs(leftY) < CONTROLS.DEADZONE then leftY = 0 end
    
    -- Set input flags based on analog values
    self.input.left = leftX < -CONTROLS.DEADZONE
    self.input.right = leftX > CONTROLS.DEADZONE
    self.input.up = leftY < -CONTROLS.DEADZONE
    self.input.down = leftY > CONTROLS.DEADZONE
    
    -- Get right stick for aiming
    local rightX = self.gamepad:getGamepadAxis(CONTROLS.GAMEPAD.AIM_AXIS.HORIZONTAL)
    local rightY = self.gamepad:getGamepadAxis(CONTROLS.GAMEPAD.AIM_AXIS.VERTICAL)
    
    -- If right stick is being used (outside deadzone), update aim direction
    if math.abs(rightX) > CONTROLS.DEADZONE or math.abs(rightY) > CONTROLS.DEADZONE then
        self:normalizeAim(rightX, rightY)
    end
    
    -- Fire button
    self.input.fire = self.gamepad:isGamepadDown(CONTROLS.GAMEPAD.FIRE)
end

-- Update aim direction from a point (used for mouse aiming)
function Player:updateAimFromPoint(pointX, pointY)
    -- Calculate vector from player to point
    local dx = pointX - self.x
    local dy = pointY - self.y
    
    -- Normalize the vector
    self:normalizeAim(dx, dy)
end

-- Normalize aim vector
function Player:normalizeAim(x, y)
    local length = math.sqrt(x * x + y * y)
    
    if length > 0 then
        self.aimX = x / length
        self.aimY = y / length
        
        -- Update facing direction based on aim
        if self.aimX < 0 then
            self.direction = -1
        else
            self.direction = 1
        end
    end
end

-- Update fire cooldown timer
function Player:updateFiring(dt)
    if self.fireTimer > 0 then
        self.fireTimer = math.max(0, self.fireTimer - dt)
    end
    
    -- Check if firing and cooldown is ready
    if self.input.fire and self.fireTimer <= 0 then
        self:fire()
        self.fireTimer = self.fireCooldown
    end
end

-- Fire weapon (placeholder)
function Player:fire()
    if DEBUG_PLAYER and DEV.DEBUG_MASTER then
        print("Player fired in direction: " .. self.aimX .. ", " .. self.aimY)
    end
    
    -- TODO: Implement actual weapon firing mechanics
    -- This is where projectile creation would happen
end

-- Update movement based on input
function Player:updateMovement(dt)
    -- Calculate input direction
    local inputX, inputY = 0, 0
    
    if self.input.left then inputX = inputX - 1 end
    if self.input.right then inputX = inputX + 1 end
    if self.input.up then inputY = inputY - 1 end
    if self.input.down then inputY = inputY + 1 end
    
    -- Normalize diagonal movement
    if inputX ~= 0 and inputY ~= 0 then
        local length = math.sqrt(2)
        inputX = inputX / length
        inputY = inputY / length
    end
    
    -- Apply acceleration
    local targetVx = inputX * self.speed
    local targetVy = inputY * self.speed
    
    -- Smooth acceleration towards target velocity
    self.vx = self.vx + (targetVx - self.vx) * math.min(dt * TUNING.ACCELERATION / self.speed, 1)
    self.vy = self.vy + (targetVy - self.vy) * math.min(dt * TUNING.ACCELERATION / self.speed, 1)
    
    -- Apply friction when no input
    if inputX == 0 then
        self.vx = self.vx * math.pow(0.01, dt * TUNING.FRICTION)
    end
    if inputY == 0 then
        self.vy = self.vy * math.pow(0.01, dt * TUNING.FRICTION)
    end
    
    -- Update position
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    
    -- Update movement state
    self.isMoving = math.abs(self.vx) > 1 or math.abs(self.vy) > 1
end

-- Update animation
function Player:updateAnimation(dt)
    if self.isMoving then
        self.currentAnimation:update(dt)
    else
        -- Reset to first frame when not moving
        self.currentAnimation:gotoFrame(1)
    end
end

-- Main update function
function Player:update(dt)
    -- Check for gamepad if none is set
    if not self.gamepad then
        self:checkGamepad()
    end
    
    -- Process input based on available devices
    if self.gamepad then
        self:processGamepadInput()
    else
        self:processKeyboardInput()
    end
    
    -- Update movement and animation
    self:updateMovement(dt)
    self:updateAnimation(dt)
    self:updateFiring(dt)
end

-- Draw the player
function Player:draw()
    -- Draw current animation with appropriate flipping
    local scaleX = self.direction
    local offsetX = self.direction < 0 and self.width or 0
    
    love.graphics.setColor(1, 1, 1)
    self.currentAnimation:draw(
        self.spriteSheet, 
        self.x, 
        self.y, 
        0,                   -- rotation
        scaleX, 1,           -- scale
        offsetX,             -- offset X
        self.height / 2      -- offset Y
    )
    
    -- Debug visualization
    if DEBUG_PLAYER and DEV.DEBUG_MASTER then
        self:drawDebug()
    end
end

-- Draw debug visuals
function Player:drawDebug()
    -- Draw hit box
    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.circle("line", self.x, self.y, self.hitboxRadius)
    
    -- Draw aim direction
    love.graphics.setColor(0, 1, 0, 0.8)
    love.graphics.line(
        self.x, 
        self.y, 
        self.x + self.aimX * 30, 
        self.y + self.aimY * 30
    )
    
    -- Draw velocity vector
    love.graphics.setColor(0, 0, 1, 0.8)
    love.graphics.line(
        self.x,
        self.y,
        self.x + self.vx * 0.1,
        self.y + self.vy * 0.1
    )
    
    -- Draw status text
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format(
        "Pos: %.1f, %.1f\nVel: %.1f, %.1f\nAim: %.2f, %.2f",
        self.x, self.y,
        self.vx, self.vy,
        self.aimX, self.aimY
    ), self.x + 20, self.y - 40)
end

-- Handle key press
function Player:keypressed(key)
    -- Toggle player debug (requires master debug to be on)
    if key == CONTROLS.KEYBOARD.DEBUG.TOGGLE_PLAYER and love.keyboard.isDown("lshift", "rshift") then
        DEBUG_PLAYER = not DEBUG_PLAYER
        if DEV.DEBUG_MASTER then
            print("Player debug: " .. (DEBUG_PLAYER and "ON" or "OFF"))
        end
    end
end

return Player
