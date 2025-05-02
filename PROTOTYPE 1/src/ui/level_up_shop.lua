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

-- Table utility functions
local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- The LevelUpShop module
local LevelUpShop = {
    -- Shop state
    isOpen = false,
    cards = {},
    selectedIndex = 1,
    
    -- References to other systems
    player = nil,
    weaponSystem = nil,
    passiveSystem = nil,
    
    -- Card layout
    cardWidth = 160,
    cardHeight = 240,
    cardSpacing = 20,
    
    -- Delayed opening
    pendingOpen = false,
    delayTimer = 0,
    openDelay = 0,
    
    -- UI grid
    grid = nil,
    
    -- Capture screen for blur
    backgroundCapture = nil
}

-- Initialize the shop
function LevelUpShop:init()
    -- Create UI grid
    self.grid = BlockGrid:new({
        rows = 5,
        cols = 5,
        cellWidth = love.graphics.getWidth() / 5,
        cellHeight = love.graphics.getHeight() / 5
    })
    
    Debug.log("LevelUpShop: Initialized")
    return self
end

-- Open the shop
function LevelUpShop:open(player, weaponSystem, passiveSystem)
    -- STRICT VALIDATION: Ensure we have ALL required references
    if not player then
        Debug.log("ERROR: LevelUpShop:open called without player reference")
        return
    end
    
    if not weaponSystem then
        Debug.log("ERROR: LevelUpShop:open called without weaponSystem reference")
        return
    end
    
    if not passiveSystem then
        Debug.log("ERROR: LevelUpShop:open called without passiveSystem reference")
        return
    end
    
    -- Set references
    self.player = player
    self.weaponSystem = weaponSystem
    self.passiveSystem = passiveSystem
    
    -- Log debug info about system references (always log this since it's critical)
    Debug.log("LevelUpShop: Set shop references to weapon and passive systems")
    
    -- Reset state
    self.isOpen = true
    self.selectedIndex = 1
    self.cards = {}
    
    -- Build candidate pool of items
    local candidatePool = self:buildCandidatePool()
    
    -- Generate cards from the pool
    self:generateCards(candidatePool)
    
    -- Capture the current screen for blur background
    self:captureBackground()
    
    return self
end

-- Build the pool of candidate items that can be offered
function LevelUpShop:buildCandidatePool()
    local pool = {}
    
    Debug.log("START BUILDING CANDIDATE POOL")
    
    -- Check if we have item definitions available
    if not ItemDefs then
        Debug.log("ERROR: Cannot build shop - ItemDefs is nil")
        return pool
    end
    
    -- Get player's current items and levels
    local playerItems = {}
    local hasWeaponSystem = (self.weaponSystem ~= nil)
    local hasPassiveSystem = (self.passiveSystem ~= nil)
    
    -- Log system availability
    Debug.log("LevelUpShop: Building with weapon system: " .. 
              (hasWeaponSystem and "YES" or "NO") .. ", passive system: " .. 
              (hasPassiveSystem and "YES" or "NO"))
    
    -- Add weapons from weaponSystem (if available)
    if hasWeaponSystem then
        Debug.log("LevelUpShop: Using weaponSystem reference to get current weapon levels")
        
        -- Map all existing weapons to their levels
        for _, weapon in ipairs(self.weaponSystem.weapons) do
            if weapon and weapon.id then
                playerItems[weapon.id] = weapon.level
                Debug.log("LevelUpShop: Found weapon '" .. weapon.id .. "' at level " .. weapon.level)
            end
        end
    end
    
    -- Add passives from passiveSystem (if available)
    if hasPassiveSystem then
        Debug.log("LevelUpShop: Using passiveSystem reference to get current passive levels")
        
        -- Map all existing passives to their levels
        for _, passive in ipairs(self.passiveSystem.passives) do
            if passive and passive.id then
                playerItems[passive.id] = passive.level
                Debug.log("LevelUpShop: Found passive '" .. passive.id .. "' at level " .. passive.level)
            end
        end
    end
    
    -- Check all weapons
    if ItemDefs and ItemDefs.weapons then
        Debug.log("Processing " .. #ItemDefs.weapons .. " weapon definitions")
        
        for i, itemDef in ipairs(ItemDefs.weapons) do
            local currentLevel = playerItems[itemDef.id] or 0
            local maxLevel = itemDef.maxLevel or 5
            
            -- Create a copy of the item definition with its current level
            local item = deepcopy(itemDef)
            item.currentLevel = currentLevel
            item.type = "weapon"
            
            -- Add to candidate pool
            table.insert(pool, item)
            
            Debug.log("Added weapon candidate #" .. i .. ": '" .. (item.id or "unknown") .. 
                      "' (level " .. currentLevel .. ")")
        end
    else
        Debug.log("ERROR: No weapon definitions available")
    end
    
    -- Check all passives
    if ItemDefs and ItemDefs.passives then
        Debug.log("Processing " .. #ItemDefs.passives .. " passive definitions")
        
        for i, itemDef in ipairs(ItemDefs.passives) do
            local currentLevel = playerItems[itemDef.id] or 0
            local maxLevel = itemDef.maxLevel or 5
            
            -- Create a copy of the item definition with its current level
            local item = deepcopy(itemDef)
            item.currentLevel = currentLevel
            item.type = "passive"
            
            -- Add to candidate pool
            table.insert(pool, item)
            
            Debug.log("Added passive candidate #" .. i .. ": '" .. (item.id or "unknown") .. 
                      "' (level " .. currentLevel .. ")")
        end
    else
        Debug.log("ERROR: No passive definitions available")
    end
    
    -- Log the final pool size
    Debug.log("FINAL CANDIDATE POOL SIZE: " .. #pool)
    
    return pool
end

-- Generate cards from the candidate pool
function LevelUpShop:generateCards(candidatePool)
    -- Ensure we have a valid pool
    if not candidatePool or #candidatePool == 0 then
        Debug.log("ERROR: Empty candidate pool")
        return
    end
    
    -- Separate candidates into new and upgrade items
    local newItems = {}
    local upgradeItems = {}
    
    for i, item in ipairs(candidatePool) do
        if item.currentLevel == 0 then
            table.insert(newItems, {item = item, index = i})
        else
            table.insert(upgradeItems, {item = item, index = i})
        end
    end
    
    Debug.log("Shop candidate pools: " .. #newItems .. " new items, " .. #upgradeItems .. " upgrades")
    
    -- Try to ensure at least one new item and one upgrade if available
    local numCardsToGenerate = math.min(3, #candidatePool)
    local cardsAdded = 0
    
    -- Add one upgrade if available
    if #upgradeItems > 0 then
        local idx = love.math.random(#upgradeItems)
        local selection = upgradeItems[idx]
        local card = self:buildCard(selection.item)
        table.insert(self.cards, card)
        table.remove(upgradeItems, idx)
        cardsAdded = cardsAdded + 1
    end
    
    -- Add one new item if available
    if cardsAdded < numCardsToGenerate and #newItems > 0 then
        local idx = love.math.random(#newItems)
        local selection = newItems[idx]
        local card = self:buildCard(selection.item)
        table.insert(self.cards, card)
        table.remove(newItems, idx)
        cardsAdded = cardsAdded + 1
    end
    
    -- Combine remaining items and pick at random to fill remaining slots
    local remainingPool = {}
    for _, item in ipairs(newItems) do
        table.insert(remainingPool, item)
    end
    for _, item in ipairs(upgradeItems) do
        table.insert(remainingPool, item)
    end
    
    -- Fill remaining slots randomly
    while cardsAdded < numCardsToGenerate and #remainingPool > 0 do
        local idx = love.math.random(#remainingPool)
        local selection = remainingPool[idx]
        local card = self:buildCard(selection.item)
        table.insert(self.cards, card)
        table.remove(remainingPool, idx)
        cardsAdded = cardsAdded + 1
    end
    
    Debug.log("Generated " .. #self.cards .. " cards for shop")
end

-- Build a card from an item definition
function LevelUpShop:buildCard(item)
    -- Get current level using the getLevel methods if available
    local currentLevel = 0
    
    if item.type == "weapon" and self.weaponSystem then
        currentLevel = self.weaponSystem:getLevel(item.id) or item.currentLevel or 0
    elseif item.type == "passive" and self.passiveSystem then
        currentLevel = self.passiveSystem:getLevel(item.id) or item.currentLevel or 0
    else
        currentLevel = item.currentLevel or 0
    end
    
    -- Determine if this is a new item or an upgrade
    local isNew = (currentLevel == 0)
    local nextLevel = currentLevel + 1
    
    -- Log card creation
    Debug.log("Building card for '" .. item.id .. "' - " .. 
              (isNew and "NEW" or ("Level " .. currentLevel .. " -> " .. nextLevel)))
    
    -- Build the card data
    local card = {
        id = item.id,
        type = item.type,
        displayName = item.displayName or "Unknown Item",
        description = item.description or "No description available",
        icon = item.icon,
        rarity = item.rarity or "common",
        isNew = isNew,
        currentLevel = currentLevel,
        nextLevel = nextLevel,
        maxLevel = item.maxLevel or 5
    }
    
    return card
end

-- Capture the current screen for background blur
function LevelUpShop:captureBackground()
    self.backgroundCapture = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setCanvas(self.backgroundCapture)
    love.graphics.clear()
    love.graphics.draw(love.graphics.captureScreenshot())
    love.graphics.setCanvas()
end

-- Draw the shop
function LevelUpShop:draw()
    if not self.isOpen then return end
    
    -- Draw blurred background
    if self.backgroundCapture then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.draw(self.backgroundCapture)
    end
    
    -- Draw darkened overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(32))
    local title = "Level Up! You reached level " .. self.player.level
    local titleWidth = love.graphics.getFont():getWidth(title)
    love.graphics.print(title, love.graphics.getWidth() / 2 - titleWidth / 2, 70)
    
    -- Draw subtitle
    love.graphics.setFont(love.graphics.newFont(24))
    local subtitle = "Choose an upgrade:"
    local subtitleWidth = love.graphics.getFont():getWidth(subtitle)
    love.graphics.print(subtitle, love.graphics.getWidth() / 2 - subtitleWidth / 2, 120)
    
    -- Draw cards
    self:drawCards()
    
    -- Draw buttons
    self:drawButtons()
end

-- Draw all cards
function LevelUpShop:drawCards()
    if #self.cards == 0 then return end
    
    local totalWidth = #self.cards * (self.cardWidth + self.cardSpacing) - self.cardSpacing
    local startX = love.graphics.getWidth() / 2 - totalWidth / 2
    local startY = love.graphics.getHeight() / 2 - self.cardHeight / 2
    
    for i, card in ipairs(self.cards) do
        local x = startX + (i-1) * (self.cardWidth + self.cardSpacing)
        local isSelected = (i == self.selectedIndex)
        self:drawCard(card, x, startY, isSelected)
    end
end

-- Draw a single card
function LevelUpShop:drawCard(card, x, y, isSelected)
    -- Get rarity color
    local rarityColor = Rarity.colors[card.rarity] or {0.7, 0.7, 0.7, 1.0}
    
    -- Border thickness and colors based on selection
    local borderThickness = isSelected and 4 or 2
    local borderColor = isSelected and {1, 1, 1, 1} or {0.6, 0.6, 0.6, 1}
    
    -- Card background
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", x, y, self.cardWidth, self.cardHeight, 8, 8)
    
    -- Card border
    love.graphics.setColor(borderColor)
    love.graphics.setLineWidth(borderThickness)
    love.graphics.rectangle("line", x, y, self.cardWidth, self.cardHeight, 8, 8)
    
    -- Card header with rarity color
    love.graphics.setColor(rarityColor)
    love.graphics.rectangle("fill", x, y, self.cardWidth, 40, 8, 8, true, true, false, false)
    
    -- Card title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(16))
    local titleText = card.displayName or "Unknown"
    local titleWidth = love.graphics.getFont():getWidth(titleText)
    love.graphics.print(titleText, x + self.cardWidth/2 - titleWidth/2, y + 10)
    
    -- Item type
    love.graphics.setFont(love.graphics.newFont(12))
    local typeText = "Type: " .. card.type
    local typeWidth = love.graphics.getFont():getWidth(typeText)
    love.graphics.print(typeText, x + self.cardWidth/2 - typeWidth/2, y + 30)
    
    -- Item icon (if available)
    if card.icon and type(card.icon) == "userdata" then
        local iconSize = 64
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(card.icon, x + self.cardWidth/2 - iconSize/2, y + 60, 0, iconSize/card.icon:getWidth(), iconSize/card.icon:getHeight())
    else
        -- Draw placeholder if no icon
        love.graphics.setColor(0.4, 0.4, 0.4, 1)
        love.graphics.rectangle("fill", x + self.cardWidth/2 - 32, y + 60, 64, 64)
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.rectangle("line", x + self.cardWidth/2 - 32, y + 60, 64, 64)
    end
    
    -- Level info
    love.graphics.setFont(love.graphics.newFont(14))
    local levelText = "Level: " .. (card.isNew and "0->1" or (card.currentLevel .. "->" .. card.nextLevel))
    local levelWidth = love.graphics.getFont():getWidth(levelText)
    love.graphics.print(levelText, x + self.cardWidth/2 - levelWidth/2, y + 130)
    
    -- Badge for NEW or LEVEL UP
    if card.isNew then
        love.graphics.setColor(0.2, 0.8, 0.2, 1) -- Green for new items
        love.graphics.rectangle("fill", x + self.cardWidth/2 - 25, y + 155, 50, 25, 4, 4)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(14))
        local badgeText = "NEW"
        local badgeWidth = love.graphics.getFont():getWidth(badgeText)
        love.graphics.print(badgeText, x + self.cardWidth/2 - badgeWidth/2, y + 158)
    else
        love.graphics.setColor(0.2, 0.4, 0.8, 1) -- Blue for level ups
        love.graphics.rectangle("fill", x + self.cardWidth/2 - 25, y + 155, 50, 25, 4, 4)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(14))
        local badgeText = "LV " .. card.nextLevel
        local badgeWidth = love.graphics.getFont():getWidth(badgeText)
        love.graphics.print(badgeText, x + self.cardWidth/2 - badgeWidth/2, y + 158)
    end
    
    -- Item description
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.printf(card.description or "No description", x + 10, y + 190, self.cardWidth - 20, "center")
end

-- Draw buttons (REROLL and SKIP)
function LevelUpShop:drawButtons()
    local buttonWidth = 120
    local buttonHeight = 40
    local spacing = 60
    
    -- Reroll button
    local rerollX = love.graphics.getWidth() / 2 - buttonWidth - spacing/2
    local buttonY = love.graphics.getHeight() - 100
    
    love.graphics.setColor(0.2, 0.2, 0.4, 1)
    love.graphics.rectangle("fill", rerollX, buttonY, buttonWidth, buttonHeight, 5, 5)
    love.graphics.setColor(0.4, 0.4, 0.6, 1)
    love.graphics.rectangle("line", rerollX, buttonY, buttonWidth, buttonHeight, 5, 5)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(16))
    local rerollText = "REROLL"
    local rerollWidth = love.graphics.getFont():getWidth(rerollText)
    love.graphics.print(rerollText, rerollX + buttonWidth/2 - rerollWidth/2, buttonY + buttonHeight/2 - 10)
    
    -- Skip button
    local skipX = love.graphics.getWidth() / 2 + spacing/2
    
    love.graphics.setColor(0.2, 0.2, 0.4, 1)
    love.graphics.rectangle("fill", skipX, buttonY, buttonWidth, buttonHeight, 5, 5)
    love.graphics.setColor(0.4, 0.4, 0.6, 1)
    love.graphics.rectangle("line", skipX, buttonY, buttonWidth, buttonHeight, 5, 5)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(16))
    local skipText = "SKIP"
    local skipWidth = love.graphics.getFont():getWidth(skipText)
    love.graphics.print(skipText, skipX + buttonWidth/2 - skipWidth/2, buttonY + buttonHeight/2 - 10)
end

-- Update shop logic
function LevelUpShop:update(dt)
    -- Handle delayed opening if set
    if self.pendingOpen then
        self.delayTimer = (self.delayTimer or 0) + dt
        
        if self.delayTimer >= (self.openDelay or 0) then
            self.pendingOpen = false
            self:open(self.player, self.weaponSystem, self.passiveSystem)
        end
    end
end

-- Handle mouse clicks
function LevelUpShop:mousepressed(x, y, button)
    -- Only process clicks when the shop is open
    if not self.isOpen or button ~= 1 then return false end
    
    -- Check for card clicks
    if #self.cards > 0 then
        local totalWidth = #self.cards * (self.cardWidth + self.cardSpacing) - self.cardSpacing
        local startX = love.graphics.getWidth() / 2 - totalWidth / 2
        local startY = love.graphics.getHeight() / 2 - self.cardHeight / 2
        
        for i, card in ipairs(self.cards) do
            local cardX = startX + (i-1) * (self.cardWidth + self.cardSpacing)
            
            if x >= cardX and x <= cardX + self.cardWidth and
               y >= startY and y <= startY + self.cardHeight then
                self:selectCard(i)
                return true
            end
        end
    end
    
    -- Check for button clicks
    local buttonWidth = 120
    local buttonHeight = 40
    local spacing = 60
    local buttonY = love.graphics.getHeight() - 100
    
    -- Reroll button
    local rerollX = love.graphics.getWidth() / 2 - buttonWidth - spacing/2
    if x >= rerollX and x <= rerollX + buttonWidth and
       y >= buttonY and y <= buttonY + buttonHeight then
        self:reroll()
        return true
    end
    
    -- Skip button
    local skipX = love.graphics.getWidth() / 2 + spacing/2
    if x >= skipX and x <= skipX + buttonWidth and
       y >= buttonY and y <= buttonY + buttonHeight then
        self:skip()
        return true
    end
    
    return false
end

-- Handle gamepad input
function LevelUpShop:gamepadpressed(gamepad, button)
    -- Only process input when the shop is open
    if not self.isOpen then return false end
    
    if button == "dpleft" then
        -- Move selection left
        self.selectedIndex = math.max(1, self.selectedIndex - 1)
        return true
    elseif button == "dpright" then
        -- Move selection right
        self.selectedIndex = math.min(#self.cards, self.selectedIndex + 1)
        return true
    elseif button == "a" then
        -- Select current card
        self:selectCurrent()
        return true
    elseif button == "x" then
        -- Reroll
        self:reroll()
        return true
    elseif button == "b" then
        -- Skip
        self:skip()
        return true
    end
    
    return false
end

-- Select the current card
function LevelUpShop:selectCurrent()
    if #self.cards > 0 and self.selectedIndex >= 1 and self.selectedIndex <= #self.cards then
        self:selectCard(self.selectedIndex)
    end
end

-- Select a card
function LevelUpShop:selectCard(index)
    -- Validate card selection
    if not self.cards or not self.cards[index] then 
        Debug.log("ERROR: LevelUpShop:selectCard - Invalid card or index: " .. tostring(index))
        return 
    end
    
    local card = self.cards[index]
    local itemId = card.id
    local itemType = card.type
    
    -- Always log selection for debugging
    Debug.log("PLAYER SELECTED: " .. itemType .. " '" .. itemId .. "' (" .. 
              (card.isNew and "NEW" or ("Level " .. (card.nextLevel-1) .. " -> " .. card.nextLevel)) .. ")")
    
    -- Apply the selection with the appropriate system
    if itemType == "weapon" then
        -- Use the weapon system if available
        if self.weaponSystem then
            -- Add or upgrade the weapon
            if self.weaponSystem.addOrUpgrade then
                self.weaponSystem:addOrUpgrade(itemId)
            elseif card.isNew and self.weaponSystem.addWeapon then
                self.weaponSystem:addWeapon(itemId)
            elseif not card.isNew and self.weaponSystem.upgradeWeapon then
                self.weaponSystem:upgradeWeapon(itemId)
            end
            
            -- Refresh the inventory UI if present
            if self.player and self.player.inventoryUI then
                self.player.inventoryUI:refresh()
            end
            
            -- Dispatch appropriate event
            Event.dispatch(card.isNew and "PLAYER_ITEM_GAINED" or "PLAYER_ITEM_LEVELED", 
                          {id = itemId, type = "weapon", level = card.nextLevel})
        else
            Debug.log("ERROR: Cannot add/upgrade weapon - missing weaponSystem reference")
        end
    elseif itemType == "passive" then
        -- Use the passive system if available
        if self.passiveSystem then
            -- Add or upgrade the passive with error protection
            local success = pcall(function()
                if self.passiveSystem.addOrUpgrade then
                    self.passiveSystem:addOrUpgrade(itemId)
                elseif card.isNew and self.passiveSystem.addPassive then
                    self.passiveSystem:addPassive(itemId)
                elseif not card.isNew and self.passiveSystem.upgradePassive then
                    self.passiveSystem:upgradePassive(itemId)
                end
            end)
            
            if not success then
                Debug.log("ERROR during passive selection - using fallback method")
                
                -- Try a fallback approach for adding/upgrading
                if card.isNew then
                    -- Try to add through table insertion
                    local newPassive = {
                        id = itemId,
                        level = 1,
                        def = ItemDefs.passives[self:findItemById(ItemDefs.passives, itemId)]
                    }
                    table.insert(self.passiveSystem.passives, newPassive)
                else
                    -- Try to find and increment level
                    for _, passive in ipairs(self.passiveSystem.passives) do
                        if passive.id == itemId then
                            passive.level = passive.level + 1
                            break
                        end
                    end
                end
            end
            
            -- Refresh the buffs UI if present
            if self.player and self.player.buffsUI then
                self.player.buffsUI:refresh()
            end
            
            -- Dispatch appropriate event
            Event.dispatch(card.isNew and "PLAYER_BUFF_GAINED" or "PLAYER_BUFF_LEVELED", 
                          {id = itemId, level = card.nextLevel})
        else
            Debug.log("ERROR: Cannot add/upgrade passive - missing passiveSystem reference")
        end
    end
    
    -- Dispatch a general items changed event
    Event.dispatch("PLAYER_ITEMS_CHANGED", {})
    
    -- Close the shop
    self:close()
end

-- Find item by ID in a list
function LevelUpShop:findItemById(items, id)
    for i, item in ipairs(items) do
        if item.id == id then
            return i
        end
    end
    return nil
end

-- Handle reroll
function LevelUpShop:reroll()
    -- Safety check on player reference
    if not self.player then
        Debug.log("ERROR: Cannot reroll - missing player reference")
        return
    end
    
    -- Check if we need to enforce coin cost
    local rerollCost = TUNING.SHOP.REROLL_COST or 0
    if rerollCost > 0 and self.player.coins and self.player.coins < rerollCost then
        Debug.log("Not enough coins to reroll: " .. self.player.coins .. "/" .. rerollCost)
        return
    end
    
    -- Deduct coins if cost is enforced
    if rerollCost > 0 and self.player.coins then
        self.player.coins = self.player.coins - rerollCost
    end
    
    -- Clear current cards
    self.cards = {}
    
    -- Build new candidate pool
    local candidatePool = self:buildCandidatePool()
    
    -- Generate new cards
    self:generateCards(candidatePool)
    
    -- Reset selection
    self.selectedIndex = 1
    
    Debug.log("Reroll complete, generated " .. #self.cards .. " new cards")
end

-- Handle skip
function LevelUpShop:skip()
    Debug.log("LevelUpShop: Skipped selection")
    
    -- Close shop without making a selection
    self:close()
end

-- Close the shop
function LevelUpShop:close()
    -- Set shop state to closed
    self.isOpen = false
    
    -- Clear card data to prevent memory issues
    self.cards = {}
    
    -- Resume gameplay by dispatching the close event
    Event.dispatch("LEVEL_UP_SHOP_CLOSED", {})
    
    Debug.log("LevelUpShop: Closed and dispatched LEVEL_UP_SHOP_CLOSED event")
end

-- Return the module
return LevelUpShop
