-- Debug entry point with step-by-step initialization for troubleshooting

-- Basic LÖVE callbacks that don't depend on any modules
function love.load()
    print("Debug load started")
    
    -- Use pcall to capture errors
    local status, err = pcall(function()
        -- Step 1: Test package path setup
        print("Step 1: Setting up package path")
        package.path = package.path .. ";" .. love.filesystem.getSource() .. "/?.lua"
        
        -- Step 2: Test basic module loading one by one
        print("Step 2: Loading core modules")
        
        print("  Loading paths...")
        local Paths = require("src/core/paths")
        print("  Paths loaded successfully")
        
        print("  Loading settings...")
        local Settings = require("src/core/settings")
        print("  Settings loaded successfully")
        
        print("  Loading state_stack...")
        local StateStack = require("src/core/state_stack")
        print("  StateStack loaded successfully")
        
        print("  Loading event_bus...")
        local EventBus = require("src/core/event_bus")
        print("  EventBus loaded successfully")
        
        print("  Loading logger...")
        local Logger = require("src/core/logger")
        print("  Logger loaded successfully")
        
        print("  Loading input...")
        local Input = require("src/core/input")
        print("  Input loaded successfully")
        
        print("  Loading debug_display...")
        local Debug = require("src/ui/debug_display")
        print("  Debug_display loaded successfully")
        
        print("  Loading block_grid...")
        local BlockGrid = require("src/ui/block_grid")
        print("  BlockGrid loaded successfully")
        
        -- Step 3: Set up global references
        print("Step 3: Setting up global references")
        _G.Paths = Paths
        _G.Settings = Settings
        _G.StateStack = StateStack
        _G.EventBus = EventBus
        _G.Logger = Logger
        _G.Debug = Debug
        _G.BlockGrid = BlockGrid
        _G.Input = Input
        
        -- Step 4: Initialize core systems
        print("Step 4: Initializing core systems")
        Debug:init()
        BlockGrid:init()
        Input:init()
        
        -- Step 5: Test loading boot state
        print("Step 5: Loading boot state")
        local BootSplash = require("src/ui/states/boot_splash")
        StateStack:push(BootSplash)
        
        print("All initialization steps completed successfully!")
    end)
    
    if not status then
        print("ERROR DURING INITIALIZATION: " .. tostring(err))
        -- Store the error for display
        _G.init_error = err
    end
end

function love.update(dt)
    if StateStack then
        StateStack:update(dt)
    end
    
    if Debug then
        Debug.update(dt)
    end
end

function love.draw()
    -- Draw initialization error if there was one
    if _G.init_error then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.print("ERROR: " .. tostring(_G.init_error), 50, 50, 0, 1.5, 1.5)
        love.graphics.print("Check the console for more details", 50, 100)
        return
    end
    
    -- If initialization succeeded, draw normally
    if StateStack then
        StateStack:draw()
    end
    
    if Debug then
        Debug.draw()
    end
end

-- Simple error handler that prints to console
function love.errorhandler(msg)
    print("ERROR: " .. tostring(msg))
    print(debug.traceback())
    return false
end
