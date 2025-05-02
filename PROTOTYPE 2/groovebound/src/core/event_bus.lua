-- Event Bus module
-- Implements a simple event system for game-wide communication
-- Allows components to listen for and emit events without direct coupling

-- Initialize the event system
local EventBus = {}
local listeners = {}

-- Register a function to be called when an event is emitted
-- @param event - The event name to listen for (use "*" to listen to all events)
-- @param fn - The function to call when the event is emitted
function EventBus:on(event, fn)
  if not listeners[event] then
    listeners[event] = {}
  end
  table.insert(listeners[event], fn)
end

-- Remove a function from the listeners for an event
-- @param event - The event name to remove the listener from
-- @param fn - The function to remove
function EventBus:off(event, fn)
  if not listeners[event] then
    return
  end
  
  for i, listener in ipairs(listeners[event]) do
    if listener == fn then
      table.remove(listeners[event], i)
      break
    end
  end
end

-- Emit an event to all registered listeners
-- @param event - The event name to emit
-- @param data - Optional data to pass to the listeners
function EventBus:emit(event, data)
  -- Call specific event listeners
  if listeners[event] then
    for _, fn in ipairs(listeners[event]) do
      fn(data)
    end
  end
  
  -- Call wildcard listeners that receive all events
  if event ~= "*" and listeners["*"] then
    for _, fn in ipairs(listeners["*"]) do
      fn({ event = event, data = data })
    end
  end
end

-- Return the module
return EventBus
