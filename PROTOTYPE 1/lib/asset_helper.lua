-- Asset Helper for Groove Bound
-- Provides safe loading of assets with placeholder fallbacks

local PATHS = require("config.paths")
local Config = require("config.settings")

-- Shorthand for readability
local DEV = Config.DEV

-- Local debug flag, ANDed with master debug
local DEBUG_ASSETS = false

-- Cache for generated placeholder textures
local placeholderCache = {}

-- Asset Helper module
local AssetHelper = {}

-- Create a placeholder image with a magenta checker pattern
local function createPlaceholder(width, height)
    width = width or 32
    height = height or 32
    
    -- Generate a unique cache key
    local cacheKey = width .. "x" .. height
    
    -- Return cached placeholder if available
    if placeholderCache[cacheKey] then
        return placeholderCache[cacheKey]
    end
    
    -- Create new image data
    local imageData = love.image.newImageData(width, height)
    
    -- Define colors
    local magenta = {1, 0, 1, 1}      -- RGB: 255, 0, 255 (Magenta)
    local darkMagenta = {0.5, 0, 0.5, 1} -- RGB: 128, 0, 128 (Dark Magenta)
    
    -- Draw checker pattern
    local checkerSize = math.min(8, math.floor(width / 4), math.floor(height / 4))
    for y = 0, height - 1 do
        for x = 0, width - 1 do
            local checkerX = math.floor(x / checkerSize)
            local checkerY = math.floor(y / checkerSize)
            local isEven = (checkerX + checkerY) % 2 == 0
            
            local color = isEven and magenta or darkMagenta
            imageData:setPixel(x, y, color[1], color[2], color[3], color[4])
        end
    end
    
    -- Create image from data
    local image = love.graphics.newImage(imageData)
    
    -- Cache the placeholder
    placeholderCache[cacheKey] = image
    
    return image
end

-- Safely load an image, falling back to a placeholder if the file doesn't exist
function AssetHelper.safeImage(path, width, height)
    -- Check if file exists
    local success, fileInfo = pcall(love.filesystem.getInfo, path, "file")
    
    if success and fileInfo then
        -- File exists, load it normally
        return love.graphics.newImage(path)
    else
        -- File doesn't exist, create placeholder
        local placeholder = createPlaceholder(width, height)
        
        -- Print warning message
        local pathInfo = path or "nil path"
        print("[AssetHelper] placeholder created for missing file: " .. pathInfo)
        
        if DEBUG_ASSETS and DEV.DEBUG_MASTER then
            print("[AssetHelper] using " .. width .. "x" .. height .. " placeholder")
        end
        
        return placeholder
    end
end

-- Safely load an audio source (stub for future implementation)
function AssetHelper.safeSource(path)
    -- TODO: Implement placeholder audio functionality
    -- Check if file exists
    local success, fileInfo = pcall(love.filesystem.getInfo, path, "file")
    
    if success and fileInfo then
        -- File exists, load it normally
        return love.audio.newSource(path, "static")
    else
        -- File doesn't exist, return nil for now
        print("[AssetHelper] missing audio file: " .. path)
        return nil
    end
end

-- Handle key press
function AssetHelper.keypressed(key)
    -- Toggle asset debug (requires master debug to be on)
    if key == Config.CONTROLS.KEYBOARD.DEBUG.TOGGLE_ASSETS and love.keyboard.isDown("lshift", "rshift") then
        DEBUG_ASSETS = not DEBUG_ASSETS
        if DEV.DEBUG_MASTER then
            print("Asset debug: " .. (DEBUG_ASSETS and "ON" or "OFF"))
        end
    end
end

return AssetHelper
