-- Player module for Groove Bound
-- Handles player creation, movement, animation, and input

local L = require("lib.loader")
local Config = require("config.settings")
local PATHS = require("config.paths")
local UI = require("config.ui")
local WeaponManager = require("src.weapon_manager")
local Projectile = require("src.projectile")

-- Get global Debug instance
local Debug = _G.Debug

-- Shorthand for readability
local TUNING = Config.TUNING.PLAYER
local CONTROLS = Config.CONTROLS
local DEV = Config.DEV
local BG = UI.GRID

-- Local debug flags, ANDed with master debug
local DEBUG_PLAYER = false
local DEBUG_COLLISION = false

-- Player metatable
local Player = {}
Player.__index = Player

-- Constructor
function Player:new(x, y, world)
    -- Create instance
    local instance = {
        -- Position and physics
        x = x or 0,
        y = y or 0,
        vx = 0,
        vy = 0,
        speed = TUNING.MOVE_SPEED,
        world = world,  -- Physics world reference
        -- Dimensions
        width = TUNING.SPRITE_SIZE,
        height = TUNING.SPRITE_SIZE,
        colliderSize = BG.base, -- Size matches grid
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
        gamepad = nil,
        -- Hit area for debug visualization
        hitbox = {
            x = x or 0,
            y = y or 0,
            w = BG.base,
            h = BG.base
        }
    }
    
    -- Initialize weapon manager
    WeaponManager:init()
    
    -- Initialize physics body if world is provided
    if world then
        -- Create collider (centered on player position)
        instance.collider = world:newRectangleCollider(
            instance.x - BG.base/2,
            instance.y - BG.base/2,
            BG.base,
            BG.base,
            {collision_class = 'player'}
        )
        
        -- Set object reference and prevent rotation
        instance.collider:setObject(instance)
        instance.collider:setFixedRotation(true)
        
        -- Set up collision callbacks
        instance.collider:setPreSolve(function(collider_1, collider_2, contact)
            if collider_2.collision_class == "environment" then
                if DEV.DEBUG_COLLISION and DEV.DEBUG_MASTER and Debug.enabled then
                    Debug.log("Wall bump")
                end
            end
        end)
    end
    
    -- Load sprite sheet
    instance.spriteSheet = L.Asset.safeImage(PATHS.ASSETS.SPRITES.PLAYER, 128, 32)
    
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

-- Move based on input
function Player:move(dt)
    -- Reset velocity
    local vx, vy = 0, 0
    
    -- Apply velocity based on input
    if self.input.left then
        vx = vx - 1
        self.direction = -1
    end
    if self.input.right then
        vx = vx + 1
        self.direction = 1
    end
    if self.input.up then vy = vy - 1 end
    if self.input.down then vy = vy + 1 end
    
    -- Normalize diagonal movement
    if vx ~= 0 and vy ~= 0 then
        local length = math.sqrt(vx * vx + vy * vy)
        vx = vx / length
        vy = vy / length
    end
    
    -- Apply speed
    vx = vx * self.speed
    vy = vy * self.speed
    
    -- Store velocity
    self.vx = vx
    self.vy = vy
    
    -- Update movement state
    self.isMoving = (vx ~= 0 or vy ~= 0)
    
    -- For non-physics movement (we don't use this now but keeping for compatibility)
    if not self.collider then
        self.x = self.x + (vx * dt)
        self.y = self.y + (vy * dt)
    end
end

-- Update firing based on input
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

-- Get aim vector for weapons
function Player:getAimVector()
    return self.aimX, self.aimY
end

-- Fire weapon (placeholder)
function Player:fire()
    if DEBUG_PLAYER and DEV.DEBUG_MASTER then
        print("Player fired in direction: " .. self.aimX .. ", " .. self.aimY)
    end
    
    -- Firing is now handled by the WeaponManager
    -- This function remains for backward compatibility
end

-- Main update function
function Player:update(dt)
    -- Check for gamepad if none is set
    if not self.gamepad then
        self:checkGamepad()
    end
    
    -- Process input based on available devices
    self:processKeyboardInput()
    self:processGamepadInput()
    
    -- Apply movement (updates velocity based on input)
    self:move(dt)
    
    -- Apply velocity directly to collider
    if self.collider then
        self.collider:setLinearVelocity(self.vx, self.vy)
    end
    
    -- Update animation
    if self.currentAnimation then
        self.currentAnimation:update(dt)
    end
    
    -- Update fire cooldown
    if self.fireTimer > 0 then
        self.fireTimer = self.fireTimer - dt
    end
    
    -- Handle firing
    if self.input.fire and self.fireTimer <= 0 then
        self:fire()
        self.fireTimer = self.fireCooldown
    end
    
    -- Get current position from collider
    local x, y = 0, 0
    if self.collider then
        x, y = self.collider:getPosition()
    end
    
    -- Update weapons using collider position
    WeaponManager:updateAll(dt, x, y, self.aimX, self.aimY)
    
    -- Update projectiles
    Projectile:updateAll(dt)
end

-- Draw the player
function Player:draw()
    -- Draw projectiles behind player
    Projectile:drawAll()
    
    -- Get position directly from collider
    if self.collider and self.spriteSheet and self.currentAnimation then
        local cx, cy = self.collider:getPosition()
        
        -- Animation frame size
        local frameWidth = self.spriteSheet:getWidth() / 4
        local frameHeight = self.spriteSheet:getHeight()
        
        -- Use direction for horizontal flipping only, no position offset
        local scaleX = (self.direction < 0) and -1 or 1
        
        love.graphics.setColor(1, 1, 1)
        self.currentAnimation:draw(
            self.spriteSheet,
            cx,  -- draw at collider x
            cy,  -- draw at collider y
            0,   -- no rotation
            scaleX, -- flip horizontally based on direction
            1,   -- no vertical scaling
            frameWidth/2,  -- center horizontally
            frameHeight/2  -- center vertically
        )
    end
    -- Draw weapons (get position directly from collider)
    if self.collider then
        local x, y = self.collider:getPosition()
        WeaponManager:drawAll(x, y, self.aimX, self.aimY, self.direction)
    else
        WeaponManager:drawAll(self.x, self.y, self.aimX, self.aimY, self.direction)
    end
    
    -- Debug visualization
    if DEBUG_PLAYER and DEV.DEBUG_MASTER then
        -- Get current position for debug visualizations
        local x, y = self.x, self.y
        if self.collider then
            x, y = self.collider:getPosition()
        end
        
        -- Draw aim direction
        love.graphics.setColor(0, 1, 0, 0.7)
        love.graphics.line(
            x, y,
            x + self.aimX * 40,
            y + self.aimY * 40
        )
        
        -- Draw velocity vector
        love.graphics.setColor(0, 0, 1, 0.7)
        love.graphics.line(
            x, y,
            x + (self.vx / 10),
            y + (self.vy / 10)
        )
    end
    
    -- Draw collision debug if enabled
    if DEV.DEBUG_COLLISION and DEV.DEBUG_MASTER and self.collider and Debug.enabled then
        love.graphics.setColor(1, 0.5, 0, 0.7)
        local points = {self.collider:getWorldPoints(self.collider:getShape():getPoints())}
        love.graphics.polygon("line", points)
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
    
    -- Add test weapon when space is pressed
    if key == "space" then
        local testWeapon = WeaponManager:addWeapon("pistol", "pistol")
        if testWeapon and DEBUG_PLAYER and DEV.DEBUG_MASTER then
            print("Added test weapon: " .. testWeapon.name)
        end
    end
    
    -- Forward key presses to weapon manager and projectiles
    WeaponManager:keypressed(key)
    Projectile:keypressed(key)
end

return Player
