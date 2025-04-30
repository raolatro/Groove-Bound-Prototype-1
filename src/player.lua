-- Player module for Groove Bound
-- Handles player creation, movement, animation, and input

local L = require("lib.loader")
local Config = require("config.settings")
local PATHS = require("config.paths")
local UI = require("config.ui")
local Controls = require("config.controls")
local Projectile = require("src.projectile")

-- Get global Debug instance
local Debug = _G.Debug

-- Shorthand for readability
local TUNING = Config.TUNING.PLAYER
local DEV = Config.DEV
local BG = UI.GRID

-- Local debug flags, ANDed with master debug
local DEBUG_PLAYER = false

-- Vector normalization helper function
local function VecNormalize(x, y)
    local length = math.sqrt(x * x + y * y)
    if length > 0 then
        return x / length, y / length
    end
    return x, y
end
local DEBUG_COLLISION = false

-- Player metatable
local Player = {}
Player.__index = Player

-- Constructor
function Player:new(x, y, world)
    -- Create instance
    local instance = {
        -- Position
        x = x or 0,
        y = y or 0,
        -- Velocity
        vx = 0,
        vy = 0,
        -- Physics body
        collider = nil,
        -- Speed
        speed = TUNING.MOVE_SPEED,
        -- Sprite
        spriteSheet = nil,
        currentAnimation = nil,
        currentFrame = nil,
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
        -- Analog stick values for combined movement
        stickX = 0,
        stickY = 0,
        -- Health-related fields
        currentHP = Config.TUNING.PLAYER.MAX_HP or 200,
        maxHP = Config.TUNING.PLAYER.MAX_HP or 200,
        invincibleTimer = 0,
        invincibleTime = Config.TUNING.PLAYER.INVINCIBLE_TIME or 1.0,
        damageFlashTimer = 0,
        -- Hit area for debug visualization
        hitbox = {
            x = x or 0,
            y = y or 0,
            w = BG.base,
            h = BG.base
        }
    }
    
    -- Weapons are now managed by GameSystems
    -- No need to initialize weapons here
    
    -- Initialize physics body if world is provided
    if world then
        -- Create triple-height collider (centered on player position)
        -- One grid square above and below the player = 3x height
        instance.collider = world:newRectangleCollider(
            instance.x - BG.base/2,
            instance.y - BG.base*3/2,  -- Centered vertically on 3x height
            BG.base,
            BG.base*3,  -- Triple height collider
            {collision_class = 'player'}
        )
        
        -- Set object reference and prevent rotation
        instance.collider:setObject(instance)
        instance.collider:setFixedRotation(true)
        
        -- Set up collision callbacks
        instance.collider:setPreSolve(function(collider_1, collider_2, contact)
            if collider_2.collision_class == "environment" then
                if DEV.DEBUG_COLLISION and DEV.DEBUG_MASTER and Debug.enabled then
                    -- Debug.log("Wall bump")
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

-- Helper function to log when input modes change - for debugging only
local function logInputModeChange(mode)
    if DEV.DEBUG_MASTER and Debug.enabled and Debug.INPUT then
        Debug.log("[" .. mode .. "] Using " .. mode .. " controls")
    end
end

-- Read mouse aim vector
function Player:readMouseAim()
    -- Get mouse position
    local mouseX, mouseY = love.mouse.getPosition()
    
    -- Get current player position
    local px, py = 0, 0
    if self.collider then
        px, py = self.collider:getPosition()
    else
        px, py = self.x, self.y
    end
    
    -- Convert screen to world coordinates
    if _G.camera then
        -- Convert screen to world coordinates
        mouseX, mouseY = _G.camera:screenToWorld(mouseX, mouseY)
        
        -- Calculate aim vector from player to mouse world position
        local dx = mouseX - px
        local dy = mouseY - py
        
        -- Always normalize and update - no dead zone for mouse
        self.aimX, self.aimY = VecNormalize(dx, dy)
        
        if DEV.DEBUG_MASTER and Debug.enabled and Debug.AIM then
            -- Debug.log("Aim updated from mouse")
        end
    end
end

-- Process keyboard input for movement
function Player:processKeyboardInput()
    -- Movement keys - WASD and arrow keys (will be combined in move() method)
    self.input.up = love.keyboard.isDown('w', 'up')
    self.input.down = love.keyboard.isDown('s', 'down')
    self.input.left = love.keyboard.isDown('a', 'left')
    self.input.right = love.keyboard.isDown('d', 'right')
    
    -- Fire input
    self.input.fire = love.keyboard.isDown(Controls.KEYBOARD.FIRE)
    
    -- Mouse aiming is now handled separately in readMouseAim()
    -- This allows for proper input mode handling
end

-- Read gamepad aim from right stick
function Player:readPadAim()
    -- Skip if no gamepad available
    if #love.joystick.getJoysticks() == 0 or not self.gamepad then return end
    
    -- Get right stick for aiming
    local rightX = self.gamepad:getGamepadAxis(Controls.GAMEPAD.AIM_AXES.HORIZONTAL)
    local rightY = self.gamepad:getGamepadAxis(Controls.GAMEPAD.AIM_AXES.VERTICAL)
    
    -- Calculate stick magnitude
    local magnitude = rightX*rightX + rightY*rightY
    
    -- If right stick is being used (outside deadzone), update aim direction
    -- Otherwise, keep previous aim direction (persistence)
    if magnitude > Controls.DEADZONE*Controls.DEADZONE then
        local prevX, prevY = self.aimX, self.aimY
        self.aimX, self.aimY = VecNormalize(rightX, rightY)
        
        if DEV.DEBUG_MASTER and Debug.enabled and Debug.AIM then
            if math.abs(prevX - self.aimX) > 0.01 or math.abs(prevY - self.aimY) > 0.01 then
                -- Debug.log("Aim updated from stick")
            end
        end
    end
end

-- Process gamepad input for movement
function Player:processGamepadInput()
    -- Guard against no gamepad or no joysticks
    if #love.joystick.getJoysticks() == 0 or not self.gamepad then return end
    
    -- Get left stick for movement
    local leftX = self.gamepad:getGamepadAxis(Controls.GAMEPAD.MOVE_AXES.HORIZONTAL)
    local leftY = self.gamepad:getGamepadAxis(Controls.GAMEPAD.MOVE_AXES.VERTICAL)
    
    -- Apply deadzone
    if math.abs(leftX) < Controls.DEADZONE then leftX = 0 end
    if math.abs(leftY) < Controls.DEADZONE then leftY = 0 end
    
    -- Set input flags based on analog values
    self.input.left = self.input.left or leftX < -Controls.DEADZONE
    self.input.right = self.input.right or leftX > Controls.DEADZONE
    self.input.up = self.input.up or leftY < -Controls.DEADZONE
    self.input.down = self.input.down or leftY > Controls.DEADZONE
    
    -- Store stick movement values for combining with keyboard
    self.stickX = leftX
    self.stickY = leftY
    
    -- Fire input
    self.input.fire = self.gamepad:isGamepadDown(Controls.GAMEPAD.BUTTONS.FIRE)
    
    -- Right stick aiming is now handled separately in readPadAim()
    -- This allows for proper input mode handling
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
    self.aimX, self.aimY = VecNormalize(x, y)
end

-- Update aim direction based on point
function Player:updateAimFromPoint(targetX, targetY)
    -- Get current position
    local px, py = 0, 0
    if self.collider then
        px, py = self.collider:getPosition()
    else
        px, py = self.x, self.y
    end
    
    -- Calculate vector from player to point
    local dx = targetX - px
    local dy = targetY - py
    
    -- Normalize
    self:normalizeAim(dx, dy)
end

-- Move based on input
function Player:move(dt)
    -- Get keyboard input movement vector
    local mvx, mvy = 0, 0
    if self.input.left then mvx = mvx - 1 end
    if self.input.right then mvx = mvx + 1 end
    if self.input.up then mvy = mvy - 1 end
    if self.input.down then mvy = mvy + 1 end
    
    -- Add gamepad stick input if available
    if self.stickX and self.stickY then
        mvx = mvx + self.stickX
        mvy = mvy + self.stickY
    end
    
    -- Update facing direction based on input
    if mvx < 0 then
        self.direction = -1
    elseif mvx > 0 then
        self.direction = 1
    end
    
    -- Normalize diagonal movement
    if mvx ~= 0 or mvy ~= 0 then
        local length = math.sqrt(mvx * mvx + mvy * mvy)
        mvx = mvx / length
        mvy = mvy / length
        
        -- Apply speed
        mvx = mvx * self.speed
        mvy = mvy * self.speed
    end
    
    -- Store velocity
    self.vx = mvx
    self.vy = mvy
    
    -- Update movement state
    self.isMoving = (mvx ~= 0 or mvy ~= 0)
    
    -- For non-physics movement (we don't use this now but keeping for compatibility)
    if not self.collider then
        self.x = self.x + (mvx * dt)
        self.y = self.y + (mvy * dt)
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
    
    -- Reset input state for this frame
    self.input.up = false
    self.input.down = false
    self.input.left = false
    self.input.right = false
    self.input.fire = false
    self.stickX = 0
    self.stickY = 0
    
    -- Process input based on current input mode
    if Controls.inputMode == "pad" then
        self:processGamepadInput()
        self:readPadAim()
    else
        self:processKeyboardInput()
    end
    
    -- Mouse aiming is always enabled regardless of input mode
    if Controls.inputMode == "mouse" then
        self:readMouseAim()
    end
    
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
    
    -- Update invincibility timer if active
    if self.invincibleTimer > 0 then
        self.invincibleTimer = self.invincibleTimer - dt
        
        -- Debug flash during invincibility
        if _G.DEBUG_MASTER and _G.DEBUG_HP then
            -- Flash faster when invincible for visual feedback
            if math.floor(self.invincibleTimer * 10) % 2 == 0 then
                -- Debug invincibility visualization
            end
        end
    end
    
    -- Update damage flash timer if active
    if self.damageFlashTimer > 0 then
        self.damageFlashTimer = self.damageFlashTimer - dt
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
    
    -- Weapons are now updated by GameSystems
    -- No need to update weapons here
    
    -- But we'll still update projectiles
    Projectile:updateAll(dt)
end

-- Update health-related timers
function Player:updateHealthTimers(dt)
    -- Update invincibility timer
    if self.invincibleTimer > 0 then
        self.invincibleTimer = self.invincibleTimer - dt
        
        -- Clamp to zero to prevent negative values
        if self.invincibleTimer < 0 then
            self.invincibleTimer = 0
        end
    end
    
    -- Update damage flash timer
    if self.damageFlashTimer > 0 then
        self.damageFlashTimer = self.damageFlashTimer - dt
        
        -- Clamp to zero to prevent negative values
        if self.damageFlashTimer < 0 then
            self.damageFlashTimer = 0
        end
    end
end

-- Apply damage to the player
function Player:takeDamage(amount, source)
    -- Skip if invincible
    if self.invincibleTimer > 0 or Config.DEV.INVINCIBLE then
        if _G.DEBUG_MASTER and _G.DEBUG_HP then
            print("Player is invincible, damage ignored")
        end
        return false
    end
    
    -- Apply damage with safety checks
    -- Initialize currentHP if it's nil
    if self.currentHP == nil then
        self.currentHP = Config.TUNING.PLAYER.MAX_HP or 200
    end
    
    -- Initialize maxHP if nil
    if self.maxHP == nil then
        self.maxHP = Config.TUNING.PLAYER.MAX_HP or 200
    end
    
    local oldHP = self.currentHP
    self.currentHP = math.max(0, self.currentHP - amount)
    
    -- Track last damage source for debug display
    self.lastDamageSource = source or "unknown"
    self.lastDamageAmount = amount
    self.lastDamageTime = 0 -- Will be incremented in update
    
    -- Start invincibility timer with safety check
    self.invincibleTimer = self.invincibleTime or Config.TUNING.PLAYER.INVINCIBLE_TIME or 0.8
    
    -- Start damage flash timer
    self.damageFlashTimer = 0.2
    
    -- Debug output
    if _G.DEBUG_MASTER and _G.DEBUG_HP then
        print(string.format("Player -%d HP from %s (%d/%d)", 
            amount, source or "unknown", self.currentHP, self.maxHP))
    end
    
    -- Fire event with source information
    local Event = require("lib.event")
    Event.dispatch("PLAYER_DAMAGED", {
        amount = amount,
        newHP = self.currentHP,
        source = source or "unknown"
    })
    
    -- Check for death
    if self.currentHP <= 0 then
        self:die()
    end
    
    return true
end

-- Player death
function Player:die()
    -- Debug output
    if _G.DEBUG_MASTER and _G.DEBUG_HP then
        print("PLAYER DIED")
    end
    
    -- Fire event
    local Event = require("lib.event")
    Event.dispatch("PLAYER_DEAD", {})
    
    -- For now, we don't implement actual death behavior
    -- This would be handled by the game state management
 end

-- Draw the player
function Player:draw()
    -- Projectiles are now drawn by the game_play module within camera transformation
    
    -- Get position directly from collider
    if self.collider and self.spriteSheet and self.currentAnimation then
        local cx, cy = self.collider:getPosition()
        
        -- Animation frame size
        local frameWidth = self.spriteSheet:getWidth() / 4
        local frameHeight = self.spriteSheet:getHeight()
        
        -- Use direction for horizontal flipping only, no position offset
        local scaleX = (self.direction < 0) and -1 or 1
        
        -- Set color based on damage state
        if self.damageFlashTimer > 0 then
            -- Flash red when taking damage
            local flashColor = Config.DEV.HP_DEBUG.DAMAGE_FLASH_COLOR or {1, 0, 0, 1}
            love.graphics.setColor(flashColor)
        elseif self.invincibleTimer > 0 then
            -- Flash between normal and translucent when invincible
            if math.floor(self.invincibleTimer * 10) % 2 == 0 then
                love.graphics.setColor(1, 1, 1, 0.6) -- Translucent
            else
                love.graphics.setColor(1, 1, 1, 1) -- Normal
            end
        else
            -- Normal rendering
            love.graphics.setColor(1, 1, 1)
        end
        
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
    -- Weapons are now drawn by GameSystems
    -- No need to draw weapons here
    
    -- Debug visualization
    local x, y = self.x, self.y
    if self.collider then
        x, y = self.collider:getPosition()
    end
    
    -- SEPARATE DEBUG FLAGS for different visualizations
    -- Always use _G.DEBUG_* to get the most current debug flag values
    
    -- Draw aim direction only if DEBUG_MASTER is true AND DEBUG_AIM is true
    if (_G.DEBUG_MASTER and _G.DEBUG_AIM) then
        -- Draw aim direction with a clear, visible green line
        love.graphics.setColor(0, 1, 0, 0.7)
        love.graphics.line(
            x, y,
            x + self.aimX * 60, -- Make longer for better visibility
            y + self.aimY * 60
        )
        
        -- Draw aim target point
        love.graphics.setColor(1, 0, 0, 0.7)
        love.graphics.circle("fill", x + self.aimX * 60, y + self.aimY * 60, 5)
    end
    
    -- Draw velocity vector only if DEBUG_MASTER is true AND DEBUG_PLAYER is true
    if (_G.DEBUG_MASTER and _G.DEBUG_PLAYER) then
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
    
    -- Draw HP debug visualization
    if _G.DEBUG_MASTER and _G.DEBUG_HP then
        -- Get current position
        local px, py = x, y
        
        -- Draw hit radius circle
        local hitRadius = self.hitRadius or Config.TUNING.PLAYER.HIT_RADIUS or 24
        
        -- Draw health indicator circle with color based on HP percent
        local hpPercent = self.currentHP / self.maxHP
        
        -- Use color gradient: Green (full HP) to Yellow (half HP) to Red (low HP)
        local r = math.min(2 - hpPercent * 2, 1) -- Red increases as health decreases
        local g = math.min(hpPercent * 2, 1)     -- Green decreases as health decreases
        
        -- If invincible, use a pulsing effect
        if self.invincibleTimer > 0 then
            -- Pulse between blue and normal HP color
            if math.floor(self.invincibleTimer * 10) % 2 == 0 then
                love.graphics.setColor(0.3, 0.3, 1, 0.6) -- Blue for invincibility
            else
                love.graphics.setColor(r, g, 0, 0.6)
            end
        else
            love.graphics.setColor(r, g, 0, 0.6)
        end
        
        -- Draw the hitbox circle
        love.graphics.circle("line", px, py, hitRadius)
        
        -- Draw numeric HP overlay
        if Config.TUNING.DEBUG and Config.TUNING.DEBUG.NUM_OVERLAY then
            love.graphics.setColor(1, 1, 1, 0.8)
            
            -- Display current/max HP
            love.graphics.print(tostring(math.floor(self.currentHP)) .. "/" .. tostring(self.maxHP), 
                               px - 15, py - hitRadius - 15)
            
            -- Display damage source if recently damaged
            if self.lastDamageSource and self.lastDamageTime and self.lastDamageTime < 3.0 then
                love.graphics.setColor(1, 0.7, 0.7, 0.8)
                love.graphics.print(string.format("-%.0f (%s)", self.lastDamageAmount or 0, self.lastDamageSource),
                                  px - 25, py - hitRadius - 30)
            end
        end
        
        -- Update last damage time in draw to ensure it's updated even during paused states
        if self.lastDamageTime ~= nil then
            self.lastDamageTime = self.lastDamageTime + love.timer.getDelta()
        end
    end
    
    -- Draw aim debug if enabled
    if Debug.enabled and Debug.AIM and DEV.DEBUG_MASTER then
        -- Get current position
        local px, py = 0, 0
        if self.collider then
            px, py = self.collider:getPosition()
        else
            px, py = self.x, self.y
        end
        
        -- Calculate aim point (32 pixels away from player)
        local aimPointX = px + self.aimX * 32
        local aimPointY = py + self.aimY * 32
        
        -- Draw circle at aim point
        love.graphics.setColor(1, 0, 0, 0.7)
        love.graphics.circle("line", aimPointX, aimPointY, 12)
        
        -- Draw crosshair at aim point
        love.graphics.setColor(1, 1, 0, 0.9)
        love.graphics.line(aimPointX - 4, aimPointY, aimPointX + 4, aimPointY)
        love.graphics.line(aimPointX, aimPointY - 4, aimPointX, aimPointY + 4)
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
    if key == "f3" and love.keyboard.isDown("lshift", "rshift") then
        DEBUG_PLAYER = not DEBUG_PLAYER
        if DEV.DEBUG_MASTER then
            print("Player debug: " .. (DEBUG_PLAYER and "ON" or "OFF"))
        end
    end
    
    -- Weapons are now managed by GameSystems
    -- Test weapons are now handled there
    Projectile:keypressed(key)
end

return Player
