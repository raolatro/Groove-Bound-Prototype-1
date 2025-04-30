-- Arena module for Groove Bound
-- Creates and manages the arena floor and outer walls

local L = require("lib.loader")
local Config = require("config.settings")
local UI = require("config.ui")
local PATHS = require("config.paths")
local BlockGrid = require("src.ui.block_grid")

-- Shorthand for readability
local DEV = Config.DEV
local ARENA = UI.ARENA
local BG = UI.GRID

-- Local debug flag, ANDed with master debug
local DEBUG_WALLS = false

-- Physics collision classes
local COLLISION_CLASSES = {
    ENVIRONMENT = "environment",
    PLAYER = "player",
    ENEMY = "enemy",
    PROJECTILE = "projectile"
}

-- Arena module
local Arena = {
    walls = {},       -- Container for wall objects
    floorColor = {0.2, 0.2, 0.2, 1}, -- Dark gray
    wallColor = {0.4, 0.4, 0.5, 1},  -- Blue-gray
    width = ARENA.w,
    height = ARENA.h
}

-- Create arena elements
function Arena:init(world)
    self.world = world
    self.walls = {}
    
    -- Register collision classes
    world:addCollisionClass(COLLISION_CLASSES.ENVIRONMENT)
    world:addCollisionClass(COLLISION_CLASSES.PLAYER, 
        {ignores = {}})
    world:addCollisionClass(COLLISION_CLASSES.ENEMY, 
        {ignores = {}})
    world:addCollisionClass(COLLISION_CLASSES.PROJECTILE, 
        {ignores = {}})
    
    -- Create outer walls
    local thickness = ARENA.wallThickness
    
    -- Create outer walls (top, right, bottom, left)
    self:createWall(ARENA.w / 2, thickness / 2, ARENA.w, thickness) -- Top
    self:createWall(ARENA.w - thickness / 2, ARENA.h / 2, thickness, ARENA.h) -- Right
    self:createWall(ARENA.w / 2, ARENA.h - thickness / 2, ARENA.w, thickness) -- Bottom
    self:createWall(thickness / 2, ARENA.h / 2, thickness, ARENA.h) -- Left
    
    -- Load floor texture if available
    self.floorTexture = L.Asset.safeImage(PATHS.ASSETS.SPRITES.FLOOR, ARENA.w, ARENA.h)
    
    -- Debug output
    if DEBUG_WALLS and DEV.DEBUG_MASTER then
        print("Arena initialized: " .. ARENA.w .. "x" .. ARENA.h)
        print("Walls created: " .. #self.walls)
    end
end

-- Create a single wall
function Arena:createWall(x, y, width, height)
    -- Create wall object
    local wall = self.world:newRectangleCollider(x - width / 2, y - height / 2, width, height)
    
    wall:setType("static")
    wall:setCollisionClass(COLLISION_CLASSES.ENVIRONMENT)
    
    -- Add to environment group for later reference
    wall.isWall = true
    
    -- Save dimensions for drawing
    wall.width = width
    wall.height = height
    
    -- Create hitbox for debugging/visibility
    wall.hitbox = {
        x = x,
        y = y,
        w = width,
        h = height
    }
    
    -- Store wall
    table.insert(self.walls, wall)
    
    return wall
end

-- Draw the arena
function Arena:draw()
    -- Draw floor
    love.graphics.setColor(self.floorColor)
    if self.floorTexture then
        love.graphics.draw(self.floorTexture, 0, 0)
    else
        love.graphics.rectangle("fill", 0, 0, self.width, self.height)
        
        -- Draw grid for reference in debug mode
        if DEV.DEBUG_GRID and DEV.DEBUG_MASTER then
            love.graphics.setColor(0.3, 0.3, 0.3, 0.2)
            for x = 0, self.width, BG.base do
                love.graphics.line(x, 0, x, self.height)
            end
            for y = 0, self.height, BG.base do
                love.graphics.line(0, y, self.width, y)
            end
        end
    end
    
    -- Draw walls
    love.graphics.setColor(self.wallColor)
    for _, wall in ipairs(self.walls) do
        local x1, y1, x2, y2 = wall:getBoundingBox()
        love.graphics.rectangle("fill", x1, y1, x2 - x1, y2 - y1)
    end
    
    -- Draw debug hitboxes
    if DEBUG_WALLS and DEV.DEBUG_MASTER then
        love.graphics.setColor(1, 0, 1, 0.5) -- Magenta
        for _, wall in ipairs(self.walls) do
            local x1, y1, x2, y2 = wall:getBoundingBox()
            love.graphics.rectangle("line", x1, y1, x2 - x1, y2 - y1)
        end
    end
end

-- Handle key press
function Arena:keypressed(key)
    -- Toggle walls debug (requires master debug to be on)
    if key == Config.CONTROLS.KEYBOARD.DEBUG.TOGGLE_WALLS and not love.keyboard.isDown("lshift", "rshift") then
        DEBUG_WALLS = not DEBUG_WALLS
        DEV.DEBUG_WALLS = DEBUG_WALLS
        if DEV.DEBUG_MASTER then
            print("Walls debug: " .. (DEBUG_WALLS and "ON" or "OFF"))
        end
    end
end

-- Get collision class names
function Arena:getCollisionClasses()
    return COLLISION_CLASSES
end

return Arena
