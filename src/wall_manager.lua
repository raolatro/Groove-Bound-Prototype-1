-- Wall Manager for Groove Bound
-- Generates and manages interior obstacles

local L = require("lib.loader")
local Config = require("config.settings")
local UI = require("config.ui")
local BlockGrid = require("src.ui.block_grid")
local PATHS = require("config.paths")

-- Shorthand for readability
local DEV = Config.DEV
local ARENA = UI.ARENA
local BG = UI.GRID

-- Local debug flag, ANDed with master debug
local DEBUG_WALLS = false

-- Wall Manager module
local WallManager = {
    obstacles = {},          -- Container for obstacle objects
    obstacleColor = {0.5, 0.4, 0.35, 1},  -- Brown
    debugColor = {1, 0, 1, 0.5},  -- Magenta
    rng = nil                -- RNG for deterministic generation
}

-- Spawn obstacles
function WallManager:spawn(count, world, seed)
    self.world = world
    self.obstacles = {}
    
    -- Initialize RNG with seed for deterministic generation
    seed = seed or os.time()
    self.rng = love.math.newRandomGenerator(seed)
    
    -- Use the 'environment' collision class directly
    local wallClass = "environment"
    
    -- Debug output
    if DEBUG_WALLS and DEV.DEBUG_MASTER then
        print("Using collision class: " .. wallClass)
    end
    
    -- Debug output
    if DEBUG_WALLS and DEV.DEBUG_MASTER then
        print("Spawning " .. count .. " obstacles with seed: " .. seed)
    end
    
    -- Create obstacles
    local attempts = 0
    local maxAttempts = count * 10 -- Avoid infinite loops
    local minDist = BG.base * 10   -- Minimum distance from other obstacles
    local playerSafeRadius = BG.base * 15 -- Keep area around player spawn clear
    
    while #self.obstacles < count and attempts < maxAttempts do
        attempts = attempts + 1
        
        -- Random size in grid units
        local sizeX = self.rng:random(ARENA.obstacleMinSize, ARENA.obstacleMaxSize)
        local sizeY = self.rng:random(ARENA.obstacleMinSize, ARENA.obstacleMaxSize)
        
        -- Convert to pixels
        local width = sizeX * BG.base
        local height = sizeY * BG.base
        
        -- Ensure obstacle stays within arena with margin
        local margin = ARENA.wallThickness + BG.base
        local x = self.rng:random(margin, ARENA.w - margin - width)
        local y = self.rng:random(margin, ARENA.h - margin - height)
        
        -- Snap to grid
        x = math.floor(x / BG.base) * BG.base
        y = math.floor(y / BG.base) * BG.base
        
        -- Center coordinates
        local centerX = x + width / 2
        local centerY = y + height / 2
        
        -- Check distance from player spawn (center of arena)
        local playerX = ARENA.w / 2
        local playerY = ARENA.h / 2
        local distToPlayer = math.sqrt((centerX - playerX)^2 + (centerY - playerY)^2)
        
        if distToPlayer < playerSafeRadius then
            -- Too close to player spawn, skip
            goto continue
        end
        
        -- Check overlap with existing obstacles
        local overlaps = false
        for _, obs in ipairs(self.obstacles) do
            local ox = obs.hitbox.x
            local oy = obs.hitbox.y
            local ow = obs.hitbox.w
            local oh = obs.hitbox.h
            
            -- Calculate distance between centers
            local dx = math.abs(centerX - (ox + ow/2))
            local dy = math.abs(centerY - (oy + oh/2))
            
            -- Check for overlap with minimum distance
            if dx < (width + ow) / 2 + minDist and dy < (height + oh) / 2 + minDist then
                overlaps = true
                break
            end
        end
        
        if not overlaps then
            -- Create obstacle
            local obstacle = self.world:newRectangleCollider(x, y, width, height)
            obstacle:setType("static")
            obstacle:setCollisionClass(wallClass)
            
            -- Add to environment group for later reference
            obstacle.isObstacle = true
            
            -- Save dimensions for drawing
            obstacle.width = width
            obstacle.height = height
            
            -- Create hitbox for debugging/visibility
            obstacle.hitbox = {
                x = x,
                y = y,
                w = width,
                h = height
            }
            
            -- Load obstacle texture if available
            obstacle.texture = L.Asset.safeImage(PATHS.ASSETS.SPRITES.OBSTACLE, width, height)
            
            -- Store obstacle
            table.insert(self.obstacles, obstacle)
        end
        
        ::continue::
    end
    
    -- Debug output
    if DEBUG_WALLS and DEV.DEBUG_MASTER then
        print("Spawned " .. #self.obstacles .. " obstacles after " .. attempts .. " attempts")
    end
    
    return self.obstacles
end

-- Update obstacles
function WallManager:update(dt)
    -- Not much to update for static obstacles
    -- This function would handle any dynamic behavior of obstacles
end

-- Draw obstacles
function WallManager:draw()
    -- Draw all obstacles
    love.graphics.setColor(self.obstacleColor)
    for _, obstacle in ipairs(self.obstacles) do
        local x1, y1, x2, y2 = obstacle:getBoundingBox()
        
        if obstacle.texture then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(obstacle.texture, x1, y1)
        else
            love.graphics.setColor(self.obstacleColor)
            love.graphics.rectangle("fill", x1, y1, x2 - x1, y2 - y1)
        end
    end
    
    -- Draw debug hitboxes
    if DEBUG_WALLS and DEV.DEBUG_MASTER then
        love.graphics.setColor(self.debugColor) -- Magenta
        for _, obstacle in ipairs(self.obstacles) do
            local x1, y1, x2, y2 = obstacle:getBoundingBox()
            love.graphics.rectangle("line", x1, y1, x2 - x1, y2 - y1)
        end
    end
end

-- Handle key press
function WallManager:keypressed(key)
    -- Toggle walls debug (requires master debug to be on)
    if key == Config.CONTROLS.KEYBOARD.DEBUG.TOGGLE_WALLS and not love.keyboard.isDown("lshift", "rshift") then
        DEBUG_WALLS = not DEBUG_WALLS
        DEV.DEBUG_WALLS = DEBUG_WALLS
        if DEV.DEBUG_MASTER then
            print("Walls debug: " .. (DEBUG_WALLS and "ON" or "OFF"))
        end
    end
end

return WallManager
