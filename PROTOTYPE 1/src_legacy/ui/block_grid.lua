-- Block Grid Layout API for Groove Bound
-- Provides pixel-perfect UI placement with grid snapping

local Config = require("config.settings")
local UI = require("config.ui")

-- Shorthand for readability
local DEV = Config.DEV
local BG = UI.GRID

-- Local debug flag, ANDed with master debug
local DEBUG_GRID = false

-- BlockGrid module
local BlockGrid = {}

-- Update grid size dynamically
function BlockGrid.updateGridSize(newSize)
    if newSize == 8 or newSize == 16 or newSize == 32 then
        BG.base = newSize
        BG.half = newSize / 2
        BG.quarter = newSize / 4
        
        if DEBUG_GRID and DEV.DEBUG_MASTER then
            print("Grid size updated to " .. newSize)
        end
    else
        print("Invalid grid size. Valid options: 8, 16, 32")
    end
end

-- Convert block coordinates to pixel coordinates (snap to grid)
function BlockGrid.toGrid(blockX, blockY)
    return math.floor(blockX * BG.base), math.floor(blockY * BG.base)
end

-- Convert pixel coordinates to block coordinates
function BlockGrid.fromPixels(pixelX, pixelY)
    return math.floor(pixelX / BG.base), math.floor(pixelY / BG.base)
end

-- Get screen dimensions in grid units
function BlockGrid.getScreenGrid()
    local w, h = love.graphics.getDimensions()
    return math.floor(w / BG.base), math.floor(h / BG.base)
end

-- Draw a block with grid alignment
function BlockGrid.drawBlock(blockX, blockY, widthInBlocks, heightInBlocks, color)
    local x, y = BlockGrid.toGrid(blockX, blockY)
    local w = widthInBlocks * BG.base
    local h = heightInBlocks * BG.base
    
    -- Save current color
    local r, g, b, a = love.graphics.getColor()
    
    -- Set new color
    if color then
        love.graphics.setColor(color)
    end
    
    -- Draw filled rectangle
    love.graphics.rectangle("fill", x, y, w, h)
    
    -- Draw grid outline for debugging
    if DEBUG_GRID and DEV.DEBUG_MASTER then
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.rectangle("line", x, y, w, h)
        
        -- Draw grid pattern inside the block
        love.graphics.setColor(1, 1, 1, 0.1)
        for gx = 0, widthInBlocks - 1 do
            for gy = 0, heightInBlocks - 1 do
                love.graphics.rectangle("line", 
                    x + (gx * BG.base), 
                    y + (gy * BG.base), 
                    BG.base, BG.base)
            end
        end
    end
    
    -- Restore original color
    love.graphics.setColor(r, g, b, a)
    
    return x, y, w, h
end

-- Handle key press
function BlockGrid.keypressed(key)
    -- Toggle grid debug (requires master debug to be on)
    if key == Config.CONTROLS.KEYBOARD.DEBUG.TOGGLE_GRID and not love.keyboard.isDown("lshift", "rshift") then
        DEBUG_GRID = not DEBUG_GRID
        DEV.DEBUG_GRID = DEBUG_GRID
        if DEV.DEBUG_MASTER then
            print("Grid debug: " .. (DEBUG_GRID and "ON" or "OFF"))
        end
    end
end

return BlockGrid
