-- xp_bar.lua
-- Displays the player's level, XP, and progress bar

local L = require("lib.loader")
local PATHS = require("config.paths")

-- The XPBar module
local XPBar = {
    -- UI positioning and sizing
    x = 20,
    y = 20,
    width = 200,
    height = 25,
    padding = 2,
    
    -- Fonts
    font = nil,
    smallFont = nil,
    
    -- Colors
    backgroundColor = {0.1, 0.1, 0.2, 0.7},
    borderColor = {0.3, 0.3, 0.5, 0.8},
    fillColor = {0.3, 0.6, 1.0, 0.8},
    textColor = {1, 1, 1, 1},
    
    -- References
    levelUpSystem = nil,
    
    -- State
    visible = true,
    initialized = false
}

-- Initialize the XP bar
function XPBar:init(levelUpSystem)
    -- Store reference to level up system
    self.levelUpSystem = levelUpSystem
    
    -- Load fonts
    self.font = love.graphics.newFont(16)
    self.smallFont = love.graphics.newFont(12)
    
    -- Set position to bottom left by default
    self.x = 20
    self.y = love.graphics.getHeight() - 50
    
    -- Mark as initialized
    self.initialized = true
    
    return self
end

-- Draw the XP bar
function XPBar:draw()
    -- Skip if not initialized or not visible
    if not self.initialized or not self.visible then
        return
    end
    
    -- Skip if no level up system reference or level data
    if not self.levelUpSystem or not self.levelData then
        return
    end
    
    -- Store current graphics state
    local r, g, b, a = love.graphics.getColor()
    local font = love.graphics.getFont()
    
    -- Use cached level info
    local levelInfo = self.levelData
    local progress = levelInfo.progress
    
    -- Draw XP bar background
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)
    
    -- Draw XP progress fill
    love.graphics.setColor(self.fillColor)
    local fillWidth = (self.width - self.padding * 2) * progress
    love.graphics.rectangle("fill", self.x + self.padding, self.y + self.padding, 
                          fillWidth, self.height - self.padding * 2, 3, 3)
    
    -- Draw XP bar border
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 5, 5)
    
    -- Draw level and XP text
    love.graphics.setFont(self.font)
    love.graphics.setColor(self.textColor)
    
    -- Level indicator
    love.graphics.printf("Lvl " .. levelInfo.level, 
                       self.x - 10, self.y - 22, 
                       self.width + 20, "center")
    
    -- XP numbers
    if DEBUG_MASTER and DEBUG_UI then
        love.graphics.setFont(self.smallFont)
        love.graphics.printf(levelInfo.currentXP .. " / " .. levelInfo.nextLevelXP, 
                           self.x, self.y + 5, 
                           self.width, "center")
    end
    
    -- Restore graphics state
    love.graphics.setColor(r, g, b, a)
    love.graphics.setFont(font)
end

-- Update the XP bar (for animations, etc.)
function XPBar:update(dt)
    -- Skip if not initialized
    if not self.initialized or not self.levelUpSystem then
        return
    end
    
    -- Cache the level data for this frame
    self.levelData = self.levelUpSystem:getLevelInfo()
    
    -- Update width based on screen size (responsive UI)
    self.width = math.min(300, love.graphics.getWidth() * 0.3)
    self.x = 20
    self.y = love.graphics.getHeight() - 50
end

-- Toggle visibility
function XPBar:toggle()
    self.visible = not self.visible
end

-- Set position
function XPBar:setPosition(x, y)
    self.x = x
    self.y = y
end

-- Handle resize
function XPBar:resize(w, h)
    -- Adjust y position to stay at bottom left
    self.y = h - 50
end

-- Return the module
return XPBar
