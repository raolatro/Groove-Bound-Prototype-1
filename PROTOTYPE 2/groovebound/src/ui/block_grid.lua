-- Block Grid module
-- Manages the grid system for UI and entity placement
-- Automatically adjusts grid unit size based on window dimensions

local BlockGrid = {
  unit = 16 -- Default grid unit size (16px)
}

-- Initialize the BlockGrid
-- Sets up the initial grid unit size based on window dimensions
function BlockGrid:init()
  -- Calculate grid unit based on current window size
  self:resize(love.graphics.getWidth(), love.graphics.getHeight())
  
  -- Set up window resize callback to automatically adjust grid
  love.resize = function(w, h)
    self:resize(w, h)
  end
end

-- Recalculate grid unit size based on window dimensions
-- width≥1280→16, 800-1279→12, <800→8
-- @param width - The window width
-- @param height - The window height
function BlockGrid:resize(width, height)
  if width >= 1280 then
    self.unit = 16
  elseif width >= 800 then
    self.unit = 12
  else
    self.unit = 8
  end
end

-- Convert grid coordinates to pixel coordinates
-- @param gridX - X position in grid units
-- @param gridY - Y position in grid units
-- @return x, y - Pixel coordinates
function BlockGrid:toPixels(gridX, gridY)
  return gridX * self.unit, gridY * self.unit
end

-- Convert pixel coordinates to grid coordinates (rounded down)
-- @param pixelX - X position in pixels
-- @param pixelY - Y position in pixels
-- @return gridX, gridY - Grid coordinates
function BlockGrid:toGrid(pixelX, pixelY)
  return math.floor(pixelX / self.unit), math.floor(pixelY / self.unit)
end

-- Get a rectangle in pixel coordinates based on grid position and size
-- @param col - Grid column (X position in grid units)
-- @param row - Grid row (Y position in grid units)
-- @param w - Width in grid units
-- @param h - Height in grid units
-- @return x, y, width, height - Rectangle in pixel coordinates
function BlockGrid:grid(col, row, w, h)
  local x, y = self:toPixels(col, row)
  local width = w * self.unit
  local height = h * self.unit
  return x, y, width, height
end

-- Check if a point is inside a grid rectangle
-- @param pointX - X coordinate of the point
-- @param pointY - Y coordinate of the point
-- @param col - Grid column of the rectangle
-- @param row - Grid row of the rectangle
-- @param w - Width of the rectangle in grid units
-- @param h - Height of the rectangle in grid units
-- @return true if the point is inside the rectangle
function BlockGrid:isPointInGrid(pointX, pointY, col, row, w, h)
  local x, y, width, height = self:grid(col, row, w, h)
  return pointX >= x and pointX <= x + width and
         pointY >= y and pointY <= y + height
end

-- Return the module
return BlockGrid
