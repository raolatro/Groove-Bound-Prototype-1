-- level_up_panel.lua
-- Handles the UI for level-up choices

local L = require("lib.loader")
local PATHS = require("config.paths")
local UI = require("config.ui")

-- The LevelUpPanel module
local LevelUpPanel = {
    -- UI positioning and sizing
    x = 0,
    y = 0,
    width = 800,
    height = 400,
    padding = 20,
    cardWidth = 220,
    cardHeight = 300,
    
    -- Fonts
    titleFont = nil,
    headerFont = nil,
    textFont = nil,
    
    -- Animation and state
    visible = false,
    fadeInTime = 0.3,
    currentFade = 0,
    selectedCard = nil,
    
    -- Level-up data
    newLevel = 1,
    choices = {},
    
    -- References
    levelUpSystem = nil,
    
    -- Flag for whether panel has been initialized
    initialized = false
}

-- Initialize the level-up panel
function LevelUpPanel:init(levelUpSystem)
    -- Store references
    self.levelUpSystem = levelUpSystem
    
    -- Load fonts
    self.titleFont = love.graphics.newFont(24)
    self.headerFont = love.graphics.newFont(18)
    self.textFont = love.graphics.newFont(14)
    
    -- Center in screen
    self.x = (love.graphics.getWidth() - self.width) / 2
    self.y = (love.graphics.getHeight() - self.height) / 2
    
    -- Register callbacks
    if levelUpSystem then
        levelUpSystem.onLevelUp = function(level, choices)
            self:show(level, choices)
        end
        
        levelUpSystem.onChoiceSelected = function(choice, result, message)
            self:hide()
        end
    end
    
    -- Mark as initialized
    self.initialized = true
    
    return self
end

-- Show the level-up panel
function LevelUpPanel:show(level, choices)
    -- Set data
    self.newLevel = level
    self.choices = choices
    
    -- Show panel with fade-in
    self.visible = true
    self.currentFade = 0
    self.selectedCard = nil
    
    -- Pause the game (would be implemented in game state)
    -- Game:setPaused(true)
end

-- Hide the level-up panel
function LevelUpPanel:hide()
    self.visible = false
    
    -- Unpause the game (would be implemented in game state)
    -- Game:setPaused(false)
end

-- Update the level-up panel
function LevelUpPanel:update(dt)
    -- Skip if not visible
    if not self.visible then
        return
    end
    
    -- Update fade-in
    if self.currentFade < 1 then
        self.currentFade = math.min(1, self.currentFade + dt / self.fadeInTime)
    end
    
    -- Handle input (mouse hovering, clicking, etc.)
    self:processInput()
end

-- Process panel input
function LevelUpPanel:processInput()
    -- Get mouse position
    local mx, my = love.mouse.getPosition()
    
    -- Check if mouse is over any card
    local hoverCard = nil
    
    for i, choice in ipairs(self.choices) do
        local cardX = self.x + self.padding + (i-1) * (self.cardWidth + self.padding)
        local cardY = self.y + self.padding + 50 -- Extra space for title
        
        -- Check if mouse is inside card bounds
        if mx >= cardX and mx <= cardX + self.cardWidth and
           my >= cardY and my <= cardY + self.cardHeight then
            hoverCard = i
            break
        end
    end
    
    -- Store hover state
    self.hoverCard = hoverCard
    
    -- Process click
    if love.mouse.isDown(1) and hoverCard and not self.selectedCard then
        self.selectedCard = hoverCard
        
        -- Apply the choice
        if self.levelUpSystem then
            self.levelUpSystem:applyChoice(hoverCard)
        end
    end
end

-- Draw the level-up panel
function LevelUpPanel:draw()
    -- Skip if not visible or not initialized
    if not self.visible or not self.initialized then
        return
    end
    
    -- Store current graphics state
    local r, g, b, a = love.graphics.getColor()
    local font = love.graphics.getFont()
    
    -- Apply fade
    local alpha = self.currentFade
    
    -- Draw panel background
    love.graphics.setColor(0, 0, 0, 0.85 * alpha)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw panel container
    love.graphics.setColor(0.15, 0.15, 0.25, 0.9 * alpha)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 10, 10)
    love.graphics.setColor(0.3, 0.3, 0.6, 0.9 * alpha)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 10, 10)
    
    -- Draw title
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.printf(
        "Level Up! You reached level " .. self.newLevel,
        self.x,
        self.y + self.padding,
        self.width,
        "center"
    )
    
    -- Draw instruction
    love.graphics.setFont(self.textFont)
    love.graphics.setColor(0.8, 0.8, 1, alpha)
    love.graphics.printf(
        "Choose an upgrade:",
        self.x,
        self.y + self.padding + 30,
        self.width,
        "center"
    )
    
    -- Draw choice cards
    for i, choice in ipairs(self.choices) do
        -- Calculate card position
        local cardX = self.x + self.padding + (i-1) * (self.cardWidth + self.padding)
        local cardY = self.y + self.padding + 60 -- Extra space for title
        
        -- Determine if this card is hovered or selected
        local isHovered = (self.hoverCard == i)
        local isSelected = (self.selectedCard == i)
        
        -- Draw card background with appropriate color
        local cardColor = choice.colour or {1, 1, 1, 1}
        
        -- Base color and adjustments for hover/select
        local bgColor = {0.2, 0.2, 0.3, 0.9 * alpha}
        local borderColor = {cardColor[1], cardColor[2], cardColor[3], 0.8 * alpha}
        
        if isHovered then
            bgColor = {0.25, 0.25, 0.35, 0.9 * alpha}
            borderColor = {cardColor[1] * 1.2, cardColor[2] * 1.2, cardColor[3] * 1.2, alpha}
        end
        
        if isSelected then
            bgColor = {0.3, 0.3, 0.4, 0.9 * alpha}
            borderColor = {cardColor[1] * 1.5, cardColor[2] * 1.5, cardColor[3] * 1.5, alpha}
        end
        
        -- Draw card background
        love.graphics.setColor(bgColor)
        love.graphics.rectangle("fill", cardX, cardY, self.cardWidth, self.cardHeight, 5, 5)
        
        -- Draw card border
        love.graphics.setColor(borderColor)
        love.graphics.rectangle("line", cardX, cardY, self.cardWidth, self.cardHeight, 5, 5)
        
        -- Draw card content
        -- Card header
        love.graphics.setFont(self.headerFont)
        love.graphics.setColor(cardColor[1], cardColor[2], cardColor[3], alpha)
        
        local headerText = choice.type:gsub("_", " "):gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
        love.graphics.printf(
            headerText,
            cardX + 10,
            cardY + 15,
            self.cardWidth - 20,
            "center"
        )
        
        -- Card name
        love.graphics.setFont(self.textFont)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.printf(
            choice.name,
            cardX + 10,
            cardY + 45,
            self.cardWidth - 20,
            "center"
        )
        
        -- Card level (if applicable)
        if choice.level then
            love.graphics.printf(
                "Level " .. choice.level .. " → " .. (choice.level + 1),
                cardX + 10,
                cardY + 70,
                self.cardWidth - 20,
                "center"
            )
        end
        
        -- Card description
        love.graphics.setColor(0.8, 0.8, 0.8, alpha)
        love.graphics.printf(
            choice.description,
            cardX + 10,
            cardY + 100,
            self.cardWidth - 20,
            "center"
        )
        
        -- Draw debug info if enabled
        if DEBUG_MASTER and DEBUG_UI then
            love.graphics.setColor(1, 0, 0, 0.7 * alpha)
            love.graphics.printf(
                "ID: " .. choice.id .. "\nType: " .. choice.type,
                cardX + 10,
                cardY + self.cardHeight - 40,
                self.cardWidth - 20,
                "left"
            )
        end
    end
    
    -- Restore graphics state
    love.graphics.setColor(r, g, b, a)
    love.graphics.setFont(font)
end

-- Handle resize
function LevelUpPanel:resize(w, h)
    -- Re-center in screen
    self.x = (w - self.width) / 2
    self.y = (h - self.height) / 2
end

-- Return the module
return LevelUpPanel
