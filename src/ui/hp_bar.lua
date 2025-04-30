-- hp_bar.lua
-- Displays the player's health with a red bar under the XP bar

local L = require("lib.loader")
local Config = require("config.settings")
local PATHS = require("config.paths")

-- Constants
local TUNING = Config.TUNING.PLAYER
local DEV = Config.DEV

-- The HPBar module
local HPBar = {
    -- UI positioning and sizing
    x = 20,
    y = 0, -- Will be set based on XP bar position
    width = 200,
    height = 8, -- Thinner than XP bar
    padding = 1,
    
    -- Fonts
    font = nil,
    smallFont = nil,
    
    -- Colors
    backgroundColor = {0.2, 0.1, 0.1, 0.7},
    borderColor = {0.5, 0.2, 0.2, 0.8},
    fillColor = {0.9, 0.2, 0.2, 0.9}, -- Red for health
    textColor = {1, 1, 1, 1},
    
    -- References
    player = nil,
    xpBar = nil, -- Reference to XP bar for positioning
    
    -- State
    visible = true,
    initialized = false,
    fullHPFadeTimer = 0, -- For fading effect when at full HP
    damageFlashTimer = 0, -- For flashing effect when taking damage
}

-- Initialize the HP bar
function HPBar:init(player, xpBar)
    -- Store references
    self.player = player
    self.xpBar = xpBar
    
    -- Load fonts
    self.font = love.graphics.newFont(12)
    self.smallFont = love.graphics.newFont(10)
    
    -- Position just below XP bar
    self:updatePosition()
    
    -- Mark as initialized
    self.initialized = true
    
    return self
end

-- Update position based on XP bar
function HPBar:updatePosition()
    if self.xpBar then
        self.x = self.xpBar.x
        self.width = self.xpBar.width
        self.y = self.xpBar.y + self.xpBar.height + 2 -- 2px gap
    end
end

-- Update the HP bar
function HPBar:update(dt)
    -- Skip if not initialized
    if not self.initialized then
        return
    end
    
    -- Make sure position is synced with XP bar
    self:updatePosition()
    
    -- Update fade timer for full HP effect
    local maxHP = Config.TUNING.PLAYER.MAX_HP
    
    if self.player and self.player.currentHP and maxHP and self.player.currentHP >= maxHP then
        self.fullHPFadeTimer = self.fullHPFadeTimer + dt
        if self.fullHPFadeTimer > 3 then
            -- Start fading after 3 seconds at full HP
            -- Will be used in draw to reduce alpha
        end
    else
        self.fullHPFadeTimer = 0
    end
    
    -- Update damage flash timer
    if self.damageFlashTimer > 0 then
        self.damageFlashTimer = self.damageFlashTimer - dt
    end
end

-- Called when player takes damage
function HPBar:onDamage()
    self.damageFlashTimer = 0.2 -- Flash for 0.2 seconds
    self.fullHPFadeTimer = 0 -- Reset full HP fade
end

-- Draw the HP bar
function HPBar:draw()
    -- Skip if not initialized or not visible
    if not self.initialized or not self.visible then
        return
    end
    
    -- Skip if no player reference
    if not self.player then
        return
    end
    
    -- Store current graphics state
    local r, g, b, a = love.graphics.getColor()
    local font = love.graphics.getFont()
    
    -- Calculate fill percentage
    local currentHP = self.player.currentHP or 0
    local maxHP = Config.TUNING.PLAYER.MAX_HP or 200
    local healthPercent = math.max(0, math.min(1, currentHP / maxHP))
    
    -- Calculate fade for full HP
    local alpha = 1.0
    if self.fullHPFadeTimer > 3 then
        alpha = 0.3 + 0.7 * math.abs(math.sin(love.timer.getTime() * 0.5))
    end
    
    -- Calculate flash effect
    local flashIntensity = 0
    if self.damageFlashTimer > 0 then
        flashIntensity = self.damageFlashTimer / 0.2
    end
    
    -- Draw HP bar background
    love.graphics.setColor(self.backgroundColor[1], self.backgroundColor[2], 
                          self.backgroundColor[3], self.backgroundColor[4] * alpha)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 3, 3)
    
    -- Draw HP fill with potential flash effect
    local fillColor = {
        self.fillColor[1] + flashIntensity * (1 - self.fillColor[1]),
        self.fillColor[2] * (1 - flashIntensity),
        self.fillColor[3] * (1 - flashIntensity),
        self.fillColor[4] * alpha
    }
    
    love.graphics.setColor(fillColor)
    local fillWidth = (self.width - self.padding * 2) * healthPercent
    love.graphics.rectangle("fill", self.x + self.padding, self.y + self.padding, 
                          fillWidth, self.height - self.padding * 2, 2, 2)
    
    -- Draw HP bar border
    love.graphics.setColor(self.borderColor[1], self.borderColor[2], 
                          self.borderColor[3], self.borderColor[4] * alpha)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 3, 3)
    
    -- Draw HP text if DEBUG_HP is enabled
    if _G.DEBUG_MASTER and (_G.DEBUG_HP == true) then
        love.graphics.setFont(self.smallFont)
        love.graphics.setColor(1, 1, 1, alpha)
        
        local hpText = string.format("HP %d/%d", currentHP, maxHP)
        local textWidth = self.smallFont:getWidth(hpText)
        
        -- Center the text
        love.graphics.print(hpText, 
            self.x + (self.width - textWidth) / 2, 
            self.y + (self.height - self.smallFont:getHeight()) / 2 - 1)
    end
    
    -- Restore graphics state
    love.graphics.setColor(r, g, b, a)
    love.graphics.setFont(font)
end

-- Return the module
return HPBar
