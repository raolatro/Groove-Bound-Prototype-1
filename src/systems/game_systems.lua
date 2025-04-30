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

-- Import UI components
local InventoryGrid = require("src.ui.inventory_grid")
local LevelUpPanel = require("src.ui.level_up_panel")
local XPBar = require("src.ui.xp_bar")

-- The GameSystems module
local GameSystems = {
    -- System instances
    weaponSystem = nil,
    passiveSystem = nil,
    levelUpSystem = nil,
    
    -- UI component instances
    inventoryGrid = nil,
    levelUpPanel = nil,
    xpBar = nil,
    
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
    
    -- Set up UI components
    self.inventoryGrid = InventoryGrid:init(self.weaponSystem)
    self.levelUpPanel = LevelUpPanel:init(self.levelUpSystem)
    self.xpBar = XPBar:init(self.levelUpSystem)
    
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
    
    -- Debug XP addition with K key
    if DEBUG_MASTER and DEBUG_WEAPONS and love.keyboard.isDown("k") then
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
    
    -- Always draw level up panel last (on top)
    self.levelUpPanel:draw()
end

-- Handle keypressed events
function GameSystems:keypressed(key)
    -- Debug keys for weapon testing
    if DEBUG_MASTER and DEBUG_WEAPONS then
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
