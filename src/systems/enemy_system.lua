-- enemy_system.lua
-- Manages enemy entities, movement, and combat

local L = require("lib.loader")
local Config = require("config.settings")
local PATHS = require("config.paths")
local EnemyDefs = require("src.data.enemy_defs")

-- Import events system
local Event = require("lib.event")

-- Define events
Event.define("ENEMY_KILLED", {"enemy", "position"})
Event.define("ENEMY_DAMAGED", {"id", "amount", "newHP"})

-- Constants
local TUNING = Config.TUNING.ENEMIES
local DEV = Config.DEV
local PI = math.pi

-- Local references
local VecNormalize = L.utils.math.normalize
local atan2 = math.atan2

-- The EnemySystem module
local EnemySystem = {
    -- Storage for active enemies
    enemies = {},
    
    -- Reference to player
    player = nil,
    
    -- Reference to enemy projectile system (will be set later)
    enemyProjectileSystem = nil,
    
    -- State
    initialized = false
}

-- Initialize the enemy system
function EnemySystem:init(player, world)
    -- Store references
    self.player = player
    self.world = world
    
    -- Clear existing enemies
    self.enemies = {}
    
    -- Mark as initialized
    self.initialized = true
    
    -- Debug output
    if _G.DEBUG_MASTER and _G.DEBUG_ENEMIES then
        print("Enemy System initialized")
    end
    
    return self
end

-- Set reference to enemy projectile system
function EnemySystem:setProjectileSystem(projectileSystem)
    self.enemyProjectileSystem = projectileSystem
    
    if _G.DEBUG_MASTER and _G.DEBUG_ENEMIES then
        print("Enemy Projectile System reference set")
    end
end

-- Spawn an enemy
function EnemySystem:spawn(enemyDef, x, y)
    -- Validate parameters
    if not enemyDef or not x or not y then
        print("Error: Missing parameters for enemy spawn")
        return nil
    end
    
    -- Get a randomized color variation
    local color = EnemyDefs.randomWarmColour(enemyDef.baseColour)
    
    -- Randomize size slightly if debug randomize is enabled
    local size = enemyDef.size
    if _G.DEBUG_MASTER and _G.DEBUG_ENEMIES and DEV.RANDOMIZE_ENEMIES then
        local range = TUNING.RANDOM_RANGE_PCT or 0.2
        size = size * (1 + (math.random() * 2 - 1) * range)
    end
    
    -- Create enemy entity
    local enemy = {
        -- Type info
        def = enemyDef,
        id = enemyDef.id,
        displayName = enemyDef.displayName,
        type = enemyDef.type,
        
        -- Position and movement
        x = x,
        y = y,
        vx = 0,
        vy = 0,
        rotation = 0,
        moveSpeed = enemyDef.moveSpeed,
        
        -- Visual properties
        size = size,
        color = color,
        
        -- Combat properties
        hp = enemyDef.hp,
        maxHp = enemyDef.hp,
        damage = enemyDef.damage or 1,
        xpMultiplier = enemyDef.xpMultiplier or 1,
        
        -- Projectile properties
        projectileEnabled = enemyDef.projectileEnabled or false,
        projectileCooldown = 0,
        
        -- State
        isActive = true,
        isDying = false,
        deathTimer = 0
    }
    
    -- Add projectile settings if enabled
    if enemy.projectileEnabled and enemyDef.projectile then
        enemy.projectileSettings = {
            fireRate = enemyDef.projectile.fireRate or 1,
            damage = enemyDef.projectile.damage or enemy.damage,
            cooldown = enemyDef.projectile.cooldown or 1,
            speed = enemyDef.projectile.speed or 150,
            range = enemyDef.projectile.range or 300,
            size = enemyDef.projectile.size or 8
        }
    end
    
    -- Add to active enemies
    table.insert(self.enemies, enemy)
    
    -- Debug output
    if _G.DEBUG_MASTER and _G.DEBUG_ENEMIES then
        print(string.format("Spawned %s enemy at (%.1f, %.1f) with HP: %d", 
            enemy.displayName, enemy.x, enemy.y, enemy.hp))
    end
    
    return enemy
end

-- Update all enemies
function EnemySystem:update(dt)
    -- Skip if not initialized
    if not self.initialized then
        return
    end
    
    -- Get player position for enemies to move toward
    local playerX, playerY
    if self.player and self.player.collider then
        playerX, playerY = self.player.collider:getPosition()
    else
        -- Default to center if player not available
        playerX, playerY = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
    end
    
    -- Update each enemy
    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        
        if enemy.isActive then
            if enemy.isDying then
                -- Update death animation
                enemy.deathTimer = enemy.deathTimer + dt
                
                -- Remove enemy after death animation
                if enemy.deathTimer >= 0.5 then -- 0.5 seconds death animation
                    table.remove(self.enemies, i)
                end
            else
                -- Direction toward player
                local dx = playerX - enemy.x
                local dy = playerY - enemy.y
                local dist = math.sqrt(dx*dx + dy*dy)
                
                -- Normalize direction
                local dirX, dirY = 0, 0
                if dist > 0 then
                    dirX, dirY = dx / dist, dy / dist
                end
                
                -- Update velocity
                enemy.vx = dirX * enemy.moveSpeed
                enemy.vy = dirY * enemy.moveSpeed
                
                -- Update position
                enemy.x = enemy.x + enemy.vx * dt
                enemy.y = enemy.y + enemy.vy * dt
                
                -- Update rotation to face player
                enemy.rotation = atan2(dy, dx)
                
                -- Check collision with player
                self:checkPlayerCollision(enemy, dt)
                
                -- Update projectile logic
                if enemy.projectileEnabled and self.enemyProjectileSystem then
                    -- Decrease cooldown
                    if enemy.projectileCooldown > 0 then
                        enemy.projectileCooldown = enemy.projectileCooldown - dt
                    end
                    
                    -- Fire projectile when cooldown is ready
                    if enemy.projectileCooldown <= 0 and dist < (enemy.projectileSettings.range or 400) then
                        -- Fire projectile toward player
                        if self.enemyProjectileSystem then
                            self.enemyProjectileSystem:spawn(
                                enemy.x, enemy.y,
                                dirX, dirY,
                                enemy.projectileSettings
                            )
                        end
                        
                        -- Reset cooldown
                        enemy.projectileCooldown = enemy.projectileSettings.cooldown
                    end
                end
            end
        end
    end
end

-- Draw all enemies
function EnemySystem:draw()
    -- Skip if not initialized
    if not self.initialized then
        return
    end
    
    -- Store current graphics state
    local r, g, b, a = love.graphics.getColor()
    
    -- Draw each enemy
    for _, enemy in ipairs(self.enemies) do
        if enemy.isActive then
            -- Determine alpha based on dying state
            local alpha = 1.0
            if enemy.isDying then
                alpha = 1.0 - (enemy.deathTimer / 0.5) -- Fade out during death
            end
            
            -- Draw enemy body (filled circle)
            love.graphics.setColor(
                enemy.color[1], 
                enemy.color[2], 
                enemy.color[3], 
                alpha * enemy.color[4]
            )
            love.graphics.circle("fill", enemy.x, enemy.y, enemy.size)
            
            -- Draw direction indicator (small line pointing in movement direction)
            local lineLength = enemy.size * 0.8
            love.graphics.line(
                enemy.x, 
                enemy.y, 
                enemy.x + math.cos(enemy.rotation) * lineLength, 
                enemy.y + math.sin(enemy.rotation) * lineLength
            )
            
            -- Draw debug information if enabled
            if _G.DEBUG_MASTER and _G.DEBUG_ENEMIES then
                -- Draw hitbox outline
                love.graphics.setColor(1, 1, 1, alpha * 0.5)
                love.graphics.circle("line", enemy.x, enemy.y, enemy.size)
                
                -- Draw HP bar
                local hpWidth = enemy.size * 2
                local hpHeight = 3
                local hpX = enemy.x - hpWidth / 2
                local hpY = enemy.y - enemy.size - 10
                
                -- HP bar background
                love.graphics.setColor(0.2, 0.2, 0.2, alpha * 0.7)
                love.graphics.rectangle("fill", hpX, hpY, hpWidth, hpHeight)
                
                -- HP bar fill
                local hpRatio = enemy.hp / enemy.maxHp
                love.graphics.setColor(1 - hpRatio, hpRatio, 0, alpha * 0.8)
                love.graphics.rectangle("fill", hpX, hpY, hpWidth * hpRatio, hpHeight)
                
                -- Draw enemy name and HP text
                local smallFont = love.graphics.newFont(8)
                local prevFont = love.graphics.getFont()
                love.graphics.setFont(smallFont)
                love.graphics.setColor(1, 1, 1, alpha * 0.9)
                love.graphics.printf(
                    enemy.displayName .. " (" .. enemy.hp .. "/" .. enemy.maxHp .. ")", 
                    enemy.x - 50, hpY - 12, 
                    100, "center"
                )
                love.graphics.setFont(prevFont)
                
                -- Draw projectile cooldown if applicable
                if enemy.projectileEnabled then
                    -- Show cooldown timer
                    love.graphics.setColor(1, 0.7, 0.3, alpha * 0.8)
                    if enemy.projectileCooldown > 0 then
                        love.graphics.printf(
                            string.format("%.1fs", enemy.projectileCooldown),
                            enemy.x - 50, hpY + 5,
                            100, "center"
                        )
                    else
                        love.graphics.printf(
                            "READY", 
                            enemy.x - 50, hpY + 5,
                            100, "center"
                        )
                    end
                end
            end
        end
    end
    
    -- Restore graphics state
    love.graphics.setColor(r, g, b, a)
end

-- Check for collisions between an enemy and the player
function EnemySystem:checkPlayerCollision(enemy, dt)
    -- Skip if player is not available or if player is invincible
    if not self.player or self.player.invincibleTimer > 0 or Config.DEV.INVINCIBLE then
        return
    end
    
    -- Skip if enemy is already dying
    if enemy.isDying or not enemy.isActive then
        return
    end
    
    -- Get player position
    local playerX, playerY
    if self.player.collider then
        playerX, playerY = self.player.collider:getPosition()
    else
        playerX, playerY = self.player.x, self.player.y
    end
    
    -- Calculate distance between enemy and player
    local dx = playerX - enemy.x
    local dy = playerY - enemy.y
    local distance = math.sqrt(dx*dx + dy*dy)
    
    -- Get hit radii with fallback defaults
    local playerHitRadius = 24 -- Default fallback value
    
    -- Try to get hit radius from player or config with multiple safety checks
    if self.player.hitRadius and self.player.hitRadius > 0 then
        playerHitRadius = self.player.hitRadius
    elseif Config and Config.TUNING and Config.TUNING.PLAYER and Config.TUNING.PLAYER.HIT_RADIUS then
        playerHitRadius = Config.TUNING.PLAYER.HIT_RADIUS
    end
    
    -- Ensure enemy size is valid
    local enemyHitRadius = enemy.size or 20 -- Default fallback
    
    -- Check for collision
    if distance < (playerHitRadius + enemyHitRadius) then
        -- Contact damage from enemy definition or use default
        local contactDamage = enemy.def.contactDamage or Config.TUNING.ENEMIES.DEFAULT_CONTACT
        
        -- Get PlayerSystem from GameSystems
        local gameSystems = _G.gameSystems or {}
        
        -- Apply damage to player using PlayerSystem if available
        local damageApplied = false
        if gameSystems.playerSystem then
            damageApplied = gameSystems.playerSystem:applyDamage(contactDamage, "contact")
        else
            -- Fallback to direct player damage if PlayerSystem not available
            damageApplied = self.player:takeDamage(contactDamage)
            
            -- Debug output in fallback mode
            if damageApplied and _G.DEBUG_MASTER and _G.DEBUG_HP then
                print(string.format("Player hit by %s for %d damage (FALLBACK PATH)", 
                    enemy.displayName, contactDamage))
            end
        end
        
        -- Kill the enemy on contact (kamikaze behavior) with "contact" cause
        self:killEnemy(enemy, "contact")
    end
end

-- Apply damage to an enemy and check if it dies
function EnemySystem:applyDamage(enemy, damage, source)
    -- Skip if enemy is already dying
    if enemy.isDying or not enemy.isActive then
        return false
    end
    
    -- Apply damage
    enemy.hp = enemy.hp - damage
    
    -- Fire damage event with source information
    Event.dispatch("ENEMY_DAMAGED", {
        id = enemy.id,
        amount = damage,
        newHP = enemy.hp,
        source = source or "unknown"
    })
    
    -- Debug output
    if _G.DEBUG_MASTER and (_G.DEBUG_ENEMIES or _G.DEBUG_HP) then
        print(string.format("%s took %d damage from %s! HP: %d/%d", 
            enemy.displayName, damage, source or "unknown", enemy.hp, enemy.maxHp))
    end
    
    -- Check if enemy died
    if enemy.hp <= 0 then
        self:killEnemy(enemy, source)
        return true
    end
    
    return false
end

-- Keep legacy method for backward compatibility
function EnemySystem:damageEnemy(enemy, damage)
    return self:applyDamage(enemy, damage, "unknown")
end

-- Handle enemy death with cause tracking
function EnemySystem:killEnemy(enemy, cause)
    -- Skip if already dying
    if enemy.isDying then
        return
    end
    
    -- Mark as dying
    enemy.isDying = true
    enemy.deathTimer = 0
    
    -- Debug output
    if _G.DEBUG_MASTER and _G.DEBUG_ENEMIES then
        print(string.format("%s was killed by %s at position (%.1f, %.1f)!", 
            enemy.displayName, cause or "unknown", enemy.x, enemy.y))
    end
    
    -- Dispatch death event with position, enemy info, and cause
    Event.dispatch("ENEMY_KILLED", {
        enemy = enemy,
        position = {x = enemy.x, y = enemy.y},
        cause = cause or "unknown"
    })
end

-- Check collision between all enemies and projectiles
function EnemySystem:checkProjectileCollisions(projectiles)
    -- Skip if no enemies or projectiles
    if #self.enemies == 0 or not projectiles then
        return
    end
    
    -- Check each enemy against each projectile
    for _, enemy in ipairs(self.enemies) do
        if enemy.isActive and not enemy.isDying then
            for _, proj in ipairs(projectiles) do
                if proj.isActive then
                    -- Simple circle collision check
                    local dx = enemy.x - proj.x
                    local dy = enemy.y - proj.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    
                    -- Check if collision occurred
                    if dist < (enemy.size + (proj.radius or proj.size or 5)) then
                        -- Enemy takes damage from projectile
                        local enemyKilled = self:damageEnemy(enemy, proj.damage)
                        
                        -- Handle piercing logic
                        if proj.piercing and proj.piercing > 0 then
                            -- If projectile has piercing, reduce the piercing count
                            proj.piercing = proj.piercing - 1
                            
                            -- Debug output for piercing
                            if _G.DEBUG_MASTER and _G.DEBUG_HP then
                                print(string.format("Projectile pierced through! Remaining pierces: %d", proj.piercing))
                            end
                        else
                            -- If no piercing, deactivate the projectile
                            proj.isActive = false
                        end
                        
                        -- Debug output
                        if _G.DEBUG_MASTER and _G.DEBUG_HP then
                            print(string.format("Enemy %s hit for %d damage", 
                                enemy.displayName, proj.damage))
                        end
                    end
                end
            end
        end
    end
end

-- Return the module
return EnemySystem
