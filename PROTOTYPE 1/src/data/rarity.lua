-- rarity.lua
-- Handles rarity-based item selection and provides helper functions for the level-up shop

local Debug = require("src.debug")
local Config = require("config.settings")

-- Local shorthand
local DEV = Config.DEV
local TUNING = Config.TUNING

local Rarity = {}

-- Colors for different rarity tiers (RGBA)
Rarity.colors = {
    common = {0.7, 0.7, 0.7, 1.0},       -- Grey
    rare = {0.3, 0.5, 1.0, 1.0},         -- Blue
    epic = {0.8, 0.3, 0.9, 1.0},         -- Purple
    legendary = {1.0, 0.8, 0.2, 1.0}     -- Gold
}

-- Hex color versions (for UI rendering)
Rarity.hexColors = {
    common = "#B3B3B3",                  -- Grey
    rare = "#4D80FF",                    -- Blue
    epic = "#CC4DCC",                    -- Purple
    legendary = "#FFD700"                -- Gold
}

-- Order of rarities from lowest to highest
Rarity.order = {"common", "rare", "epic", "legendary"}

-- Computes the adjusted weights for each rarity tier based on player's luck
-- @param luck Player's luck stat
-- @return Table with adjusted weights for each rarity tier
function Rarity.computeWeights(luck)
    -- Get base values and shifts from config
    local base = TUNING.LUCK.BASE
    local shift = TUNING.LUCK.SHIFT
    local minCommon = TUNING.LUCK.MIN_COMMON
    local maxLegendary = TUNING.LUCK.MAX_LEGENDARY
    
    -- Calculate adjusted weights based on luck
    local weights = {
        common = math.max(minCommon, base.common + (shift.common * luck)),
        rare = math.max(0, base.rare + (shift.rare * luck)),
        epic = math.max(0, base.epic + (shift.epic * luck)),
        legendary = math.min(maxLegendary, math.max(0, base.legendary + (shift.legendary * luck)))
    }
    
    -- Normalize weights to ensure they sum to 1
    local total = weights.common + weights.rare + weights.epic + weights.legendary
    weights.common = weights.common / total
    weights.rare = weights.rare / total
    weights.epic = weights.epic / total
    weights.legendary = weights.legendary / total
    
    -- Debug output if needed
    if DEV.DEBUG_MASTER then
        Debug.log(string.format("Rarity weights (luck %.1f): common=%.3f, rare=%.3f, epic=%.3f, legendary=%.3f", 
            luck, weights.common, weights.rare, weights.epic, weights.legendary))
    end
    
    return weights
end

-- Selects a rarity tier using a roulette wheel selection based on weights
-- @param weights Table of weights for each rarity tier
-- @return String representing the selected rarity tier
function Rarity.pickTier(weights)
    local roll = love.math.random()
    local cumulativeChance = 0
    
    for _, tier in ipairs(Rarity.order) do
        cumulativeChance = cumulativeChance + weights[tier]
        if roll <= cumulativeChance then
            return tier
        end
    end
    
    -- Fallback (should never happen if weights are properly normalized)
    return "common"
end

-- Generates a user-friendly description of an item effect for display
-- @param effect The effect table with modifiers
-- @return String with a concise summary of the level effect
function Rarity.buildEffectSummary(effect)
    if not effect or type(effect) ~= "table" then
        return ""
    end
    
    local tokens = {}
    
    -- Convert modifiers to tokens
    for k, v in pairs(effect) do
        local token = ""
        if type(v) == "number" then
            -- Format as percentage or flat bonus
            if k:match("[sS]peed") or k:match("[rR]ate") or k:match("[dD]amage") or k:match("[rR]ange") then
                -- Percentage stats
                if v > 0 then token = string.format("+%d%% %s", v * 100, Rarity.shortenStat(k))
                else token = string.format("%d%% %s", v * 100, Rarity.shortenStat(k)) end
            else
                -- Flat bonuses
                if v > 0 then token = string.format("+%d %s", v, Rarity.shortenStat(k))
                else token = string.format("%d %s", v, Rarity.shortenStat(k)) end
            end
        elseif type(v) == "boolean" and v == true then
            -- Boolean effects like "piercing"
            token = "+" .. Rarity.shortenStat(k)
        elseif type(v) == "string" then
            -- String format values (from levelUps in weapons)
            if v:match("^[%+%-]%d+%%") then
                -- Percentage value like "+10%"
                token = v .. " " .. Rarity.shortenStat(k)
            elseif v:match("^[%+%-]%d+") then
                -- Flat value like "+5"
                token = v .. " " .. Rarity.shortenStat(k)
            else
                -- Other string values
                token = v .. " " .. Rarity.shortenStat(k)
            end
        else
            -- Other effects
            token = tostring(v) .. " " .. Rarity.shortenStat(k)
        end
        
        table.insert(tokens, token)
    end
    
    -- Join all tokens with commas
    return table.concat(tokens, ", ")
end

-- Shortens stat names for display
-- @param stat The stat name to shorten
-- @return Shortened stat name
function Rarity.shortenStat(stat)
    local shortcuts = {
        projectileCount = "proj",
        projectiles = "proj",
        fireRate = "frt",
        damage = "dmg",
        range = "rng",
        area = "aoe",
        cooldown = "cd",
        speed = "spd",
        duration = "dur",
        piercing = "pierce",
        knockback = "knbk",
        radius = "rad",
        critical = "crit",
        lifesteal = "life",
        attackSpeed = "as",
        movementSpeed = "ms"
    }
    
    return shortcuts[stat] or stat
end

return Rarity
