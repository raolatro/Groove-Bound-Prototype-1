-- Debug module for Groove Bound
-- Provides logging, message queue, and display features

local Config = require("config.settings")
local PATHS = require("config.paths")

-- Shorthand for readability
local DEV = Config.DEV

-- Debug module
local Debug = {
    messages = {},         -- Queue of debug messages
    maxMessages = 30,      -- Maximum number of messages to display
    displayTime = 30,      -- Time each message stays on screen (seconds)
    font = nil             -- Debug font
}

-- Log a message to the debug display
function Debug.log(message)
    if not DEV.DEBUG_MASTER then return end
    
    -- Create timestamp
    local timestamp = os.date("%H:%M:%S")
    
    -- Create new message entry
    local entry = {
        text = "[" .. timestamp .. "] " .. message,
        time = Debug.displayTime
    }
    
    -- Add to queue
    table.insert(Debug.messages, entry)
    
    -- Trim message queue if needed
    if #Debug.messages > Debug.maxMessages then
        table.remove(Debug.messages, 1)
    end
    
    -- Also print to console for convenience
    print(entry.text)
end

-- Update debug messages (remove expired ones)
function Debug.update(dt)
    if not DEV.DEBUG_MASTER then return end
    
    -- Update message timers
    for i = #Debug.messages, 1, -1 do
        Debug.messages[i].time = Debug.messages[i].time - dt
        if Debug.messages[i].time <= 0 then
            table.remove(Debug.messages, i)
        end
    end
end

-- Draw debug messages on screen
function Debug.draw()
    if not DEV.DEBUG_MASTER then return end
    
    -- Initialize font if not already loaded
    if not Debug.font then
        Debug.font = love.graphics.newFont(11) -- Slightly larger font for better visibility
    end
    
    -- Save current font and color
    local prevFont = love.graphics.getFont()
    local r, g, b, a = love.graphics.getColor()
    
    -- Set font
    love.graphics.setFont(Debug.font)
    
    -- Draw message background with higher contrast
    if #Debug.messages > 0 then
        love.graphics.setColor(0, 0, 0, 0.8) -- More opaque background
        love.graphics.rectangle(
            "fill", 
            10, 
            40, 
            500, -- Wider panel for longer messages
            #Debug.messages * 18 + 10 -- Slightly taller rows
        )
        
        -- Add border for visibility
        love.graphics.setColor(1, 1, 0, 0.7) -- Yellow border
        love.graphics.rectangle(
            "line", 
            10, 
            40, 
            500,
            #Debug.messages * 18 + 10
        )
    end
    
    -- Always show at least the master debug status
    if #Debug.messages == 0 then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 10, 40, 180, 25)
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.print("Debug Mode Active", 15, 45)
    end
    
    -- Draw messages with better contrast
    for i, message in ipairs(Debug.messages) do
        -- Brighter text with higher minimum alpha
        local alpha = math.min(1, 0.7 + (message.time / 10))
        love.graphics.setColor(1, 1, 1, alpha)
        
        -- Draw text
        love.graphics.print(
            message.text, 
            15, 
            40 + (i - 1) * 18 + 5
        )
    end
    
    -- Restore previous font and color
    love.graphics.setFont(prevFont)
    love.graphics.setColor(r, g, b, a)
end

-- Clear all debug messages
function Debug.clear()
    Debug.messages = {}
    Debug.log("Debug messages cleared")
end

-- Toggle any individual debug flag
function Debug.toggleFlag(flagName)
    if DEV[flagName] ~= nil then
        DEV[flagName] = not DEV[flagName]
        local status = DEV[flagName] and "ON" or "OFF"
        Debug.log("Debug flag " .. flagName .. ": " .. status)
        
        -- If Master was turned off, clear messages
        if flagName == "DEBUG_MASTER" and not DEV.DEBUG_MASTER then
            Debug.messages = {}
        end
        
        -- Sync the global flag if it exists
        if _G[flagName] ~= nil then
            _G[flagName] = DEV[flagName]
        end
        
        return true
    end
    return false
end

-- Generate a comprehensive debug status report
function Debug.showStatus()
    if not DEV.DEBUG_MASTER then return end
    
    Debug.log("=== DEBUG STATUS ===")
    for k, v in pairs(DEV) do
        if k:match("^DEBUG_") then
            local status = v and "ON" or "OFF"
            Debug.log(k .. ": " .. status)
        end
    end
    Debug.log("===================")
end

-- Key handler for debug toggles
function Debug.keypressed(key, scancode, isrepeat)
    if not key then return end
    
    -- Clear debug messages with F9
    if key == Config.CONTROLS.KEYBOARD.DEBUG.TOGGLE_DEBUG_CLEAR then
        Debug.clear()
        return true
    end
    
    -- Master debug toggle with F3 (no shift)
    if key == Config.CONTROLS.KEYBOARD.DEBUG.TOGGLE_MASTER and 
       not love.keyboard.isDown("lshift", "rshift") then
        Debug.toggleFlag("DEBUG_MASTER")
        return true
    end
    
    -- Show debug status with F1
    if key == "f1" then
        Debug.showStatus()
        return true
    end
    
    return false
end

return Debug
