-- block_grid.lua
-- A utility for grid-based UI layout

-- The BlockGrid module
local BlockGrid = {
    -- Default cell size
    cellSize = 32,
    
    -- Grid dimensions
    width = 0,
    height = 0,
    
    -- Flag for whether grid has been initialized
    initialized = false
}

-- Initialize grid with cell size
function BlockGrid:init(cellSize)
    -- Store cell size
    self.cellSize = cellSize or 32
    
    -- Get screen dimensions
    self.width = math.floor(love.graphics.getWidth() / self.cellSize)
    self.height = math.floor(love.graphics.getHeight() / self.cellSize)
    
    -- Mark as initialized
    self.initialized = true
    
    return self
end

-- Convert grid position to screen coordinates (center of cell)
function BlockGrid:gridToScreenCenter(gridX, gridY)
    return (gridX - 0.5) * self.cellSize, (gridY - 0.5) * self.cellSize
end

-- Convert grid position to screen coordinates (top-left of cell)
function BlockGrid:gridToScreen(gridX, gridY)
    return (gridX - 1) * self.cellSize, (gridY - 1) * self.cellSize
end

-- Convert screen coordinates to grid position
function BlockGrid:screenToGrid(screenX, screenY)
    return math.floor(screenX / self.cellSize) + 1, math.floor(screenY / self.cellSize) + 1
end

-- Get grid dimensions
function BlockGrid:getDimensions()
    return self.width, self.height
end

-- Get cell size
function BlockGrid:getCellSize()
    return self.cellSize
end

-- Get cell size as vector
function BlockGrid:getCellSizeVector()
    return {x = self.cellSize, y = self.cellSize}
end

-- Calculate grid cell width and height for a rectangle
function BlockGrid:calculateCellSize(screenWidth, screenHeight, gridWidth, gridHeight)
    local cellWidth = screenWidth / gridWidth
    local cellHeight = screenHeight / gridHeight
    return cellWidth, cellHeight
end

-- Draw grid lines (for debugging)
function BlockGrid:drawDebugGrid(r, g, b, a)
    -- Store current color
    local oldR, oldG, oldB, oldA = love.graphics.getColor()
    
    -- Set grid line color
    love.graphics.setColor(r or 0.3, g or 0.3, b or 0.3, a or 0.5)
    
    -- Draw vertical lines
    for x = 0, love.graphics.getWidth(), self.cellSize do
        love.graphics.line(x, 0, x, love.graphics.getHeight())
    end
    
    -- Draw horizontal lines
    for y = 0, love.graphics.getHeight(), self.cellSize do
        love.graphics.line(0, y, love.graphics.getWidth(), y)
    end
    
    -- Restore color
    love.graphics.setColor(oldR, oldG, oldB, oldA)
end

-- Handle window resize
function BlockGrid:resize(w, h)
    -- Update grid dimensions
    self.width = math.floor(w / self.cellSize)
    self.height = math.floor(h / self.cellSize)
end

-- Return the module
return BlockGrid
