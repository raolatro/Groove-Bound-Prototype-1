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
  if Debug and Debug.log then
    Debug.log("UPGRADE", "Applying upgrade: " .. name)
  end
  
  -- Add to list of applied upgrades
  table.insert(self.upgrades, name)
  
  -- Apply the upgrade based on its name
  if name:find("Power Chord") then
    -- Check if player already has this weapon
    local weaponIndex = self:findWeaponByName("Power Chord")
    
    if weaponIndex then
      -- Upgrade existing weapon
      local weapon = self.player.weapons[weaponIndex]
      weapon.level = weapon.level + 1
      weapon.damage = weapon.damage * 1.25
      
      -- Log the specific upgrade
      if Debug and Debug.log then
        Debug.log("LEVEL", "Power Chord upgraded to level " .. weapon.level)
      end
    else
      -- Add new weapon if there's room
      if #self.player.weapons < 4 then
        local newWeapon = {
          name = "Power Chord",
          damage = 15,
          level = 1,
          fireRate = 0.4,
          bulletSpeed = 450,
          bulletSize = 6,
          bulletLifetime = 1.2,
          fireTimer = 0,
          enabled = true,
          isPassive = false
        }
        table.insert(self.player.weapons, newWeapon)
        
        -- Log the addition
        if Debug and Debug.log then
          Debug.log("LEVEL", "New weapon added: Power Chord")
        end
      end
    end
    
  elseif name:find("Speed Boost") then
    -- Check if player already has this passive
    local passiveIndex = self:findPassiveByName("Speed Boost")
    
    if passiveIndex then
      -- Upgrade existing passive
      local passive = self.player.passives[passiveIndex]
      passive.level = passive.level + 1
      passive.multiplier = passive.multiplier + 0.15
      
      -- Apply the speed boost
      self.player.speed = self.player.baseSpeed * passive.multiplier
      
      -- Log the specific upgrade
      if Debug and Debug.log then
        Debug.log("LEVEL", "Speed Boost upgraded to level " .. passive.level)
      end
    else
      -- Add new passive if there's room
      if #self.player.passives < 4 then
        local newPassive = {
          name = "Speed Boost",
          level = 1,
          multiplier = 1.15,
          isPassive = true
        }
        table.insert(self.player.passives, newPassive)
        
        -- Apply the speed boost
        self.player.speed = self.player.baseSpeed * newPassive.multiplier
        
        -- Log the addition
        if Debug and Debug.log then
          Debug.log("LEVEL", "New passive added: Speed Boost")
        end
      end
    end
    
  elseif name:find("Basic Attack") then
    -- Always upgrade the basic attack (first weapon)
    if #self.player.weapons > 0 then
      local weapon = self.player.weapons[1]
      weapon.level = weapon.level + 1
      weapon.damage = weapon.damage * 1.2
      
      -- Log the specific upgrade
      if Debug and Debug.log then
        Debug.log("LEVEL", "Basic Attack upgraded to level " .. weapon.level)
      end
    end
    
  elseif name:find("Bass Drop") then
    -- Check if player already has this weapon
    local weaponIndex = self:findWeaponByName("Bass Drop")
    
    if weaponIndex then
      -- Upgrade existing weapon
      local weapon = self.player.weapons[weaponIndex]
      weapon.level = weapon.level + 1
      weapon.damage = weapon.damage * 1.3
      
      -- Log the specific upgrade
      if Debug and Debug.log then
        Debug.log("LEVEL", "Bass Drop upgraded to level " .. weapon.level)
      end
    else
      -- Add new weapon if there's room
      if #self.player.weapons < 4 then
        local newWeapon = {
          name = "Bass Drop",
          damage = 25,
          level = 1,
          fireRate = 0.8,
          bulletSpeed = 350,
          bulletSize = 10,
          bulletLifetime = 0.8,
          fireTimer = 0,
          enabled = true,
          isPassive = false
        }
        table.insert(self.player.weapons, newWeapon)
        
        -- Log the addition
        if Debug and Debug.log then
          Debug.log("LEVEL", "New weapon added: Bass Drop")
        end
      end
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

-- Find a weapon in player's inventory by name
-- @param name - Name of the weapon to find
-- @return The index of the weapon if found, nil otherwise
function UpgradeManager:findWeaponByName(name)
  if not self.player or not self.player.weapons then return nil end
  
  for i, weapon in ipairs(self.player.weapons) do
    if weapon.name == name then
      return i
    end
  end
  
  return nil
end

-- Find a passive in player's inventory by name
-- @param name - Name of the passive to find
-- @return The index of the passive if found, nil otherwise
function UpgradeManager:findPassiveByName(name)
  if not self.player or not self.player.passives then return nil end
  
  for i, passive in ipairs(self.player.passives) do
    if passive.name == name then
      return i
    end
  end
  
  return nil
end

-- Get a list of available upgrades
-- @param count - Number of upgrades to return
-- @return Array of upgrade names
function UpgradeManager:getAvailableUpgrades(count)
  -- Default upgrades - always include Basic Attack upgrade
  local options = {
    "Basic Attack Lv+"
  }
  
  -- Add new weapons if we have room
  if #self.player.weapons < 4 then
    -- Offer new weapons only if we have room
    if not self:findWeaponByName("Power Chord") then
      table.insert(options, "Power Chord (New)")
    end
    
    if not self:findWeaponByName("Bass Drop") then
      table.insert(options, "Bass Drop (New)")
    end
  end
  
  -- Add weapon upgrades for existing weapons
  for _, weapon in ipairs(self.player.weapons) do
    if weapon.name ~= "Basic Attack" then -- Basic attack is already included
      table.insert(options, weapon.name .. " Lv+")
    end
  end
  
  -- Add passive upgrades
  if #self.player.passives < 4 then
    -- Offer new passives if we have room
    if not self:findPassiveByName("Speed Boost") then
      table.insert(options, "Speed Boost (New)")
    end
  end
  
  -- Add passive upgrades for existing passives
  for _, passive in ipairs(self.player.passives) do
    table.insert(options, passive.name .. " Lv+")
  end
  
  -- Shuffle the options for randomness
  self:shuffleTable(options)
  
  -- Return the requested number of options
  local result = {}
  for i = 1, math.min(count, #options) do
    table.insert(result, options[i])
  end
  
  -- Log available upgrades
  if Debug and Debug.log then
    Debug.log("LEVEL", "Offering upgrades: " .. table.concat(result, ", "))
  end
  
  return result
end

-- Shuffle a table in-place (Fisher-Yates algorithm)
-- @param t - Table to shuffle
function UpgradeManager:shuffleTable(t)
  local n = #t
  while n > 1 do
    local k = math.random(n)
    t[n], t[k] = t[k], t[n]
    n = n - 1
  end
end

-- Return the upgrade manager module
return UpgradeManager
