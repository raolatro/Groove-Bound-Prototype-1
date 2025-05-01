-- enemy_defs.lua
-- Defines all enemy types for Groove Bound

local Debug = require("src.debug")

-- Helper function to convert RGB values (0-255) to LÖVE format (0-1)
local function rgb(r, g, b)
    return {r/255, g/255, b/255, 1}
end

-- Helper function to create a random warm-toned color variation of baseColor
-- This creates a color within ±Config.TUNING.ENEMIES.RANDOM_RANGE_PCT of the base
local function randomWarmColour(baseColour)
    local Config = require("config.settings")
    
    -- Only randomize if debugging is enabled and randomize flag is on
    if not (_G.DEBUG_MASTER and _G.DEBUG_ENEMIES and Config.DEV.RANDOMIZE_ENEMIES) then
        return baseColour -- Return the original if not randomizing
    end
    
    local range = Config.TUNING.ENEMIES.RANDOM_RANGE_PCT or 0.2
    
    -- Convert to HSV for better control over the "warmth" of the color
    local r, g, b = baseColour[1], baseColour[2], baseColour[3]
    
    -- Simple RGB shift for now (in real HSV you'd limit hue to warm range 0-60°)
    local randomR = r * (1 + (math.random() * 2 - 1) * range)
    local randomG = g * (1 + (math.random() * 2 - 1) * range)
    local randomB = b * (1 + (math.random() * 2 - 1) * range)
    
    -- Clamp values to valid range
    randomR = math.max(0, math.min(1, randomR))
    randomG = math.max(0, math.min(1, randomG))
    randomB = math.max(0, math.min(1, randomB))
    
    return {randomR, randomG, randomB, baseColour[4] or 1}
end

-- Enemy definitions
local enemies = {
    -- Basic enemy type - a simple slime
    {
        id = "basic_slime",
        displayName = "Slime",
        baseColour = rgb(100, 200, 100), -- Green slime
        type = "ground",
        moveSpeed = 60,
        size = 20, -- hit radius in pixels
        hp = 5,
        spawnRate = 1.0, -- relative spawn rate (higher = more common)
        xpMultiplier = 1, -- base amount of XP dropped when killed
        contactDamage = 30, -- Damage on contact with player
        projectileEnabled = false
    },
    
    -- Spitter enemy - shoots at player
    {
        id = "spitter",
        displayName = "Spitter",
        baseColour = rgb(220, 100, 100), -- Reddish
        type = "ranged",
        moveSpeed = 40, -- Slower than basic enemies
        size = 22,
        hp = 8,
        spawnRate = 0.5, -- Less common than basic enemies
        xpMultiplier = 2, -- Drops more XP
        contactDamage = 30, -- Damage on contact with player
        projectileEnabled = true,
        projectile = {
            fireRate = 1.5, -- Shots per second
            damage = 5,
            cooldown = 2.0, -- Time between shots
            speed = 150, -- Projectile speed
            range = 400, -- Maximum projectile travel distance
            size = 8 -- Projectile size
        }
    },
    
    -- Fast Rusher - quick but fragile
    {
        id = "rusher",
        displayName = "Rusher",
        baseColour = rgb(100, 100, 220), -- Bluish
        type = "ground",
        moveSpeed = 120, -- Very fast
        size = 15, -- Smaller hitbox
        hp = 3, -- Less health
        spawnRate = 0.7,
        xpMultiplier = 1.5,
        contactDamage = 30, -- Higher damage due to speed
        projectileEnabled = false
    },
    
    -- Tank enemy - slow but tough
    {
        id = "tank",
        displayName = "Tank",
        baseColour = rgb(180, 180, 80), -- Yellowish
        type = "ground",
        moveSpeed = 30, -- Very slow
        size = 30, -- Larger hit radius
        hp = 20, -- Much more health
        spawnRate = 0.3, -- Rare spawn
        xpMultiplier = 3, -- Drops lots of XP
        contactDamage = 40, -- Very high contact damage
        projectileEnabled = false
    }
}

-- Validate all enemy definitions
local function validateAll()
    local count = 0
    for _, enemy in ipairs(enemies) do
        -- Check required fields
        assert(enemy.id, "Enemy missing ID")
        assert(enemy.displayName, "Enemy missing display name")
        assert(enemy.baseColour, "Enemy missing base color")
        assert(enemy.type, "Enemy missing type")
        assert(enemy.moveSpeed, "Enemy missing move speed")
        assert(enemy.size, "Enemy missing size")
        assert(enemy.hp, "Enemy missing HP")
        assert(enemy.spawnRate, "Enemy missing spawn rate")
        
        -- Set defaults for optional fields
        enemy.xpMultiplier = enemy.xpMultiplier or 1
        
        -- Validate projectile settings if enabled
        if enemy.projectileEnabled then
            assert(enemy.projectile, "Projectile-enabled enemy missing projectile settings")
            assert(enemy.projectile.fireRate, "Enemy projectile missing fire rate")
            assert(enemy.projectile.damage, "Enemy projectile missing damage")
            assert(enemy.projectile.cooldown, "Enemy projectile missing cooldown")
        end
        
        count = count + 1
    end
    
    Debug.log("Validated " .. count .. " enemy definitions")
    return true
end

-- Run validation
validateAll()

-- Return the complete definitions
return {
    enemies = enemies,
    randomWarmColour = randomWarmColour,
    rgb = rgb
}
