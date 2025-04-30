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
    displayTime = 10,      -- Time each message stays on screen (seconds)
    font = nil,            -- Debug font (system font)
    enabled = true,        -- Always enabled during prototype phase
    AIM = true             -- Draw aim crosshair and circle
}

-- Log a message to the debug display
function Debug.log(message)
    if not message then return end
    
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
    if not Debug.enabled then return end
    
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
    if not Debug.enabled then return end
    
    -- Initialize font if not already loaded
    if not Debug.font then
        Debug.font = love.graphics.newFont(12) -- System font, size 12
    end
    
    -- Save current font and color
    local prevFont = love.graphics.getFont()
    local r, g, b, a = love.graphics.getColor()
    
    -- Draw message background
    if #Debug.messages > 0 then
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle(
            "fill", 
            10, 
            40, 
            400, 
            #Debug.messages * 16 + 10
        )
    end
    
    -- Set font and draw messages in red
    love.graphics.setFont(Debug.font)
    
    -- Draw messages
    for i, message in ipairs(Debug.messages) do
        -- Red text with alpha based on message freshness
        local alpha = math.min(1, message.time / 2)
        love.graphics.setColor(1, 0, 0, alpha) -- Red color
        
        -- Draw text
        love.graphics.print(
            message.text, 
            15, 
            40 + (i - 1) * 16 + 5
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

-- Handle key press
function Debug.keypressed(key)
    -- Handle F9 to clear debug messages
    if key == Config.CONTROLS.KEYBOARD.DEBUG.TOGGLE_DEBUG_CLEAR then
        Debug.clear()
    end
end

-- Make Debug globally accessible
_G.Debug = Debug

return Debug
