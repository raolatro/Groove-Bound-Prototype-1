-- game_over_menu.lua
-- Game over menu UI component

local L = require("lib.loader")
local Config = require("config.settings")
local PATHS = require("config.paths")
local Event = require("lib.event")
local BlockGrid = require("src.utils.block_grid")

-- The GameOverMenu module
local GameOverMenu = {
    -- UI layout
    x = 0,
    y = 0,
    width = 0,
    height = 0,
    title = "GAME OVER",
    
    -- Grid reference
    grid = nil,
    
    -- UI elements
    statsPanel = nil,
    restartButton = nil,
    
    -- Stats
    stats = nil,
    
    -- Flags
    visible = false,
    initialized = false
}

-- Initialize the game over menu
function GameOverMenu:init(stats)
    -- Initialize grid reference (for positioning)
    self.grid = BlockGrid:init(32) -- Use same grid cell size as pause menu
    
    -- Set up menu dimensions (centered on screen)
    self.width = 16 * self.grid.cellSize -- 16 grid cells wide
    self.height = 14 * self.grid.cellSize -- 14 grid cells tall
    self.x = math.floor((love.graphics.getWidth() - self.width) / 2)
    self.y = math.floor((love.graphics.getHeight() - self.height) / 2)
    
    -- Load fonts
    self.titleFont = love.graphics.newFont(Config.GAME and Config.GAME.DEFAULT_FONT or nil, 36)
    self.headingFont = love.graphics.newFont(Config.GAME and Config.GAME.DEFAULT_FONT or nil, 24)
    self.textFont = love.graphics.newFont(Config.GAME and Config.GAME.DEFAULT_FONT or nil, 18)
    self.smallFont = love.graphics.newFont(Config.GAME and Config.GAME.DEFAULT_FONT or nil, 14)
    
    -- Set up restart button
    self.restartButton = {
        x = self.x + self.grid.cellSize,
        y = self.y + 11 * self.grid.cellSize,
        width = 14 * self.grid.cellSize,
        height = 2 * self.grid.cellSize,
        label = "RESTART",
        isHovered = false,
        
        -- Helper function to check if point is inside button
        isInside = function(self, px, py)
            return px >= self.x and px <= self.x + self.width and
                   py >= self.y and py <= self.y + self.height
        end
    }
    
    -- Set up stats panel
    self.statsPanel = {
        x = self.x + self.grid.cellSize,
        y = self.y + 3 * self.grid.cellSize,
        width = 14 * self.grid.cellSize,
        height = 7 * self.grid.cellSize,
        
        -- Build rows based on stats
        rows = {}
    }
    
    -- Set initial stats
    if stats then
        self:updateStats(stats)
    end
    
    -- Mark as initialized
    self.initialized = true
    self.visible = true
    
    return self
end

-- Format time as mm:ss
local function formatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", minutes, secs)
end

-- Update stats panel with latest data
function GameOverMenu:updateStats(stats)
    self.stats = stats
    
    -- Clear existing rows
    self.statsPanel.rows = {}
    
    -- Add stats rows
    table.insert(self.statsPanel.rows, {
        label = "Final Level",
        value = tostring(stats.finalLevel or 1)
    })
    
    table.insert(self.statsPanel.rows, {
        label = "Total XP",
        value = tostring(stats.totalXP or 0)
    })
    
    table.insert(self.statsPanel.rows, {
        label = "Time Survived",
        value = formatTime(stats.timeAlive or 0)
    })
    
    table.insert(self.statsPanel.rows, {
        label = "Enemies Killed",
        value = tostring(stats.enemiesKilled or 0)
    })
    
    -- Add weapons row
    table.insert(self.statsPanel.rows, {
        label = "Weapons Acquired",
        isIconRow = true,
        items = stats.weaponsAcquired or {}
    })
    
    -- Add passives row
    table.insert(self.statsPanel.rows, {
        label = "Passive Items",
        isIconRow = true,
        items = stats.passiveItems or {}
    })
end

-- Show the menu with updated stats
function GameOverMenu:show(stats)
    self.visible = true
    
    if stats then
        self:updateStats(stats)
    end
end

-- Hide the menu
function GameOverMenu:hide()
    self.visible = false
end

-- Update method to handle input
function GameOverMenu:update(dt)
    -- Skip if not visible
    if not self.visible then
        return
    end
    
    -- Get mouse position
    local mx, my = love.mouse.getPosition()
    
    -- Check if restart button is hovered
    self.restartButton.isHovered = self.restartButton:isInside(mx, my)
end

-- Draw the menu
function GameOverMenu:draw()
    -- Skip if not visible
    if not self.visible then
        return
    end
    
    -- Store current graphics state
    local r, g, b, a = love.graphics.getColor()
    local font = love.graphics.getFont()
    
    -- Draw panel background
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 8, 8)
    
    -- Draw panel border
    love.graphics.setColor(0.3, 0.3, 0.5, 1.0)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 8, 8)
    
    -- Draw title
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(1, 0.3, 0.3, 1.0) -- Red title for Game Over
    local titleWidth = self.titleFont:getWidth(self.title)
    local titleX = self.x + (self.width - titleWidth) / 2
    love.graphics.print(self.title, titleX, self.y + self.grid.cellSize)
    
    -- Draw stats panel
    self:drawStatsPanel()
    
    -- Draw restart button
    love.graphics.setFont(self.headingFont)
    
    if self.restartButton.isHovered then
        love.graphics.setColor(0.3, 0.7, 0.3, 1.0) -- Highlight on hover
    else
        love.graphics.setColor(0.2, 0.5, 0.2, 1.0)
    end
    
    love.graphics.rectangle("fill", 
        self.restartButton.x, 
        self.restartButton.y, 
        self.restartButton.width, 
        self.restartButton.height,
        6, 6)
    
    love.graphics.setColor(0.8, 1.0, 0.8, 1.0)
    love.graphics.rectangle("line", 
        self.restartButton.x, 
        self.restartButton.y, 
        self.restartButton.width, 
        self.restartButton.height,
        6, 6)
    
    -- Button text
    love.graphics.setColor(1, 1, 1, 1)
    local btnTextWidth = self.headingFont:getWidth(self.restartButton.label)
    local btnTextX = self.restartButton.x + (self.restartButton.width - btnTextWidth) / 2
    local btnTextY = self.restartButton.y + (self.restartButton.height - self.headingFont:getHeight()) / 2
    love.graphics.print(self.restartButton.label, btnTextX, btnTextY)
    
    -- Controls help text
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
    local helpText = "Press [ENTER], [R], or gamepad START to restart"
    local helpWidth = self.smallFont:getWidth(helpText)
    love.graphics.print(helpText, 
        self.x + (self.width - helpWidth) / 2, 
        self.restartButton.y + self.restartButton.height + 10)
    
    -- Restore graphics state
    love.graphics.setColor(r, g, b, a)
    love.graphics.setFont(font)
end

-- Draw the stats panel
function GameOverMenu:drawStatsPanel()
    -- Draw panel background
    love.graphics.setColor(0.15, 0.15, 0.2, 0.8)
    love.graphics.rectangle("fill", 
        self.statsPanel.x, 
        self.statsPanel.y, 
        self.statsPanel.width, 
        self.statsPanel.height,
        6, 6)
    
    -- Draw panel border
    love.graphics.setColor(0.3, 0.3, 0.4, 0.9)
    love.graphics.rectangle("line", 
        self.statsPanel.x, 
        self.statsPanel.y, 
        self.statsPanel.width, 
        self.statsPanel.height,
        6, 6)
    
    -- Draw rows
    local rowHeight = self.grid.cellSize
    local rowY = self.statsPanel.y + 10
    
    love.graphics.setFont(self.textFont)
    
    for i, row in ipairs(self.statsPanel.rows) do
        -- Draw row label
        love.graphics.setColor(0.8, 0.8, 1.0, 1.0)
        love.graphics.print(row.label, self.statsPanel.x + 20, rowY)
        
        -- Draw row value or icons
        if row.isIconRow then
            -- Draw icons in a row
            local iconSize = 32
            local iconSpacing = 10
            local iconX = self.statsPanel.x + self.statsPanel.width - 30 - (#row.items * (iconSize + iconSpacing))
            
            for j, item in ipairs(row.items) do
                -- Draw icon background
                love.graphics.setColor(0.2, 0.2, 0.3, 1.0)
                love.graphics.rectangle("fill", iconX, rowY - 5, iconSize, iconSize, 4, 4)
                
                -- Draw icon border (use item color if available)
                local color = item.color or {0.5, 0.5, 0.7, 1.0}
                love.graphics.setColor(color[1], color[2], color[3], 1.0)
                love.graphics.rectangle("line", iconX, rowY - 5, iconSize, iconSize, 4, 4)
                
                -- Draw item name or ID as text
                love.graphics.setFont(self.smallFont)
                love.graphics.setColor(1, 1, 1, 1)
                local shortName = item.name and string.sub(item.name, 1, 3) or item.id or "?"
                local nameWidth = self.smallFont:getWidth(shortName)
                love.graphics.print(shortName, 
                    iconX + (iconSize - nameWidth) / 2, 
                    rowY + 5)
                
                -- Draw level if available
                if item.level then
                    local levelText = "L" .. item.level
                    local levelWidth = self.smallFont:getWidth(levelText)
                    love.graphics.setColor(1, 1, 0, 1)
                    love.graphics.print(levelText, 
                        iconX + (iconSize - levelWidth) / 2, 
                        rowY + 20)
                end
                
                -- Move to next icon position
                iconX = iconX + iconSize + iconSpacing
            end
        else
            -- Draw regular value
            love.graphics.setColor(1, 1, 1, 1)
            local valueWidth = self.textFont:getWidth(row.value)
            love.graphics.print(row.value, 
                self.statsPanel.x + self.statsPanel.width - 20 - valueWidth, 
                rowY)
        end
        
        -- Move to next row
        rowY = rowY + rowHeight
    end
end

-- Handle key press
function GameOverMenu:keypressed(key)
    -- Skip if not visible
    if not self.visible then
        return
    end
    
    -- Restart on Enter or R key
    if key == "return" or key == "r" then
        self:triggerRestart()
    end
end

-- Handle gamepad button press
function GameOverMenu:gamepadpressed(joystick, button)
    -- Skip if not visible
    if not self.visible then
        return
    end
    
    -- Restart on Start button
    if button == "start" then
        self:triggerRestart()
    end
end

-- Handle mouse press
function GameOverMenu:mousepressed(x, y, button)
    -- Skip if not visible
    if not self.visible then
        return
    end
    
    -- Check if restart button was clicked
    if button == 1 and self.restartButton:isInside(x, y) then
        self:triggerRestart()
    end
end

-- Trigger restart
function GameOverMenu:triggerRestart()
    -- Dispatch restart event
    Event.dispatch("GAME_RESTART", {})
end

-- Resize handler
function GameOverMenu:resize(w, h)
    -- Update menu position to stay centered
    self.x = math.floor((w - self.width) / 2)
    self.y = math.floor((h - self.height) / 2)
    
    -- Update button position
    self.restartButton.x = self.x + self.grid.cellSize
    self.restartButton.y = self.y + 11 * self.grid.cellSize
    
    -- Update stats panel position
    self.statsPanel.x = self.x + self.grid.cellSize
    self.statsPanel.y = self.y + 3 * self.grid.cellSize
end

-- Return the module
return GameOverMenu
