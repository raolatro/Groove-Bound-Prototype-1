-- game_systems.lua
-- Integration module for all weapon, passive, and inventory systems

local L = require("lib.loader")
local PATHS = require("config.paths")
local Debug = require("src.debug")

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
local GameOverSystem = require("src.systems.game_over_system")

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
    gameOverSystem = nil,
    
    -- Game state
    gameTimer = 0,
    
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
    
    -- Initialize level-up system with references to both systems and player
    self.levelUpSystem = LevelUpSystem:init(self.weaponSystem, self.passiveSystem, player)
    
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
    
    -- Initialize the game over system (after player and systems)
    self.gameOverSystem = GameOverSystem:init(player, self)
    
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
        Debug.log("Starter weapon: " .. message)
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
    -- Use pcall for all method calls to prevent errors
    local function safeCall(obj, method, ...)
        if obj and type(obj[method]) == "function" then
            local success, result = pcall(obj[method], obj, ...)
            if not success and _G.DEBUG_MASTER then
                Debug.log("Error calling " .. method .. ": " .. tostring(result))
            end
            return success, result
        end
        return false
    end
    
    -- Check if initialized
    if not self.initialized then
        return
    end
    
    -- Check if level-up shop is active (safely)
    local isLevelUpActive = self.levelUpSystem and 
                          (self.levelUpSystem.shopOpen or self.levelUpSystem.flashActive)
    
    -- Don't update gameplay systems if in level-up shop or game over
    local pauseGameplay = isLevelUpActive or 
                        (self.gameOverSystem and self.gameOverSystem.isGameOver)
    
    -- Always update level-up system and game over system first
    safeCall(self.levelUpSystem, "update", dt)
    safeCall(self.gameOverSystem, "update", dt)
    
    -- Update UI components that should always update
    safeCall(self.xpBar, "update", dt)
    safeCall(self.hpBar, "update", dt)
    
    -- If game over or level-up shop is active, bail out early
    if pauseGameplay then
        return
    end
    
    -- Update game timer
    self.gameTimer = (self.gameTimer or 0) + dt
    
    -- Get player position and aim safely
    local x, y, aimX, aimY
    if self.player then
        if self.player.collider then
            x, y = self.player.collider:getPosition()
        else
            x, y = self.player.x or 0, self.player.y or 0
        end
        aimX, aimY = self.player.aimX or 0, self.player.aimY or 0
    end
    
    -- Get passive buffs safely
    local buffs = {}
    if self.passiveSystem then
        local success, result = safeCall(self.passiveSystem, "getBuffs")
        if success then buffs = result end
    end
    
    -- Update core gameplay systems safely
    if self.weaponSystem and x and y then
        safeCall(self.weaponSystem, "update", dt, x, y, aimX, aimY, self.player, buffs)
    else
        safeCall(self.weaponSystem, "update", dt)
    end
    
    safeCall(self.passiveSystem, "update", dt)
    safeCall(self.enemySystem, "update", dt)
    safeCall(self.enemyProjectileSystem, "updateAll", dt)
    safeCall(self.enemySpawner, "update", dt)
    safeCall(self.gemSystem, "update", dt)
    
    -- Update UI components
    safeCall(self.inventoryGrid, "update", dt)
    safeCall(self.levelUpPanel, "update", dt)
    
    -- Handle collisions safely
    if self.weaponSystem and self.enemySystem then
        local projectiles = {}
        if Projectile and Projectile.activeProjectiles then
            projectiles = Projectile.activeProjectiles
        end
        safeCall(self.enemySystem, "checkProjectileCollisions", projectiles)
    end
    
    -- Handle enemy projectile collisions
    if self.enemyProjectileSystem and self.player then
        local invincible = Config and Config.DEV and Config.DEV.INVINCIBLE
        if not invincible then
            local success, damage = safeCall(self.enemyProjectileSystem, "checkPlayerCollision", self.player)
            if success and damage and damage > 0 and _G.DEBUG_MASTER and _G.DEBUG_ENEMIES then
                Debug.log("Player took " .. damage .. " damage from enemy projectile!")
            end
        end
    end
    
    -- Debug XP addition
    if self.levelUpSystem and self.debugStats and _G.DEBUG_MASTER and 
       _G.DEBUG_WEAPONS and love.keyboard.isDown("k") then
        safeCall(self.levelUpSystem, "addXP", self.debugStats.xpToAdd or 10)
    end
    
    -- Handle weapon firing
    if self.weaponSystem and self.player and 
       (love.keyboard.isDown("space") or love.mouse.isDown(1)) and
       x and y and aimX and aimY then
        safeCall(self.weaponSystem, "fireWeapon", 1, x, y, aimX, aimY, self.player, buffs)
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
    
    -- Draw inventory grid (if not game over or in level-up)
    local isInShop = self.levelUpSystem and (self.levelUpSystem.shopOpen or self.levelUpSystem.flashActive)
    if self.inventoryGrid and not (self.gameOverSystem and self.gameOverSystem.isGameOver) and not isInShop then
        self.inventoryGrid:draw()
    end
    
    -- Always draw XP and HP bars (unless in level-up shop)
    if self.xpBar and not isInShop then
        self.xpBar:draw()
    end
    
    if self.hpBar and not isInShop then
        self.hpBar:draw()
    end
    
    -- Draw level up panel (if not game over or in level-up shop)
    if not (self.gameOverSystem and self.gameOverSystem.isGameOver) and not isInShop then
        self.levelUpPanel:draw()
    end
    
    -- Draw level-up shop UI if active
    if self.levelUpSystem then
        self.levelUpSystem:draw()
    end
    
    -- Draw game over UI last (on top of everything)
    if self.gameOverSystem then
        self.gameOverSystem:draw()
    end
end

-- Handle keypressed events
function GameSystems:keypressed(key)
    -- Handle game over input
    if self.gameOverSystem and self.gameOverSystem.isGameOver then
        -- Forward key presses to game over menu
        if self.gameOverSystem.gameMenu then
            self.gameOverSystem.gameMenu:keypressed(key)
        end
        return -- Don't process other input during game over
    end
    
    -- Handle level-up shop input
    if self.levelUpSystem and (self.levelUpSystem.shopOpen or self.levelUpSystem.flashActive) then
        -- Forward key presses to level-up shop
        if self.levelUpSystem:keypressed(key) then
            return -- Input was handled by level-up shop
        end
    end
    
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
        
        -- Level up weapon with 5 key
        if key == "5" then
            self:levelUpCurrentWeapon()
        end
    end
end

-- Handle mouse press events
function GameSystems:mousepressed(x, y, button)
    -- Check if initialized
    if not self.initialized then
        return
    end
    
    -- Handle game over input
    if self.gameOverSystem and self.gameOverSystem.isGameOver then
        -- Forward mouse presses to game over menu
        if self.gameOverSystem.gameMenu then
            self.gameOverSystem.gameMenu:mousepressed(x, y, button)
        end
        return -- Don't process other input during game over
    end
    
    -- Handle level-up shop input
    if self.levelUpSystem and (self.levelUpSystem.shopOpen or self.levelUpSystem.flashActive) then
        -- Forward mouse presses to level-up shop
        if self.levelUpSystem:mousepressed(x, y, button) then
            return -- Input was handled by level-up shop
        end
    end
end

-- Handle gamepad button press events
function GameSystems:gamepadpressed(joystick, button)
    -- Check if initialized
    if not self.initialized then
        return
    end
    
    -- Handle game over input
    if self.gameOverSystem and self.gameOverSystem.isGameOver then
        -- Forward gamepad button presses to game over menu
        if self.gameOverSystem.gameMenu then
            self.gameOverSystem.gameMenu:gamepadpressed(joystick, button)
        end
        return -- Don't process other input during game over
    end
    
    -- Handle level-up shop input
    if self.levelUpSystem and (self.levelUpSystem.shopOpen or self.levelUpSystem.flashActive) then
        -- Forward gamepad presses to level-up shop
        if self.levelUpSystem:gamepadpressed(joystick, button) then
            return -- Input was handled by level-up shop
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
