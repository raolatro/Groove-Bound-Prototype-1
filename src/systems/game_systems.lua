-- game_systems.lua
-- Integration module for all weapon, passive, and inventory systems

local L = require("lib.loader")
local PATHS = require("config.paths")

-- Get reference to global Debug flags
-- These are defined in main.lua as globals
local DEBUG_MASTER = _G.DEBUG_MASTER or false
local DEBUG_WEAPONS = _G.DEBUG_WEAPONS or false
local DEBUG_UI = _G.DEBUG_UI or false

-- Import all systems
local WeaponSystem = require("src.systems.weapon_system")
local PassiveSystem = require("src.systems.passive_system")
local LevelUpSystem = require("src.systems.level_up_system")
local EnemySystem = require("src.systems.enemy_system")
local EnemySpawner = require("src.systems.enemy_spawner")
local GemSystem = require("src.systems.gem_system")
local PlayerSystem = require("src.systems.player_system")

-- Import entities
local EnemyProjectile = require("src.entities.enemy_projectile")
local XPGem = require("src.entities.xp_gem")
local Projectile = require("src.projectile")

-- Import UI components
local InventoryGrid = require("src.ui.inventory_grid")
local LevelUpPanel = require("src.ui.level_up_panel")
local XPBar = require("src.ui.xp_bar")
local HPBar = require("src.ui.hp_bar")

-- The GameSystems module
local GameSystems = {
    -- System instances
    weaponSystem = nil,
    passiveSystem = nil,
    levelUpSystem = nil,
    enemySystem = nil,
    enemySpawner = nil,
    enemyProjectileSystem = nil,
    gemSystem = nil,
    playerSystem = nil,
    
    -- UI component instances
    inventoryGrid = nil,
    levelUpPanel = nil,
    xpBar = nil,
    hpBar = nil,
    
    -- Debug features
    debugStats = {
        xpToAdd = 10
    },
    
    -- Flag for whether systems have been initialized
    initialized = false
}

-- Initialize all game systems
function GameSystems:init(player)
    -- Check for debug flag
    local debugEnabled = DEBUG_MASTER and DEBUG_WEAPONS
    
    -- Store player reference
    self.player = player
    
    -- Initialize core systems (order matters)
    self.passiveSystem = PassiveSystem:init()
    
    -- Initialize weapon system with player reference and empty passive buffs
    -- (we need to initialize passive system first to get buffs)
    self.weaponSystem = WeaponSystem:init(player, self.passiveSystem:getBuffs())
    
    -- Initialize level-up system with references to both systems
    self.levelUpSystem = LevelUpSystem:init(self.weaponSystem, self.passiveSystem)
    
    -- Initialize enemy systems
    EnemyProjectile:initPool() -- Initialize enemy projectile pool
    XPGem:initPool() -- Initialize XP gem pool
    
    -- Get world reference for physics (assumed to be available from the gameplay state)
    local world = player.world or _G.world
    
    -- Initialize the enemy system
    self.enemySystem = EnemySystem:init(player, world)
    
    -- Initialize the enemy projectile system (reference stored directly in EnemyProjectile)
    self.enemyProjectileSystem = EnemyProjectile
    
    -- Connect enemy system to projectile system
    self.enemySystem:setProjectileSystem(self.enemyProjectileSystem)
    
    -- Initialize the player system (handles player damage and visual feedback)
    self.playerSystem = PlayerSystem:init(player)
    
    -- Initialize the gem system (connects to level-up system)
    self.gemSystem = GemSystem:init(player, self.levelUpSystem)
    
    -- Expose GameSystems to global for other systems to access
    _G.gameSystems = self
    
    -- Initialize the enemy spawner last (once enemy system is ready)
    self.enemySpawner = EnemySpawner:init(player, self.enemySystem, world)
    
    -- Set up UI components
    self.inventoryGrid = InventoryGrid:init(self.weaponSystem)
    self.levelUpPanel = LevelUpPanel:init(self.levelUpSystem)
    self.xpBar = XPBar:init(self.levelUpSystem)
    self.hpBar = HPBar:init(player, self.xpBar)
    
    -- Set up event listeners for HP system
    local Event = require("lib.event")
    
    Event.subscribe("PLAYER_DAMAGED", function(data)
        -- Trigger HP bar damage flash effect
        if self.hpBar then
            self.hpBar:onDamage()
        end
    end)
    
    -- Add starter weapon
    local success, message = self.weaponSystem:addWeapon("pistol")
    if debugEnabled then
        print("Starter weapon: " .. message)
    end
    
    -- Mark as initialized
    self.initialized = true
    
    -- Add starter XP (just to start at a reasonable level)
    if debugEnabled then
        self.levelUpSystem:addXP(50)
    end
    
    return self
end

-- Update all systems
function GameSystems:update(dt)
    -- Check if initialized
    if not self.initialized then
        return
    end
    
    -- Get player position and aim for weapon updates
    local x, y
    local aimX, aimY = 0, 0
    
    if self.player then
        if self.player.collider then
            x, y = self.player.collider:getPosition()
        else
            x, y = self.player.x, self.player.y
        end
        
        aimX, aimY = self.player.aimX or 0, self.player.aimY or 0
    end
    
    -- Update weapon system with player position and aim
    if x and y then
        self.weaponSystem:update(dt, x, y, aimX, aimY, self.player, self.passiveSystem:getBuffs())
    end
    
    -- Update UI components
    self.inventoryGrid:update(dt)
    self.levelUpPanel:update(dt)
    self.xpBar:update(dt)
    self.hpBar:update(dt)
    
    -- Update enemy systems
    self.enemySpawner:update(dt)
    self.enemySystem:update(dt)
    self.enemyProjectileSystem:updateAll(dt)
    
    -- Update gem system
    self.gemSystem:update(dt)
    
    -- Check for collisions between player projectiles and enemies
    if self.weaponSystem and self.enemySystem then
        -- Get active projectiles from weapon system
        local projectiles = Projectile.activeProjectiles
        
        -- Check collisions
        self.enemySystem:checkProjectileCollisions(projectiles)
    end
    
    -- Check for collisions between enemy projectiles and player
    if self.enemyProjectileSystem and not Config.DEV.INVINCIBLE then
        -- Check collisions
        local damage = self.enemyProjectileSystem:checkPlayerCollision(self.player)
        
        -- If player was hit and damage returned, apply it
        if damage and damage > 0 then
            -- This is where you would apply damage to the player
            -- For now, just log it
            if _G.DEBUG_MASTER and _G.DEBUG_ENEMIES then
                print("Player took " .. damage .. " damage from enemy projectile!")
            end
        end
    end
    
    -- Debug XP addition with K key
    if _G.DEBUG_MASTER and _G.DEBUG_WEAPONS and love.keyboard.isDown("k") then
        self.levelUpSystem:addXP(self.debugStats.xpToAdd)
    end
    
    -- Check if player is asking to fire weapon with space or mouse button
    if love.keyboard.isDown("space") or love.mouse.isDown(1) then
        -- Get player position and aim
        local x, y
        if self.player.collider then
            x, y = self.player.collider:getPosition()
        else
            x, y = self.player.x, self.player.y
        end
        
        -- Make sure we have aim values
        local aimX, aimY = self.player.aimX or 0, self.player.aimY or 0
        
        -- Fire the current weapon with passive buffs
        self.weaponSystem:fireWeapon(1, x, y, aimX, aimY, self.player, self.passiveSystem:getBuffs())
    end
end

-- Draw all systems (legacy method - calls both drawWorld and drawUI)
function GameSystems:draw()
    -- Check if initialized
    if not self.initialized then
        return
    end
    
    -- Call both draw methods
    self:drawWorld()
    self:drawUI()
end

-- Draw world elements (should be called inside camera transform)
function GameSystems:drawWorld()
    -- Check if initialized
    if not self.initialized then
        return
    end
    
    -- Draw weapon system debug visuals
    self.weaponSystem:draw()
    
    -- Draw enemy system in world space
    if self.enemySystem then
        self.enemySystem:draw()
    end
    
    -- Draw enemy projectiles in world space
    if self.enemyProjectileSystem then
        self.enemyProjectileSystem:drawAll()
    end
    
    -- Draw XP gems in world space
    if self.gemSystem then
        self.gemSystem:draw()
    end
    
    -- No UI drawing here - that's in drawUI()
end

-- Draw UI elements (should be called after camera:detach())
function GameSystems:drawUI()
    -- Check if initialized
    if not self.initialized then
        return
    end
    
    -- Draw UI components
    if self.inventoryGrid then
        self.inventoryGrid:draw()
    end
    
    if self.xpBar then
        self.xpBar:draw()
    end
    
    if self.hpBar then
        self.hpBar:draw()
    end
    
    -- Always draw level up panel last (on top)
    self.levelUpPanel:draw()
end

-- Handle keypressed events
function GameSystems:keypressed(key)
    -- Debug keys for weapon testing
    if _G.DEBUG_MASTER and _G.DEBUG_WEAPONS then
        -- Add weapon with 1-4 keys
        if key == "1" then
            self.weaponSystem:addWeapon("pistol")
        elseif key == "2" then
            self.weaponSystem:addWeapon("omni")
        elseif key == "3" then
            self.weaponSystem:addWeapon("bomb")
        elseif key == "4" then
            self.weaponSystem:addWeapon("drone")
        end
        
        -- Level up weapon with Shift+1-4
        if love.keyboard.isDown("lshift", "rshift") then
            if key == "1" and self.weaponSystem.weapons[1] then
                self.weaponSystem:levelUpWeapon(1)
            elseif key == "2" and self.weaponSystem.weapons[2] then
                self.weaponSystem:levelUpWeapon(2)
            elseif key == "3" and self.weaponSystem.weapons[3] then
                self.weaponSystem:levelUpWeapon(3)
            elseif key == "4" and self.weaponSystem.weapons[4] then
                self.weaponSystem:levelUpWeapon(4)
            end
        end
        
        -- Add passive with P key
        if key == "p" then
            self.passiveSystem:addPassive("speed")
        end
        
        -- Give XP with X key
        if key == "x" then
            self.levelUpSystem:addXP(100)
        end
    end
end

-- Handle resize events
function GameSystems:resize(w, h)
    -- Update UI component positions
    if self.xpBar then
        self.xpBar:resize(w, h)
    end
    
    if self.levelUpPanel then
        self.levelUpPanel:resize(w, h)
    end
end

-- Return the module
return GameSystems
