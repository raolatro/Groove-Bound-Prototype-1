-- LÖVE Configuration
function love.conf(t)
    -- Identity
    t.identity = "groovebound"            -- The name of the save directory
    t.version = "11.4"                    -- The LÖVE version this game was made for
    t.console = true                      -- Enable/disable console output

    -- Window Configuration
    t.window.title = "Groove Bound"        -- The window title
    t.window.icon = nil                   -- Path to an icon file
    t.window.width = 1280                 -- Window width
    t.window.height = 720                 -- Window height
    t.window.resizable = false            -- Make window resizable
    t.window.minwidth = 800               -- Minimum window width
    t.window.minheight = 600              -- Minimum window height
    t.window.fullscreen = false           -- Enable fullscreen
    t.window.vsync = 1                    -- Vertical sync mode (0 = off, 1 = on, 2 = adaptive)

    -- Modules configuration
    t.modules.audio = true                -- Enable the audio module
    t.modules.data = true                 -- Enable the data module
    t.modules.event = true                -- Enable the event module
    t.modules.font = true                 -- Enable the font module
    t.modules.graphics = true             -- Enable the graphics module
    t.modules.image = true                -- Enable the image module
    t.modules.joystick = true             -- Enable the joystick module
    t.modules.keyboard = true             -- Enable the keyboard module
    t.modules.math = true                 -- Enable the math module
    t.modules.mouse = true                -- Enable the mouse module
    t.modules.physics = true              -- Enable the physics module
    t.modules.sound = true                -- Enable the sound module
    t.modules.system = true               -- Enable the system module
    t.modules.thread = true               -- Enable the thread module
    t.modules.timer = true                -- Enable the timer module
    t.modules.touch = true                -- Enable the touch module
    t.modules.video = true                -- Enable the video module
    t.modules.window = true               -- Enable the window module

    -- Enable more detailed debug error messages
    t.gammacorrect = false                -- Enable gamma-correct rendering
    t.externalstorage = true              -- Enable external storage
    t.accelerometerjoystick = false       -- Enable accelerometer joystick
end

-- Custom global error handling to catch errors better
local originalErrorHandler = love.errorhandler
love.errorhandler = function(msg)
    -- Log the error to a file first
    local date = os.date("%Y-%m-%d_%H-%M-%S")
    local errorLog = "crash_" .. date .. ".log"
    
    local logContent = "Error occurred: " .. tostring(msg) .. "\n\n"
    logContent = logContent .. debug.traceback(2) .. "\n\n"
    
    -- Try to save the error log
    pcall(function()
        love.filesystem.write(errorLog, logContent)
    end)
    
    -- Call the original error handler
    return originalErrorHandler(msg)
end