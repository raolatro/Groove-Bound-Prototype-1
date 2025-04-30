-- UI Configuration for Groove Bound
-- Defines grid, camera, and arena parameters

-- Block grid configuration
local GRID = {
    base = 32,  -- Base grid size in pixels (can be 8, 16, 32)
    
    -- Precomputed values for convenience
    half = 16,  -- Half of base size
    quarter = 8 -- Quarter of base size
}

-- Camera configuration
local CAMERA = {
    lag = 0.15,        -- Smoothing factor (0-1): 0 = instant snap, 1 = no movement
    shakeIntensity = 0, -- Current shake intensity
    shakeDuration = 0,  -- Remaining shake duration
    zoomLevel = 1       -- Current zoom level
}

-- Arena configuration
local ARENA = {
    w = 4096,           -- Arena width in pixels
    h = 4096,           -- Arena height in pixels
    wallThickness = 64, -- Border wall thickness
    obstacleCount = 24, -- Number of obstacles to generate
    obstacleMinSize = 2, -- Minimum obstacle size in grid units
    obstacleMaxSize = 6  -- Maximum obstacle size in grid units
}

return {
    GRID = GRID,
    CAMERA = CAMERA,
    ARENA = ARENA
}
