-- event.lua
-- Simple event system for Groove Bound

local Event = {
    -- Storage for all defined events
    definitions = {},
    
    -- Storage for all event callbacks
    listeners = {},
    
    -- Debug flag
    debug = false
}

-- Define a new event type with expected parameters
function Event.define(eventName, parameterNames)
    if not eventName then
        error("Event.define: Missing event name")
    end
    
    -- Store the event definition
    Event.definitions[eventName] = {
        parameters = parameterNames or {}
    }
    
    -- Initialize listener table for this event
    Event.listeners[eventName] = Event.listeners[eventName] or {}
    
    if Event.debug then
        print("Event defined: " .. eventName)
    end
end

-- Dispatch an event to all listeners
function Event.dispatch(eventName, data)
    if not Event.listeners[eventName] then
        if Event.debug then
            print("Warning: No listeners for event " .. eventName)
        end
        return
    end
    
    -- Copy data to prevent modification
    local eventData = data or {}
    
    if Event.debug then
        print("Dispatching event: " .. eventName)
    end
    
    -- Notify all listeners
    for _, listener in ipairs(Event.listeners[eventName]) do
        listener(eventData)
    end
end

-- Subscribe to an event
function Event.subscribe(eventName, callback)
    -- Create listener table if it doesn't exist
    Event.listeners[eventName] = Event.listeners[eventName] or {}
    
    -- Add the callback
    table.insert(Event.listeners[eventName], callback)
    
    if Event.debug then
        print("Added listener for event: " .. eventName)
    end
    
    -- Return an unsubscribe function
    return function()
        -- Find and remove this specific callback
        for i, cb in ipairs(Event.listeners[eventName]) do
            if cb == callback then
                table.remove(Event.listeners[eventName], i)
                if Event.debug then
                    print("Removed listener for event: " .. eventName)
                end
                return
            end
        end
    end
end

-- Remove all listeners for an event
function Event.clearListeners(eventName)
    if eventName then
        Event.listeners[eventName] = {}
    else
        -- Clear all listeners if no event name given
        Event.listeners = {}
    end
    
    if Event.debug then
        print("Cleared listeners for: " .. (eventName or "ALL EVENTS"))
    end
end

-- Enable or disable debug output
function Event.setDebug(enabled)
    Event.debug = enabled
end

-- Return the module
return Event
