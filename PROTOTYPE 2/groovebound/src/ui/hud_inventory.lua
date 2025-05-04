-- HUD Inventory
-- Displays player's weapons and passive items

local HUDInventory = {}

-- Initialize the inventory display
-- @param player - Reference to the player entity
-- @return The HUDInventory object
function HUDInventory.new(player)
  local self = {
    player = player,            -- Reference to player
    slotSize = 48,              -- Size of each inventory slot
    padding = 4,                -- Padding between slots
    weaponSlots = 4,            -- Number of weapon slots
    passiveSlots = 4,           -- Number of passive slots
    iconFont = nil,             -- Font for weapon/passive icons
    labelFont = nil,            -- Font for weapon/passive labels
    levelFont = nil             -- Font for level numbers
  }
  
  -- Set the metatable for the HUDInventory object
  setmetatable(self, {__index = HUDInventory})
  
  -- Load fonts
  self:loadFonts()
  
  return self
end

-- Load fonts for inventory display
function HUDInventory:loadFonts()
  self.iconFont = love.graphics.newFont(20)
  self.labelFont = love.graphics.newFont(12)
  self.levelFont = love.graphics.newFont(16)
end

-- Update the inventory display
-- @param dt - Delta time since last update
function HUDInventory:update(dt)
  -- Nothing to update, this is a static display
end

-- Draw the inventory display
function HUDInventory:draw()
  -- Get screen dimensions for positioning
  local width, height = love.graphics.getDimensions()
  
  -- Calculate total width of inventory
  local totalSlots = self.weaponSlots + self.passiveSlots
  local totalWidth = totalSlots * self.slotSize + (totalSlots - 1) * self.padding
  
  -- Position inventory at bottom center
  local startX = (width - totalWidth) / 2
  local startY = height - self.slotSize - 16  -- 16px from bottom
  
  -- Save current graphics state
  love.graphics.push("all")
  
  -- Draw weapon slots (first row)
  for i = 1, self.weaponSlots do
    local x = startX + (i-1) * (self.slotSize + self.padding)
    local weapon = self.player.weapons[i]
    self:drawSlot(x, startY, weapon, false)
  end
  
  -- Draw passive slots (second row, if needed)
  for i = 1, self.passiveSlots do
    local x = startX + (self.weaponSlots + i - 1) * (self.slotSize + self.padding)
    local passive = self.player.passives[i]
    self:drawSlot(x, startY, passive, true)
  end
  
  -- Restore graphics state
  love.graphics.pop()
end

-- Draw a single inventory slot
-- @param x - X position of the slot
-- @param y - Y position of the slot
-- @param item - The weapon or passive item to draw, or nil for empty slot
-- @param isPassive - Whether this is a passive item slot
function HUDInventory:drawSlot(x, y, item, isPassive)
  -- Draw slot background
  if item then
    -- Filled slot
    love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
  else
    -- Empty slot
    love.graphics.setColor(0.1, 0.1, 0.15, 0.6)
  end
  
  -- Draw slot rectangle with rounded corners
  love.graphics.rectangle("fill", x, y, self.slotSize, self.slotSize, 4, 4)
  
  -- Draw slot border
  if item then
    love.graphics.setColor(0.8, 0.8, 1.0, 0.8)
  else
    love.graphics.setColor(0.4, 0.4, 0.5, 0.5)
  end
  love.graphics.rectangle("line", x, y, self.slotSize, self.slotSize, 4, 4)
  
  -- Draw item if present
  if item then
    -- Different visuals for weapons vs. passives
    if isPassive then
      self:drawPassiveIcon(x, y, item)
    else
      self:drawWeaponIcon(x, y, item)
    end
    
    -- Draw item level if it has one
    if item.level and item.level > 1 then
      love.graphics.setFont(self.levelFont)
      love.graphics.setColor(1, 1, 0, 1)
      love.graphics.print("+" .. (item.level - 1), 
                          x + self.slotSize - 20, 
                          y + self.slotSize - 20)
    end
  else
    -- Draw a "+" for empty slot
    love.graphics.setFont(self.iconFont)
    love.graphics.setColor(0.5, 0.5, 0.6, 0.5)
    love.graphics.printf("+", x, y + self.slotSize/2 - 12, self.slotSize, "center")
  end
end

-- Draw weapon icon in slot
-- @param x - X position of the slot
-- @param y - Y position of the slot
-- @param weapon - The weapon to draw
function HUDInventory:drawWeaponIcon(x, y, weapon)
  -- Set color based on weapon type
  love.graphics.setColor(0.9, 0.9, 0.2, 1.0) -- Default yellow for weapons
  
  -- Draw weapon icon (simple placeholder)
  love.graphics.setFont(self.iconFont)
  love.graphics.printf("W", x, y + self.slotSize/2 - 12, self.slotSize, "center")
  
  -- Draw weapon name below the icon
  love.graphics.setFont(self.labelFont)
  love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
  
  -- Truncate name if too long
  local name = weapon.name
  if #name > 12 then
    name = name:sub(1, 10) .. ".."
  end
  
  love.graphics.printf(name, 
                      x - 10, 
                      y + self.slotSize - 4, 
                      self.slotSize + 20, 
                      "center")
end

-- Draw passive item icon in slot
-- @param x - X position of the slot
-- @param y - Y position of the slot
-- @param passive - The passive item to draw
function HUDInventory:drawPassiveIcon(x, y, passive)
  -- Set color based on passive type
  love.graphics.setColor(0.2, 0.8, 0.9, 1.0) -- Cyan for passives
  
  -- Draw passive icon (simple placeholder)
  love.graphics.setFont(self.iconFont)
  love.graphics.printf("P", x, y + self.slotSize/2 - 12, self.slotSize, "center")
  
  -- Draw passive name below the icon
  love.graphics.setFont(self.labelFont)
  love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
  
  -- Truncate name if too long
  local name = passive.name
  if #name > 12 then
    name = name:sub(1, 10) .. ".."
  end
  
  love.graphics.printf(name, 
                      x - 10, 
                      y + self.slotSize - 4, 
                      self.slotSize + 20, 
                      "center")
end

-- Return the HUDInventory module
return HUDInventory
