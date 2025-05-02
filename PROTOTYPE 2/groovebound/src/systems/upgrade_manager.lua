-- Upgrade Manager
-- Handles applying upgrades when cards are picked in level-up modal

local UpgradeManager = {}

-- Create a new upgrade manager
-- @param player - Reference to the player entity
-- @return A new upgrade manager object
function UpgradeManager.new(player)
  local self = {
    player = player,      -- Reference to player entity
    upgrades = {},        -- Track applied upgrades
    
    -- Default weapon levels/stats
    weaponLevel = 1,
    weaponDamage = 10,    -- Base weapon damage
    
    -- Speed multiplier
    speedMultiplier = 1.0
  }
  
  -- Set the metatable for the upgrade manager object
  setmetatable(self, {__index = UpgradeManager})
  
  -- Load weapon damage from settings if available
  if Settings and Settings.globals and Settings.globals.weapon_damage then
    self.weaponDamage = Settings.globals.weapon_damage
  end
  
  -- Register for card picked events
  if EventBus then
    EventBus:on("CARD_PICKED", function(data)
      self:apply(data.card)
    end)
  end
  
  return self
end

-- Apply an upgrade based on the card name
-- @param name - Name of the upgrade card
function UpgradeManager:apply(name)
  -- Log the upgrade
  if Debug then
    Debug.log("UPGRADE", "Applying upgrade: " .. name)
  end
  
  -- Add to list of applied upgrades
  table.insert(self.upgrades, name)
  
  -- Apply the upgrade based on its name
  if name:find("Power Chord") or name:find("Lv") then
    -- Weapon level upgrade
    self.weaponLevel = self.weaponLevel + 1
    
    -- Increase weapon damage
    self.weaponDamage = self.weaponDamage * 1.2
    
    -- Update player's weapon
    if self.player and self.player.weapon then
      self.player.weapon.damage = self.weaponDamage
      self.player.weapon.level = self.weaponLevel
    end
    
    -- Log the specific upgrade
    if Debug then
      Debug.log("UPGRADE", "Weapon level increased to " .. self.weaponLevel .. " (damage: " .. self.weaponDamage .. ")")
    end
    
  elseif name:find("Speed") then
    -- Speed upgrade
    self.speedMultiplier = self.speedMultiplier * 1.15
    
    -- Update player speed
    if self.player then
      self.player.speed = self.player.baseSpeed * self.speedMultiplier
    end
    
    -- Log the specific upgrade
    if Debug then
      Debug.log("UPGRADE", "Speed increased by 15% (multiplier: " .. self.speedMultiplier .. ")")
    end
    
  elseif name:find("Bass Drop") then
    -- For now, just increase weapon damage slightly
    -- In future phases this could add AOE effects
    self.weaponDamage = self.weaponDamage * 1.1
    
    -- Update player's weapon
    if self.player and self.player.weapon then
      self.player.weapon.damage = self.weaponDamage
    end
    
    -- Log the specific upgrade
    if Debug then
      Debug.log("UPGRADE", "Bass Drop selected (damage: " .. self.weaponDamage .. ")")
    end
  end
  
  -- Notify that an upgrade was applied
  if EventBus then
    EventBus:emit("UPGRADE_APPLIED", {
      name = name,
      weaponLevel = self.weaponLevel,
      weaponDamage = self.weaponDamage,
      speedMultiplier = self.speedMultiplier
    })
  end
end

-- Get the current weapon level
-- @return Current weapon level
function UpgradeManager:getWeaponLevel()
  return self.weaponLevel
end

-- Get the current weapon damage
-- @return Current weapon damage
function UpgradeManager:getWeaponDamage()
  return self.weaponDamage
end

-- Get the current speed multiplier
-- @return Current speed multiplier
function UpgradeManager:getSpeedMultiplier()
  return self.speedMultiplier
end

-- Return the upgrade manager module
return UpgradeManager
