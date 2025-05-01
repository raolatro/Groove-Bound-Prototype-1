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
    buttons = {},  -- Array of all buttons for navigation
    selectedIndex = 1, -- Currently selected button index
    
    -- Selection indicator
    selectionArrow = {
        width = 16,
        height = 16,
        offset = 10,
        pulseTimer = 0,
        pulseSpeed = 2.5,
        pulseAmount = 4
    },
    
    -- Input state
    lastPadInput = 0, -- Time since last gamepad input (prevents too fast navigation)
    padRepeatDelay = 0.6, -- Initial delay before repeat
    padRepeatRate = 0.15, -- Repeat rate after initial delay
    
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
    
    -- Create buttons array for navigation
    self.buttons = {}
    
    -- Set up restart button
    local restartButton = {
        id = "restart",
        x = self.x + self.grid.cellSize,
        y = self.y + 11 * self.grid.cellSize,
        width = 14 * self.grid.cellSize,
        height = 2 * self.grid.cellSize,
        label = "RESTART",
        isHovered = false,
        isSelected = true, -- Initially selected
        
        -- Helper function to check if point is inside button
        isInside = function(self, px, py)
            return px >= self.x and px <= self.x + self.width and
                   py >= self.y and py <= self.y + self.height
        end,
        
        -- Action to perform when button is activated
        action = function(self, menu)
            menu:triggerRestart()
        end
    }
    
    -- Add button to buttons array
    table.insert(self.buttons, restartButton)
    
    -- Store a reference to the restart button for compatibility
    self.restartButton = restartButton
    
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
    
    -- Update selection arrow animation
    self.selectionArrow.pulseTimer = (self.selectionArrow.pulseTimer + dt * self.selectionArrow.pulseSpeed) % (2 * math.pi)
    
    -- Get mouse position
    local mx, my = love.mouse.getPosition()
    
    -- Check if any button is hovered with mouse
    for i, button in ipairs(self.buttons) do
        button.isHovered = button:isInside(mx, my)
        
        -- Auto-select button on hover
        if button.isHovered then
            self:selectButton(i)
        end
    end
    
    -- Check for gamepad input
    self.lastPadInput = self.lastPadInput + dt
    
    -- Check if a gamepad is connected
    local joysticks = love.joystick.getJoysticks()
    if #joysticks > 0 then
        local joystick = joysticks[1] -- Use the first joystick
        
        -- Read vertical axis (for menu navigation)
        local verticalAxis = joystick:getAxis(2) -- Usually axis 2 is vertical on most gamepads
        
        -- Navigate menu with deadzone to prevent accidental movement
        if math.abs(verticalAxis) > 0.5 and self.lastPadInput > (self.selectedIndex == 0 and self.padRepeatDelay or self.padRepeatRate) then
            -- Reset input timer
            self.lastPadInput = 0
            
            -- Navigate up or down based on axis direction
            if verticalAxis < -0.5 then
                -- Navigate up
                self:selectButton(math.max(1, self.selectedIndex - 1))
            elseif verticalAxis > 0.5 then
                -- Navigate down
                self:selectButton(math.min(#self.buttons, self.selectedIndex + 1))
            end
        end
        
        -- Check for button press using axis buttons (if needed)
        -- This would be a fallback if the gamepadpressed event doesn't work
    end
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
    
    -- Draw buttons
    love.graphics.setFont(self.headingFont)
    
    for i, button in ipairs(self.buttons) do
        -- Button background with hover/selection effect
        if button.isSelected then
            love.graphics.setColor(0.3, 0.7, 0.3, 1.0) -- Green highlight for selection
        elseif button.isHovered then
            love.graphics.setColor(0.3, 0.6, 0.3, 1.0) -- Lighter green for hover
        else
            love.graphics.setColor(0.2, 0.5, 0.2, 1.0) -- Default green
        end
        
        -- Draw button background
        love.graphics.rectangle("fill", 
            button.x, 
            button.y, 
            button.width, 
            button.height,
            6, 6)
        
        -- Draw button border
        love.graphics.setColor(0.8, 1.0, 0.8, 1.0)
        love.graphics.rectangle("line", 
            button.x, 
            button.y, 
            button.width, 
            button.height,
            6, 6)
        
        -- Button text
        love.graphics.setColor(1, 1, 1, 1)
        local btnTextWidth = self.headingFont:getWidth(button.label)
        local btnTextX = button.x + (button.width - btnTextWidth) / 2
        local btnTextY = button.y + (button.height - self.headingFont:getHeight()) / 2
        love.graphics.print(button.label, btnTextX, btnTextY)
        
        -- Draw selection arrow if button is selected
        if button.isSelected then
            -- Calculate position for the arrow
            local arrowX = button.x - self.selectionArrow.offset - self.selectionArrow.width
            local arrowY = button.y + (button.height - self.selectionArrow.height) / 2
            
            -- Add a pulse effect to the arrow
            local pulse = math.sin(self.selectionArrow.pulseTimer) * self.selectionArrow.pulseAmount
            arrowX = arrowX - pulse -- Move the arrow slightly with the pulse
            
            -- Draw the arrow
            love.graphics.setColor(1, 1, 0, 1) -- Yellow arrow
            
            -- Triangle arrow pointing right
            love.graphics.polygon("fill", 
                arrowX, arrowY,
                arrowX, arrowY + self.selectionArrow.height,
                arrowX + self.selectionArrow.width, arrowY + self.selectionArrow.height/2
            )
        end
    end
    
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

-- Select a button by index
function GameOverMenu:selectButton(index)
    -- Validate index bounds
    if index < 1 or index > #self.buttons then
        return
    end
    
    -- Clear all selections
    for i, button in ipairs(self.buttons) do
        button.isSelected = false
    end
    
    -- Select the requested button
    self.buttons[index].isSelected = true
    self.selectedIndex = index
end

-- Handle key press
function GameOverMenu:keypressed(key)
    -- Skip if not visible
    if not self.visible then
        return
    end
    
    -- Navigation with arrow keys
    if key == "up" then
        self:selectButton(math.max(1, self.selectedIndex - 1))
    elseif key == "down" then
        self:selectButton(math.min(#self.buttons, self.selectedIndex + 1))
    end
    
    -- Activate selected button with Enter/Return or Space
    if key == "return" or key == "space" then
        local selectedButton = self.buttons[self.selectedIndex]
        if selectedButton and selectedButton.action then
            selectedButton:action(self)
        end
    end
    
    -- Restart with R key (convenience shortcut)
    if key == "r" then
        self:triggerRestart()
    end
end

-- Handle gamepad button press
function GameOverMenu:gamepadpressed(joystick, button)
    -- Skip if not visible
    if not self.visible then
        return
    end
    
    -- Debug output
    if _G.DEBUG_MASTER and _G.DEBUG_UI then
        print("Gamepad button pressed: " .. button)
    end
    
    -- Navigation with dpad
    if button == "dpup" then
        self:selectButton(math.max(1, self.selectedIndex - 1))
    elseif button == "dpdown" then
        self:selectButton(math.min(#self.buttons, self.selectedIndex + 1))
    end
    
    -- Activate with A button
    if button == "a" then
        local selectedButton = self.buttons[self.selectedIndex]
        if selectedButton and selectedButton.action then
            selectedButton:action(self)
        end
    end
    
    -- Restart on Start button (convenience shortcut)
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
    
    -- Debug output
    if _G.DEBUG_MASTER and _G.DEBUG_UI then
        print("Mouse button pressed at: " .. x .. "," .. y)
    end
    
    -- Check if any button was clicked
    for i, menuButton in ipairs(self.buttons) do
        if button == 1 and menuButton:isInside(x, y) then
            -- Select the button first
            self:selectButton(i)
            
            -- Activate the button
            if menuButton.action then
                menuButton:action(self)
            end
            return
        end
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
