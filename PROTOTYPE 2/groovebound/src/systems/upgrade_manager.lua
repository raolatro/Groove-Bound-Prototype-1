-- Upgrade Manager
-- Handles applying upgrades when cards are picked in level-up modal

local Settings = require("src/core/settings")
local WeaponsData = require("src/data/weapons")

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
  
  -- Extract weapon ID from name if possible
  local weaponId = name:lower():gsub(" ", "_")
  local isKnownWeapon = false
  
  -- Check if this is a weapon upgrade from our data
  for id, _ in pairs(WeaponsData.types) do
    if name:find(WeaponsData.types[id].name) then
      isKnownWeapon = true
      weaponId = id
      break
    end
  end
  
  -- Handle passive upgrades
  if name:find("Speed Boost") then
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
  -- Handle Basic Attack upgrade (first weapon)
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
  -- Handle weapon upgrades from weapons data
  elseif isKnownWeapon then
    local weaponData = WeaponsData.get(weaponId)
    
    -- Check if player already has this weapon
    local weaponIndex = self:findWeaponByName(weaponData.name)
    
    if weaponIndex then
      -- Upgrade existing weapon
      local weapon = self.player.weapons[weaponIndex]
      weapon.level = weapon.level + 1
      weapon.damage = weapon.damage * 1.25  -- Default upgrade multiplier
      
      -- Log the specific upgrade
      if Debug and Debug.log then
        Debug.log("LEVEL", weaponData.name .. " upgraded to level " .. weapon.level)
      end
    else
      -- Add new weapon if there's room
      if #self.player.weapons < Settings.globals.max_weapon_slots then
        local newWeapon = {
          id = weaponData.id,
          name = weaponData.name,
          damage = weaponData.damage,
          level = 1,
          fireRate = weaponData.fire_rate,
          bulletSpeed = weaponData.bullet_speed,
          bulletSize = weaponData.bullet_size,
          bulletLifetime = weaponData.bullet_lifetime,
          bullet_color = weaponData.bullet_color,
          bullet_count = weaponData.bullet_count,
          spread = weaponData.spread,
          fireTimer = 0,
          enabled = true,
          isPassive = false
        }
        table.insert(self.player.weapons, newWeapon)
        
        -- Log the addition
        if Debug and Debug.log then
          Debug.log("LEVEL", "New weapon added: " .. weaponData.name)
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

-- Get a list of available upgrade options
-- @param count - Number of options to generate
-- @return A list of available upgrade options
function UpgradeManager:getUpgradeOptions(count)
  local options = {}
  count = count or 3
  
  -- Build available upgrades dynamically based on weapons data
  local availableUpgrades = {
    "Basic Attack",  -- Always include basic attack upgrade
    "Speed Boost"   -- Always include speed boost
  }
  
  -- Add all weapons from weapons data
  for id, weaponData in pairs(WeaponsData.types) do
    -- Skip the pistol (base weapon) as it's covered by "Basic Attack"
    if id ~= "pistol" then
      table.insert(availableUpgrades, weaponData.name)
    end
  end
  
  -- Filter out upgrades based on player's current weapons and passives
  local filteredUpgrades = {}
  for _, upgrade in ipairs(availableUpgrades) do
    if upgrade == "Speed Boost" then
      -- For passives, check if player has room for more passives
      local passiveIndex = self:findPassiveByName("Speed Boost")
      if not passiveIndex or (#self.player.passives < 4) then
        table.insert(filteredUpgrades, upgrade)
      end
    elseif upgrade == "Basic Attack" then
      -- Always offer basic attack upgrade
      table.insert(filteredUpgrades, upgrade)
    else
      -- For weapons, either player doesn't have it yet (and has room) or already has it
      if #self.player.weapons < Settings.globals.max_weapon_slots or self:findWeaponByName(upgrade) then
        table.insert(filteredUpgrades, upgrade)
      end
    end
  end
  
  -- Debugging
  if Debug and Debug.log and Settings.debug.files.levelup then
    Debug.log("LEVEL_UP", "Found " .. #filteredUpgrades .. " available upgrades")
    for i, upgrade in ipairs(filteredUpgrades) do
      Debug.log("LEVEL_UP", "Available upgrade " .. i .. ": " .. upgrade)
    end
  end
  
  -- Randomly select from available upgrades
  for i = 1, count do
    if #filteredUpgrades > 0 then
      local index = math.random(1, #filteredUpgrades)
      table.insert(options, filteredUpgrades[index])
      table.remove(filteredUpgrades, index)
    end
  end
  
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
