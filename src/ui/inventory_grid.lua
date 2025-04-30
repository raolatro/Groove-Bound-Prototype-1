-- inventory_grid.lua
-- Displays weapons and their cooldowns in a grid format

local L = require("lib.loader")
local PATHS = require("config.paths")
local ItemDefs = require("src.data.item_defs")

-- Get reference to global Debug flags
-- These are defined in main.lua as globals
local DEBUG_MASTER = _G.DEBUG_MASTER or false
local DEBUG_UI = _G.DEBUG_UI or false

-- The InventoryGrid module
local InventoryGrid = {
    -- UI positioning and sizing
    x = 20,
    y = 20,
    padding = 10,
    iconSize = 48,
    barHeight = 3,
    
    -- Font for level display
    font = nil,
    smallFont = nil,
    
    -- Icons and assets
    icons = {},
    weaponIcons = {},
    
    -- References
    weaponSystem = nil,
    
    -- State
    visible = true,
    initialized = false
}

-- Initialize the inventory grid
function InventoryGrid:init(weaponSystem)
    -- Store the weapon system reference
    self.weaponSystem = weaponSystem
    
    -- Load fonts
    self.font = love.graphics.newFont(16)
    self.smallFont = love.graphics.newFont(10)
    
    -- Load weapon icons for each weapon type
    self:loadWeaponIcons()
    
    -- Create default icon as fallback
    self.defaultIcon = self:createDefaultIcon()
    
    -- Mark as initialized
    self.initialized = true
    
    return self
end

-- Draw the inventory grid
function InventoryGrid:draw()
    -- Skip if not initialized or not visible
    if not self.initialized or not self.visible then
        return
    end
    
    -- Skip if no weapon system reference
    if not self.weaponSystem then
        return
    end
    
    -- Store current graphics state
    local r, g, b, a = love.graphics.getColor()
    local font = love.graphics.getFont()
    
    -- Get weapons from weapon system
    local weapons = self.weaponSystem.weapons
    
    -- Draw inventory grid background if debug enabled
    if DEBUG_MASTER and DEBUG_UI then
        love.graphics.setColor(0.1, 0.1, 0.2, 0.7)
        local totalWidth = (self.iconSize + self.padding) * 4 + self.padding
        local totalHeight = self.iconSize + self.padding * 2
        love.graphics.rectangle("fill", self.x - self.padding, self.y - self.padding, 
                                totalWidth, totalHeight)
    end
    
    -- Draw each weapon slot
    for i = 1, 4 do
        local slotX = self.x + (i-1) * (self.iconSize + self.padding)
        local slotY = self.y
        
        -- Draw slot background
        love.graphics.setColor(0.2, 0.2, 0.2, 0.7)
        love.graphics.rectangle("fill", slotX, slotY, self.iconSize, self.iconSize)
        
        -- Draw slot border
        love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
        love.graphics.rectangle("line", slotX, slotY, self.iconSize, self.iconSize)
        
        -- Draw weapon if slot is occupied
        local weapon = weapons[i]
        if weapon then
            -- Get weapon color
            local color = weapon.def.colour or {1, 1, 1, 1}
            
            -- Draw weapon icon with the proper icon for this weapon type
            love.graphics.setColor(1, 1, 1, 1)
            local icon = self.weaponIcons[weapon.def.id] or self.defaultIcon
            love.graphics.draw(icon, slotX, slotY)
            
            -- Draw level badge in bottom right corner
            love.graphics.setColor(0.1, 0.1, 0.1, 0.7)
            love.graphics.rectangle("fill", 
                slotX + self.iconSize - 20, 
                slotY + self.iconSize - 20, 
                20, 20)
            
            -- Draw level number
            love.graphics.setFont(self.font)
            love.graphics.setColor(color[1], color[2], color[3], 1)
            love.graphics.print(tostring(weapon.level), 
                slotX + self.iconSize - 13, 
                slotY + self.iconSize - 20)
            
            -- Draw weapon name only if debug is EXPLICITLY enabled
            if DEBUG_MASTER and DEBUG_UI then
                love.graphics.setFont(self.smallFont)
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.printf(weapon.def.displayName, 
                    slotX, slotY + 5, self.iconSize, "center")
            end
            
            -- Draw cooldown bar
            local cooldownPct = weapon.cooldownTimer / weapon.currentDelay
            if cooldownPct > 0 then
                -- Draw background
                love.graphics.setColor(0.2, 0.2, 0.2, 0.7)
                love.graphics.rectangle("fill", 
                    slotX, 
                    slotY + self.iconSize, 
                    self.iconSize, 
                    self.barHeight)
                
                -- Draw progress (from right to left as cooldown decreases)
                love.graphics.setColor(color[1] * 0.7, color[2] * 0.7, color[3] * 0.7, 0.9)
                love.graphics.rectangle("fill", 
                    slotX, 
                    slotY + self.iconSize, 
                    self.iconSize * (1 - cooldownPct), 
                    self.barHeight)
            end
            
            -- Display cooldown time ONLY if debug is EXPLICITLY enabled
            if DEBUG_MASTER and DEBUG_UI and cooldownPct > 0 then
                love.graphics.setFont(self.smallFont)
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.printf(string.format("%.1fs", weapon.cooldownTimer), 
                    slotX, slotY + self.iconSize - 15, self.iconSize, "center")
            end
        else
            -- Draw empty slot indicator ONLY in explicit debug mode
            if DEBUG_MASTER and DEBUG_UI then
                love.graphics.setFont(self.smallFont)
                love.graphics.setColor(0.7, 0.7, 0.7, 0.5)
                love.graphics.printf("Empty", 
                    slotX, slotY + self.iconSize/2 - 10, self.iconSize, "center")
            end
        end
    end
    
    -- Restore graphics state
    love.graphics.setColor(r, g, b, a)
    love.graphics.setFont(font)
end

-- Update inventory grid (for animations, etc.)
function InventoryGrid:update(dt)
    -- For future animations or updates
end

-- Toggle visibility
function InventoryGrid:toggle()
    self.visible = not self.visible
end

-- Set position
function InventoryGrid:setPosition(x, y)
    self.x = x
    self.y = y
end

-- Create a default icon as fallback
function InventoryGrid:createDefaultIcon()
    local icon = love.graphics.newCanvas(self.iconSize, self.iconSize)
    love.graphics.setCanvas(icon)
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("fill", 4, 4, self.iconSize - 8, self.iconSize - 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", 4, 4, self.iconSize - 8, self.iconSize - 8)
    love.graphics.setCanvas()
    return icon
end

-- Load weapon icons for each weapon type
function InventoryGrid:loadWeaponIcons()
    -- Create icons for each weapon type
    local ItemDefs = require("src.data.item_defs")
    local weapons = ItemDefs.weapons
    
    for _, weaponDef in ipairs(weapons) do
        -- Create a canvas for this weapon's icon
        local icon = love.graphics.newCanvas(self.iconSize, self.iconSize)
        love.graphics.setCanvas(icon)
        love.graphics.clear()
        
        -- Get weapon color
        local color = weaponDef.colour
        
        -- Draw icon based on weapon type/behavior
        if weaponDef.behaviour == "forward" then
            -- Pistol-like icon
            self:drawPistolIcon(icon, color)
        elseif weaponDef.behaviour == "spread" then
            -- Spread weapon icon
            self:drawSpreadIcon(icon, color)
        elseif weaponDef.behaviour == "aoe" then
            -- AOE weapon icon
            self:drawAOEIcon(icon, color)
        elseif weaponDef.behaviour == "drone" then
            -- Drone weapon icon
            self:drawDroneIcon(icon, color)
        end
        
        -- Store the icon
        self.weaponIcons[weaponDef.id] = icon
    end
    
    -- Reset canvas
    love.graphics.setCanvas()
end

-- Draw pistol-like weapon icon
function InventoryGrid:drawPistolIcon(canvas, color)
    -- Background
    love.graphics.setColor(color[1]*0.5, color[2]*0.5, color[3]*0.5, 0.7)
    love.graphics.rectangle("fill", 4, 4, self.iconSize - 8, self.iconSize - 8, 4, 4)
    
    -- Barrel
    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.rectangle("fill", self.iconSize/2 - 2, 8, 4, 20)
    
    -- Handle
    love.graphics.rectangle("fill", self.iconSize/2 - 8, 22, 16, 18)
    
    -- Muzzle flash
    love.graphics.setColor(1, 1, 0.7, 0.8)
    love.graphics.polygon("fill", 
        self.iconSize/2, 5,
        self.iconSize/2 - 6, 12,
        self.iconSize/2, 8,
        self.iconSize/2 + 6, 12
    )
    
    -- Outline
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.rectangle("line", 4, 4, self.iconSize - 8, self.iconSize - 8, 4, 4)
end

-- Draw spread weapon icon
function InventoryGrid:drawSpreadIcon(canvas, color)
    -- Background
    love.graphics.setColor(color[1]*0.5, color[2]*0.5, color[3]*0.5, 0.7)
    love.graphics.rectangle("fill", 4, 4, self.iconSize - 8, self.iconSize - 8, 4, 4)
    
    -- Main body
    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.rectangle("fill", self.iconSize/2 - 8, 15, 16, 25, 3, 3)
    
    -- Multiple barrels
    love.graphics.rectangle("fill", self.iconSize/2 - 12, 8, 4, 12)
    love.graphics.rectangle("fill", self.iconSize/2 - 4, 5, 4, 15)
    love.graphics.rectangle("fill", self.iconSize/2 + 4, 5, 4, 15)
    love.graphics.rectangle("fill", self.iconSize/2 + 8, 8, 4, 12)
    
    -- Muzzle flashes
    love.graphics.setColor(1, 1, 0.7, 0.8)
    love.graphics.circle("fill", self.iconSize/2 - 10, 5, 3)
    love.graphics.circle("fill", self.iconSize/2 - 2, 2, 3)
    love.graphics.circle("fill", self.iconSize/2 + 6, 2, 3)
    love.graphics.circle("fill", self.iconSize/2 + 10, 5, 3)
    
    -- Outline
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.rectangle("line", 4, 4, self.iconSize - 8, self.iconSize - 8, 4, 4)
end

-- Draw AOE weapon icon
function InventoryGrid:drawAOEIcon(canvas, color)
    -- Background
    love.graphics.setColor(color[1]*0.5, color[2]*0.5, color[3]*0.5, 0.7)
    love.graphics.rectangle("fill", 4, 4, self.iconSize - 8, self.iconSize - 8, 4, 4)
    
    -- Bomb shape
    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.circle("fill", self.iconSize/2, self.iconSize/2 + 4, 12)
    
    -- Fuse
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.line(self.iconSize/2, self.iconSize/2 - 8, self.iconSize/2, self.iconSize/2 - 2)
    
    -- Explosion lines
    love.graphics.setColor(1, 0.8, 0.2, 0.8)
    love.graphics.line(self.iconSize/2, 10, self.iconSize/2, 15)
    love.graphics.line(self.iconSize/2 - 8, 12, self.iconSize/2 - 3, 17)
    love.graphics.line(self.iconSize/2 + 8, 12, self.iconSize/2 + 3, 17)
    
    -- Outline
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.rectangle("line", 4, 4, self.iconSize - 8, self.iconSize - 8, 4, 4)
end

-- Draw drone weapon icon
function InventoryGrid:drawDroneIcon(canvas, color)
    -- Background
    love.graphics.setColor(color[1]*0.5, color[2]*0.5, color[3]*0.5, 0.7)
    love.graphics.rectangle("fill", 4, 4, self.iconSize - 8, self.iconSize - 8, 4, 4)
    
    -- Drone body
    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.circle("fill", self.iconSize/2, self.iconSize/2, 10)
    
    -- Drone wings/propellers
    love.graphics.rectangle("fill", self.iconSize/2 - 15, self.iconSize/2 - 2, 12, 4)
    love.graphics.rectangle("fill", self.iconSize/2 + 3, self.iconSize/2 - 2, 12, 4)
    love.graphics.rectangle("fill", self.iconSize/2 - 2, self.iconSize/2 - 15, 4, 12)
    love.graphics.rectangle("fill", self.iconSize/2 - 2, self.iconSize/2 + 3, 4, 12)
    
    -- Center detail
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("fill", self.iconSize/2, self.iconSize/2, 3)
    
    -- Outline
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.rectangle("line", 4, 4, self.iconSize - 8, self.iconSize - 8, 4, 4)
end

-- Return the module
return InventoryGrid
