-- item_defs.lua
-- Defines all weapons and passive items for Groove Bound

-- Helper function to convert RGB values (0-255) to LÖVE format (0-1)
local function rgb(r, g, b)
    return {r/255, g/255, b/255, 1}
end

-- Weapon definitions
local weapons = {
    -- Pistol - Basic single-shot weapon
    {
        id = "pistol",
        displayName = "Pocket Pistol",
        colour = rgb(66, 200, 255),
        rarity = "common",
        category = "pistol",
        maxLevel = 5,
        behaviour = "forward",
        stats = {
            damage = 10,        -- Base damage per shot
            fireRate = 1.5,     -- Time between shots (seconds) - drastically reduced fire rate
            projectileSpeed = 600, -- Pixels per second
            range = 500,        -- Maximum travel distance
            projectiles = 1,    -- Number of projectiles per shot
            piercing = 0,       -- Number of enemies projectile can pass through
        },
        levelUps = {
            damage = "+5",       -- Flat increase per level
            fireRate = "-5%",    -- Percentage decrease (faster firing)
            projectileSpeed = "+10%", 
            range = "+10%",
        }
    },
    
    -- Omni Blaster - Multi-directional spread weapon
    {
        id = "omni",
        displayName = "Omni Blaster",
        colour = rgb(255, 108, 66),
        rarity = "rare",
        category = "multi",
        maxLevel = 5,
        behaviour = "spread",
        stats = {
            damage = 8,         -- Damage per projectile
            fireRate = 2.0,     -- Time between shots - drastically reduced fire rate
            projectileSpeed = 450,
            range = 300,
            projectiles = 3,    -- Number of projectiles in the spread
            spreadAngle = 45,   -- Total angle of the spread in degrees
            piercing = 1,       -- Number of enemies each projectile can pass through
        },
        levelUps = {
            damage = "+3",
            fireRate = "-5%",
            projectiles = "+1", -- One additional projectile per level
            spreadAngle = "+5", -- Wider spread per level
        }
    },
    
    -- Boom Box - Area of effect explosion
    {
        id = "bomb",
        displayName = "Boom Box",
        colour = rgb(255, 219, 66),
        rarity = "epic",
        category = "aoe",
        maxLevel = 5,
        behaviour = "aoe",
        stats = {
            damage = 25,        -- Damage per explosion
            fireRate = 3.0,     -- Time between bombs - drastically reduced fire rate
            blastRadius = 150,  -- Explosion radius
            projectileSpeed = 300, -- Travel speed of the bomb
            range = 250,        -- How far the bomb travels before exploding
            projectiles = 1,    -- Number of bombs
        },
        levelUps = {
            damage = "+10",
            fireRate = "-10%",
            blastRadius = "+15%",
        }
    },
    
    -- Groove Drone - Autonomous orbiting helper
    {
        id = "drone",
        displayName = "Groove Drone",
        colour = rgb(142, 66, 255),
        rarity = "legendary",
        category = "autonomous",
        maxLevel = 5,
        behaviour = "drone",
        stats = {
            damage = 5,          -- Damage per drone shot
            fireRate = 2.5,      -- Time between drone shots - drastically reduced fire rate
            projectileSpeed = 400,
            range = 200,
            projectiles = 1,     -- Number of drones (starts with 1)
            orbitRadius = 100,   -- Distance from player
            orbitSpeed = 1,      -- Revolutions per second
        },
        levelUps = {
            damage = "+2",
            fireRate = "-5%",
            projectiles = "+1",  -- Additional drone per level
        }
    }
}

-- Passive item definitions
local passives = {
    -- Attack Speed passive
    {
        id = "attack_speed",
        displayName = "Rhythm Boost",
        colour = rgb(255, 247, 66),
        rarity = "rare",
        maxLevel = 3,
        effects = {
            [1] = {fireRate = "-10%"},  -- 10% faster attack speed at level 1
            [2] = {fireRate = "-15%"},  -- 15% faster attack speed at level 2
            [3] = {fireRate = "-20%"}   -- 20% faster attack speed at level 3
        }
    },
    
    -- Damage passive
    {
        id = "damage_boost",
        displayName = "Power Amp",
        colour = rgb(255, 66, 66),
        rarity = "rare",
        maxLevel = 3,
        effects = {
            [1] = {damage = "+15%"},    -- 15% increased damage at level 1
            [2] = {damage = "+25%"},    -- 25% increased damage at level 2
            [3] = {damage = "+40%"}     -- 40% increased damage at level 3
        }
    },
    
    -- Projectile Speed passive
    {
        id = "projectile_speed",
        displayName = "Velocity Mix",
        colour = rgb(66, 255, 186),
        rarity = "common",
        maxLevel = 3,
        effects = {
            [1] = {projectileSpeed = "+20%"},  -- 20% faster projectiles at level 1
            [2] = {projectileSpeed = "+35%"},  -- 35% faster projectiles at level 2
            [3] = {projectileSpeed = "+50%"}   -- 50% faster projectiles at level 3
        }
    },
    
    -- Range passive
    {
        id = "range_boost",
        displayName = "Far Reach",
        colour = rgb(179, 66, 255),
        rarity = "uncommon",
        maxLevel = 3,
        effects = {
            [1] = {range = "+15%"},     -- 15% increased range at level 1
            [2] = {range = "+30%"},     -- 30% increased range at level 2
            [3] = {range = "+50%"}      -- 50% increased range at level 3
        }
    }
}

-- Function to validate all item definitions have required fields and proper formatting
local function validateAll()
    local function validateWeapon(weapon)
        -- Check required fields
        assert(weapon.id, "Weapon missing id")
        assert(weapon.displayName, "Weapon missing displayName")
        assert(weapon.colour, "Weapon missing colour")
        assert(weapon.rarity, "Weapon missing rarity")
        assert(weapon.category, "Weapon missing category")
        assert(weapon.maxLevel, "Weapon missing maxLevel")
        assert(weapon.behaviour, "Weapon missing behaviour")
        assert(weapon.stats, "Weapon missing stats table")
        assert(weapon.levelUps, "Weapon missing levelUps table")
        
        -- Process level-up modifiers
        for stat, modifier in pairs(weapon.levelUps) do
            local mode, value
            
            -- Check if it's a percentage or flat modifier
            if string.find(modifier, "%%") then
                mode = "percent"
                value = tonumber(string.match(modifier, "([%-%d%.]+)%%"))
            else
                mode = "flat"
                value = tonumber(string.match(modifier, "([%-%d%.]+)"))
            end
            
            assert(value, "Invalid modifier format: " .. modifier)
            
            -- Replace string with structured data
            weapon.levelUps[stat] = {mode = mode, value = value}
        end
    end
    
    local function validatePassive(passive)
        -- Check required fields
        assert(passive.id, "Passive missing id")
        assert(passive.displayName, "Passive missing displayName")
        assert(passive.colour, "Passive missing colour")
        assert(passive.rarity, "Passive missing rarity")
        assert(passive.maxLevel, "Passive missing maxLevel")
        assert(passive.effects, "Passive missing effects table")
        
        -- Process effects for all levels
        for level, effects in pairs(passive.effects) do
            for stat, modifier in pairs(effects) do
                local mode, value
                
                -- Check if it's a percentage or flat modifier
                if string.find(modifier, "%%") then
                    mode = "percent"
                    value = tonumber(string.match(modifier, "([%-%d%.]+)%%"))
                else
                    mode = "flat"
                    value = tonumber(string.match(modifier, "([%-%d%.]+)"))
                end
                
                assert(value, "Invalid modifier format: " .. modifier)
                
                -- Replace string with structured data
                passive.effects[level][stat] = {mode = mode, value = value}
            end
        end
    end
    
    -- Validate all weapons
    for _, weapon in ipairs(weapons) do
        validateWeapon(weapon)
    end
    
    -- Validate all passives
    for _, passive in ipairs(passives) do
        validatePassive(passive)
    end
    
    return true
end

-- Run validation on load
validateAll()

-- Return the complete definitions
return {
    weapons = weapons,
    passives = passives,
    rgb = rgb -- Export the helper function too
}
