-- level_up_shop.lua
-- Handles the level-up shop UI, card display, and selection logic

local L = require("lib.loader")
local BlockGrid = require("src.ui.block_grid")
local Rarity = require("src.data.rarity")
local ItemDefs = require("src.data.item_defs")
local UI = require("config.ui")
local Config = require("config.settings")
local Event = require("lib.event")
local Debug = require("src.debug")

-- Local shorthand
local TUNING = Config.TUNING
local DEV = Config.DEV

-- The LevelUpShop module
local LevelUpShop = {
    -- Shop state
    isOpen = false,
    selectedIndex = 1,        -- Currently selected card/button (1-3 cards, 4=reroll, 5=skip)
    cards = {},               -- Array of card data
    blurCanvas = nil,         -- Canvas for background blur
    blurShader = nil,         -- Gaussian blur shader
    transitionAlpha = 0,      -- Alpha for fade in/out transitions
    
    -- References
    player = nil,             -- Reference to player
    levelUpSystem = nil,      -- Reference to level-up system
    weaponSystem = nil,       -- Reference to weapon system
    passiveSystem = nil,      -- Reference to passive system
    
    -- UI layout
    grid = nil,               -- BlockGrid for layout
    cardWidth = 0,            -- Width of each card
    cardHeight = 0,           -- Height of each card
    
    -- No flash animation state anymore (removed)
}

-- Initialize the level-up shop
function LevelUpShop:init(player, levelUpSystem)
    -- Store references
    self.player = player
    self.levelUpSystem = levelUpSystem
    
    -- Get systems from the levelUpSystem if available
    if levelUpSystem then
        self.weaponSystem = levelUpSystem.weaponSystem
        self.passiveSystem = levelUpSystem.passiveSystem
        
        if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
            if self.weaponSystem then
                Debug.log("LevelUpShop: Received weapon system reference")
            else
                Debug.log("WARNING: LevelUpShop initialized without weapon system reference")
            end
        end
    end
    
    -- Create our own grid instance with metrics
    self.grid = {
        base = UI.GRID.base,
        blocksX = UI.GRID.blocksX,
        blocksY = UI.GRID.blocksY
    }
    
    -- Add methods to our grid instance
    function self.grid:getWidthInPixels(blocks)
        return blocks * self.base
    end
    
    function self.grid:getHeightInPixels(blocks)
        return blocks * self.base
    end
    
    -- Set card dimensions (4 blocks wide, 6 blocks tall)
    self.cardWidth = self.grid:getWidthInPixels(4)
    self.cardHeight = self.grid:getHeightInPixels(6)
    
    -- Use a simple approach for now - no shader or complex canvas operations
    -- This simplifies implementation and avoids potential compatibility issues
    self.useSimpleBackground = true
    
    if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
        Debug.log("LevelUpShop: Initialized with simple background rendering")
    end
    
    return self
end

-- These functions have been removed as we no longer need the flash effect
-- Shop will be opened directly from LevelUpSystem:triggerLevelUp

-- Open the shop with items for selection
function LevelUpShop:open(player)
    -- Ensure we have player reference
    if not player then
        if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
            Debug.log("ERROR: LevelUpShop:open called without player reference")
        end
        return
    end
    
    -- Store reference to player
    self.player = player
    
    -- Reset state
    self.isOpen = true
    self.selectedIndex = 1
    self.cards = {}
    self.transitionAlpha = 1.0 -- Start fully visible, no transition
    
    if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
        Debug.log("LevelUpShop:open - Opening shop with isOpen set to: " .. tostring(self.isOpen))
    end
    
    -- Build candidate pool of items
    local candidatePool = self:buildCandidatePool()
    
    -- Calculate weights based on player luck
    local weights = Rarity.computeWeights(player.luck)
    
    -- Pick items based on rarity
    while #self.cards < TUNING.SHOP.NUM_CARDS and #candidatePool > 0 do
        -- Pick a tier
        local tier = Rarity.pickTier(weights)
        
        -- Find candidates of this tier
        local tierCandidates = {}
        for i, item in ipairs(candidatePool) do
            if item.rarity == tier then
                table.insert(tierCandidates, {item = item, index = i})
            end
        end
        
        -- If we have candidates of this tier, pick one randomly
        if #tierCandidates > 0 then
            local selection = tierCandidates[love.math.random(#tierCandidates)]
            local item = selection.item
            
            -- Remove from pool to prevent duplicates
            table.remove(candidatePool, selection.index)
            
            -- Create card data
            local card = self:buildCard(item)
            table.insert(self.cards, card)
        end
    end
    
    -- If we don't have enough cards, fill with random items
    while #self.cards < TUNING.SHOP.NUM_CARDS and #candidatePool > 0 do
        -- Pick a random item
        local index = love.math.random(#candidatePool)
        local item = candidatePool[index]
        
        -- Remove from pool
        table.remove(candidatePool, index)
        
        -- Create card data
        local card = self:buildCard(item)
        table.insert(self.cards, card)
    end
    
    -- Debug output
    if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
        Debug.log("LevelUpShop: Opened shop with " .. #self.cards .. " cards")
    end
    
    -- Capture the current screen for blur background
    self:captureBackground()
    
    return self
end

-- Build the pool of candidate items that can be offered
function LevelUpShop:buildCandidatePool()
    local pool = {}
    
    -- Get player's current items and levels
    local playerItems = {}
    
    -- Add weapons
    if self.player.weaponSystem then
        for _, weapon in ipairs(self.player.weaponSystem.weapons) do
            playerItems[weapon.id] = weapon.level
        end
    end
    
    -- Add passives
    if self.player.passiveSystem then
        for _, passive in ipairs(self.player.passiveSystem.passives) do
            playerItems[passive.id] = passive.level
        end
    end
    
    -- Check all weapons
    for _, itemDef in ipairs(ItemDefs.weapons) do
        local currentLevel = playerItems[itemDef.id] or 0
        local maxLevel = itemDef.maxLevel or 5
        
        -- Add if not at max level
        if currentLevel < maxLevel then
            table.insert(pool, {
                id = itemDef.id,
                type = "weapon",
                displayName = itemDef.displayName,
                description = itemDef.description or "",
                icon = nil, -- Icons not implemented in current item_defs
                color = itemDef.colour, -- Note: using 'colour' not 'color' to match item_defs.lua
                rarity = itemDef.rarity or "common",
                currentLevel = currentLevel,
                maxLevel = maxLevel
            })
        end
    end
    
    -- Check all passives
    for _, itemDef in ipairs(ItemDefs.passives) do
        local currentLevel = playerItems[itemDef.id] or 0
        local maxLevel = itemDef.maxLevel or 5
        
        -- Add if not at max level
        if currentLevel < maxLevel then
            table.insert(pool, {
                id = itemDef.id,
                type = "passive",
                displayName = itemDef.displayName,
                description = itemDef.description or "",
                icon = nil, -- Icons not implemented in current item_defs
                color = itemDef.colour, -- Note: using 'colour' not 'color' to match item_defs.lua
                rarity = itemDef.rarity or "common",
                currentLevel = currentLevel,
                maxLevel = maxLevel
            })
        end
    end
    
    if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
        Debug.log("LevelUpShop: Built candidate pool with " .. #pool .. " items")
        for i, item in ipairs(pool) do
            Debug.log(string.format("%d. %s (%s, level %d/%d)", i, item.displayName, item.rarity, item.currentLevel, item.maxLevel))
        end
    end
    
    return pool
end

-- Build a card data structure for an item
function LevelUpShop:buildCard(item)
    local isNew = (item.currentLevel == 0)
    local nextLevel = item.currentLevel + 1
    
    -- Build effect summary for this level
    local summaryLine = ""
    if not isNew then
        -- Use levelUps field from item_defs.lua format
        if item.type == "weapon" then
            -- For weapons, levelUps is key-value pairs
            local levelEffect = {}
            for stat, value in pairs(ItemDefs.weapons[self:findItemIndexById(ItemDefs.weapons, item.id)].levelUps or {}) do
                -- Parse the value string, e.g., "+5%" or "+1"
                local val = tonumber(value:match("[%+%-]?(%d+)")) or 0
                local isPercent = value:find("%%")
                
                if isPercent then
                    val = val / 100 -- Convert to decimal for percentage
                end
                
                levelEffect[stat] = isPercent and val or val
            end
            summaryLine = Rarity.buildEffectSummary(levelEffect)
        elseif item.type == "passive" then
            -- For passives, effects is indexed by level
            local levelEffect = ItemDefs.passives[self:findItemIndexById(ItemDefs.passives, item.id)].effects[nextLevel]
            if levelEffect then
                summaryLine = Rarity.buildEffectSummary(levelEffect)
            end
        end
    end
    
    -- Return card data
    return {
        id = item.id,
        type = item.type,
        displayName = item.displayName,
        description = item.description,
        icon = item.icon,
        color = item.color,
        rarity = item.rarity,
        currentLevel = item.currentLevel,
        nextLevel = nextLevel,
        isNew = isNew,
        summaryLine = summaryLine
    }
end

-- Helper function to find an item's index in a table by its ID
function LevelUpShop:findItemIndexById(itemTable, itemId)
    for i, item in ipairs(itemTable) do
        if item.id == itemId then
            return i
        end
    end
    return nil
end

-- Capture the current screen for background (simplified)
function LevelUpShop:captureBackground()
    -- With the simplified approach, we don't need to capture anything
    -- This method is kept for API compatibility
    if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
        Debug.log("LevelUpShop: Using simplified background approach")
    end
end

-- Draw the shop UI
function LevelUpShop:draw()
    if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
        -- Debug.log("LevelUpShop:draw - isOpen: " .. tostring(self.isOpen))
    end
    
    -- If the shop isn't explicitly open, exit early
    if not self.isOpen then
        if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
            Debug.log("LevelUpShop:draw - Skipping draw, shop not open")
        end
        return
    end
    
    -- Safety check for player reference
    if not self.player then
        if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
            Debug.log("ERROR: LevelUpShop:draw - Missing player reference")
        end
        
        -- Try to continue anyway to maintain flow
        self:drawBackground()
        return
    end
    
    -- Draw darkened background to ensure shop stands out against game
    -- Use a more opaque background (0.95 opacity)
    love.graphics.setColor(0, 0, 0, 0.95)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw shop title
    self:drawTitle()
    
    -- Draw cards
    self:drawCards()
    
    -- Draw buttons
    self:drawButtons()
    
    -- Debug info
    if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Level-Up Shop (Selected: " .. self.selectedIndex .. ")", 10, 10)
        
        -- Add safety checks for player properties
        local playerLuck = self.player.luck or 0
        local playerCoins = self.player.coins or 0
        
        love.graphics.print("Player Luck: " .. playerLuck, 10, 30)
        love.graphics.print("Player Coins: " .. playerCoins, 10, 50)
    end
end

-- Draw the shop title
function LevelUpShop:drawTitle()
    -- Safety check - make sure we have player reference
    if not self.player then
        if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
            Debug.log("ERROR: LevelUpShop:drawTitle - No player reference")
        end
        return
    end
    
    local screenWidth = love.graphics.getWidth()
    local font = love.graphics.newFont(32)
    
    -- Save current font
    local currentFont = love.graphics.getFont()
    
    -- Set title font and color
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw the level-up title (with safety check for player.level)
    local playerLevel = self.player.level or 1
    local title = "Level Up! You reached level " .. playerLevel
    local subtitle = "Choose an upgrade:"
    
    -- Draw title and subtitle
    love.graphics.printf(title, 0, love.graphics.getHeight() * 0.15, screenWidth, "center")
    love.graphics.printf(subtitle, 0, love.graphics.getHeight() * 0.2, screenWidth, "center")
    
    -- Restore original font
    love.graphics.setFont(currentFont)
end

-- Draw the background (simplified approach)
function LevelUpShop:drawBackground()
    -- Draw a fully opaque black overlay with a slight transparency
    -- This ensures the shop is clearly visible against the game background
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
    
    if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
        Debug.log("LevelUpShop:drawBackground - Drawing overlay")
    end
end

-- Draw the item cards
function LevelUpShop:drawCards()
    -- Calculate card positions
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local cardSpacing = self.grid:getWidthInPixels(1)
    local totalWidth = (#self.cards * self.cardWidth) + ((#self.cards - 1) * cardSpacing)
    local startX = (screenWidth - totalWidth) / 2
    local startY = screenHeight * 0.25
    
    -- Draw each card
    for i, card in ipairs(self.cards) do
        local x = startX + (i-1) * (self.cardWidth + cardSpacing)
        local y = startY
        
        -- Highlight selected card
        local isSelected = (self.selectedIndex == i)
        self:drawCard(card, x, y, isSelected)
    end
end

-- Draw a single card
function LevelUpShop:drawCard(card, x, y, isSelected)
    -- Get rarity color
    local rarityColor = Rarity.colors[card.rarity] or {0.7, 0.7, 0.7, 1.0}
    
    -- Border thickness adjustment for selected cards
    local borderThickness = isSelected and 4 or 2
    
    -- Draw card background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", x, y, self.cardWidth, self.cardHeight, 10, 10)
    
    -- Draw rarity border
    love.graphics.setColor(rarityColor)
    love.graphics.setLineWidth(borderThickness)
    love.graphics.rectangle("line", x, y, self.cardWidth, self.cardHeight, 10, 10)
    
    -- Draw selection indicator if selected
    if isSelected then
        -- Draw pulsing arrow on the left side
        local arrowSize = self.grid:getWidthInPixels(1)
        local pulseScale = 0.8 + math.sin(love.timer.getTime() * 5) * 0.2
        local arrowX = x - arrowSize * 1.5
        local arrowY = y + self.cardHeight / 2
        
        love.graphics.setColor(1, 0.8, 0.2, 1.0) -- Yellow pulsing arrow
        love.graphics.polygon("fill", 
            arrowX, arrowY,
            arrowX - arrowSize * pulseScale, arrowY - arrowSize * 0.5 * pulseScale,
            arrowX - arrowSize * pulseScale, arrowY + arrowSize * 0.5 * pulseScale
        )
    end
    
    -- Draw item name
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.printf(card.displayName, x + 10, y + 20, self.cardWidth - 20, "center")
    
    -- Draw item icon placeholder
    local iconSize = self.grid:getWidthInPixels(2)
    local iconX = x + (self.cardWidth - iconSize) / 2
    local iconY = y + self.grid:getHeightInPixels(1.5)
    
    -- Draw colored icon background
    local itemColor = card.color or {1, 1, 1, 1}
    love.graphics.setColor(itemColor)
    love.graphics.rectangle("fill", iconX, iconY, iconSize, iconSize, 5, 5)
    
    -- Draw actual icon if available
    if card.icon then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(card.icon, iconX, iconY, 0, iconSize / card.icon:getWidth(), iconSize / card.icon:getHeight())
    end
    
    -- Draw NEW tag or level indicator
    local tagY = y + self.grid:getHeightInPixels(3.7)
    local tagWidth = self.grid:getWidthInPixels(2)
    local tagHeight = self.grid:getHeightInPixels(0.6)
    local tagX = x + (self.cardWidth - tagWidth) / 2
    
    if card.isNew then
        -- Draw NEW tag with green background
        love.graphics.setColor(0.2, 0.8, 0.2, 1.0) -- Green
        love.graphics.rectangle("fill", tagX, tagY, tagWidth, tagHeight, 5, 5)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.printf("NEW", tagX, tagY + 5, tagWidth, "center")
    else
        -- Draw level indicator with item color
        love.graphics.setColor(itemColor)
        love.graphics.rectangle("fill", tagX, tagY, tagWidth, tagHeight, 5, 5)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.printf("Lvl " .. card.nextLevel, tagX, tagY + 5, tagWidth, "center")
    end
    
    -- Draw effect summary line
    if card.summaryLine and card.summaryLine ~= "" then
        love.graphics.setColor(0.9, 0.9, 0.9, 1.0)
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.printf(card.summaryLine, x + 10, tagY + tagHeight + 10, self.cardWidth - 20, "center")
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw the buttons (Reroll, Skip)
function LevelUpShop:drawButtons()
    -- Constants for button layout
    local buttonHeight = self.grid:getHeightInPixels(1)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Button positions
    local rerollWidth = self.grid:getWidthInPixels(4)
    local skipWidth = self.grid:getWidthInPixels(3)
    local spacing = self.grid:getWidthInPixels(1)
    local totalWidth = rerollWidth + spacing + skipWidth
    local startX = (screenWidth - totalWidth) / 2
    local buttonY = screenHeight * 0.65
    
    -- Draw REROLL button
    local rerollX = startX
    local isRerollSelected = (self.selectedIndex == #self.cards + 1)
    
    if isRerollSelected then
        -- Draw selection indicator
        local arrowSize = self.grid:getWidthInPixels(0.8)
        local pulseScale = 0.8 + math.sin(love.timer.getTime() * 5) * 0.2
        local arrowX = rerollX - arrowSize * 1.5
        local arrowY = buttonY + buttonHeight / 2
        
        love.graphics.setColor(1, 0.8, 0.2, 1.0) -- Yellow pulsing arrow
        love.graphics.polygon("fill", 
            arrowX, arrowY,
            arrowX - arrowSize * pulseScale, arrowY - arrowSize * 0.5 * pulseScale,
            arrowX - arrowSize * pulseScale, arrowY + arrowSize * 0.5 * pulseScale
        )
    end
    
    -- Button background
    love.graphics.setColor(0.2, 0.4, 0.8, isRerollSelected and 1.0 or 0.7)
    love.graphics.rectangle("fill", rerollX, buttonY, rerollWidth, buttonHeight, 5, 5)
    
    -- Button text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(16))
    local rerollText = "REROLL"
    if TUNING.SHOP.REROLL_COST > 0 then
        rerollText = rerollText .. " (" .. TUNING.SHOP.REROLL_COST .. " coins)"
    end
    love.graphics.printf(rerollText, rerollX, buttonY + (buttonHeight - 16) / 2, rerollWidth, "center")
    
    -- Draw SKIP button
    local skipX = rerollX + rerollWidth + spacing
    local isSkipSelected = (self.selectedIndex == #self.cards + 2)
    
    if isSkipSelected then
        -- Draw selection indicator
        local arrowSize = self.grid:getWidthInPixels(0.8)
        local pulseScale = 0.8 + math.sin(love.timer.getTime() * 5) * 0.2
        local arrowX = skipX - arrowSize * 1.5
        local arrowY = buttonY + buttonHeight / 2
        
        love.graphics.setColor(1, 0.8, 0.2, 1.0) -- Yellow pulsing arrow
        love.graphics.polygon("fill", 
            arrowX, arrowY,
            arrowX - arrowSize * pulseScale, arrowY - arrowSize * 0.5 * pulseScale,
            arrowX - arrowSize * pulseScale, arrowY + arrowSize * 0.5 * pulseScale
        )
    end
    
    -- Button background
    love.graphics.setColor(0.5, 0.5, 0.5, isSkipSelected and 1.0 or 0.7)
    love.graphics.rectangle("fill", skipX, buttonY, skipWidth, buttonHeight, 5, 5)
    
    -- Button text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("SKIP", skipX, buttonY + (buttonHeight - 16) / 2, skipWidth, "center")
end

-- Update the shop UI and handle input
function LevelUpShop:update(dt)
    -- Handle delayed opening if set
    if self.pendingOpen then
        self.delayTimer = (self.delayTimer or 0) + dt
        
        -- When delay is over, open the shop
        if self.delayTimer >= (self.openDelay or 0) then
            self.pendingOpen = false
            self:open(self.player)
            
            if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
                Debug.log("LevelUpShop:update - Opening shop after pause delay")
            end
        end
    end
    
    -- Do nothing more if not fully open
    if not self.isOpen then
        return
    end

    -- Used for animations or other continuous updates while shop is open
    -- Update transition alpha
    self.transitionAlpha = math.min(1, self.transitionAlpha + dt * 3)
end

-- Handle keyboard input
function LevelUpShop:keypressed(key)
    if not self.isOpen then return false end
    
    if key == "left" or key == "a" then
        self:selectPrevious()
        return true
    elseif key == "right" or key == "d" then
        self:selectNext()
        return true
    elseif key == "return" or key == "space" then
        self:selectCurrent()
        return true
    elseif key == "escape" then
        self:skip()
        return true
    end
    
    return false
end

-- Handle gamepad input
function LevelUpShop:gamepadpressed(gamepad, button)
    if not self.isOpen then return false end
    
    if button == "dpleft" or button == "leftshoulder" then
        self:selectPrevious()
        return true
    elseif button == "dpright" or button == "rightshoulder" then
        self:selectNext()
        return true
    elseif button == "a" or button == "dpdown" then
        self:selectCurrent()
        return true
    elseif button == "b" then
        self:skip()
        return true
    end
    
    return false
end

-- Handle mouse click
function LevelUpShop:mousepressed(x, y, button)
    -- Only process clicks when the shop is open and fully initialized
    if not self.isOpen or button ~= 1 then return false end
    
    -- Additional safety check - ensure we have cards to show 
    if not self.cards or #self.cards == 0 then 
        if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
            Debug.log("LevelUpShop:mousepressed - No cards available, ignoring click")
        end
        return false 
    end
    
    -- Check if a card was clicked
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local cardSpacing = self.grid:getWidthInPixels(1)
    local totalWidth = (#self.cards * self.cardWidth) + ((#self.cards - 1) * cardSpacing)
    local startX = (screenWidth - totalWidth) / 2
    local startY = screenHeight * 0.25
    
    for i, _ in ipairs(self.cards) do
        local cardX = startX + (i-1) * (self.cardWidth + cardSpacing)
        local cardY = startY
        
        if x >= cardX and x <= cardX + self.cardWidth and
           y >= cardY and y <= cardY + self.cardHeight then
            self.selectedIndex = i
            self:selectCurrent()
            return true
        end
    end
    
    -- Check if reroll button was clicked
    local buttonHeight = self.grid:getHeightInPixels(1)
    local rerollWidth = self.grid:getWidthInPixels(4)
    local skipWidth = self.grid:getWidthInPixels(3)
    local spacing = self.grid:getWidthInPixels(1)
    local totalButtonWidth = rerollWidth + spacing + skipWidth
    local buttonStartX = (screenWidth - totalButtonWidth) / 2
    local buttonY = screenHeight * 0.65
    
    -- Reroll button
    local rerollX = buttonStartX
    if x >= rerollX and x <= rerollX + rerollWidth and
       y >= buttonY and y <= buttonY + buttonHeight then
        self.selectedIndex = #self.cards + 1
        self:selectCurrent()
        return true
    end
    
    -- Skip button
    local skipX = rerollX + rerollWidth + spacing
    if x >= skipX and x <= skipX + skipWidth and
       y >= buttonY and y <= buttonY + buttonHeight then
        self.selectedIndex = #self.cards + 2
        self:selectCurrent()
        return true
    end
    
    return false
end

-- Select the previous item
function LevelUpShop:selectPrevious()
    self.selectedIndex = self.selectedIndex - 1
    if self.selectedIndex < 1 then
        self.selectedIndex = #self.cards + 2 -- Wrap to the Skip button
    end
end

-- Select the next item
function LevelUpShop:selectNext()
    self.selectedIndex = self.selectedIndex + 1
    if self.selectedIndex > #self.cards + 2 then
        self.selectedIndex = 1 -- Wrap to the first card
    end
end

-- Select the current item
function LevelUpShop:selectCurrent()
    if self.selectedIndex <= #self.cards then
        -- Card selected
        self:selectCard(self.selectedIndex)
    elseif self.selectedIndex == #self.cards + 1 then
        -- Reroll button
        self:reroll()
    else
        -- Skip button
        self:skip()
    end
end

-- Handle card selection
function LevelUpShop:selectCard(index)
    -- Validate card selection
    if not self.cards or not self.cards[index] then 
        if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
            Debug.log("ERROR: LevelUpShop:selectCard - Invalid card or index: " .. tostring(index))
        end
        return 
    end
    
    local card = self.cards[index]
    local itemId = card.id
    local itemType = card.type
    
    if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
        Debug.log("LevelUpShop: Selected " .. itemType .. " " .. itemId .. " (Level " .. card.nextLevel .. ")")
    end
    
    -- Apply the selection - store the selection result to verify it worked
    local selectionSuccessful = false
    
    if itemType == "weapon" then
        -- Add or upgrade weapon
        if not self.weaponSystem then
            Debug.log("ERROR: Cannot select weapon card - no weapon system reference")
            return
        end
        
        if card.isNew then
            -- Add new weapon
            selectionSuccessful = self.weaponSystem:addWeapon(itemId)
            Event.dispatch("PLAYER_ITEM_GAINED", {id = itemId, type = "weapon", level = 1})
        else
            -- Upgrade existing weapon
            selectionSuccessful = self.weaponSystem:upgradeWeapon(itemId)
            Event.dispatch("PLAYER_ITEM_LEVELED", {id = itemId, type = "weapon", level = card.nextLevel})
        end
    elseif itemType == "passive" then
        -- Add or upgrade passive
        if not self.passiveSystem then
            Debug.log("ERROR: Cannot select passive card - no passive system reference")
            return
        end
        
        if card.isNew then
            -- Add new passive
            selectionSuccessful = self.passiveSystem:addPassive(itemId)
            Event.dispatch("PLAYER_ITEM_GAINED", {id = itemId, type = "passive", level = 1})
        else
            -- Upgrade existing passive
            selectionSuccessful = self.passiveSystem:upgradePassive(itemId)
            Event.dispatch("PLAYER_ITEM_LEVELED", {id = itemId, type = "passive", level = card.nextLevel})
        end
    end
    
    if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
        Debug.log("LevelUpShop: Selection applied successfully: " .. tostring(selectionSuccessful))
    end
    
    -- Close shop and resume gameplay
    self:close()
end

-- Handle reroll
function LevelUpShop:reroll()
    -- Check if player has enough coins
    if self.player.coins >= TUNING.SHOP.REROLL_COST then
        -- Deduct coins
        self.player.coins = self.player.coins - TUNING.SHOP.REROLL_COST
        
        if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
            Debug.log("LevelUpShop: Rerolling (Cost: " .. TUNING.SHOP.REROLL_COST .. " coins)")
        end
        
        -- Reopen shop with new items
        self:open(self.player)
    else
        -- Not enough coins
        if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
            Debug.log("LevelUpShop: Not enough coins to reroll. Need " .. TUNING.SHOP.REROLL_COST .. ", have " .. self.player.coins)
        end
    end
end

-- Handle skip
function LevelUpShop:skip()
    if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
        Debug.log("LevelUpShop: Skipped selection")
    end
    
    -- Close shop and resume gameplay
    self:close()
end

-- Close the shop
function LevelUpShop:close()
    -- Set shop state to closed
    self.isOpen = false
    
    -- Clear card data to prevent memory issues
    self.cards = {}
    
    -- Resume gameplay by dispatching the close event
    -- This will trigger the game to unpause
    Event.dispatch("LEVEL_UP_SHOP_CLOSED", {})
    
    if DEV.DEBUG_MASTER and DEV.DEBUG_LEVEL_UP then
        Debug.log("LevelUpShop: Closed and dispatched LEVEL_UP_SHOP_CLOSED event")
    end
end

return LevelUpShop
