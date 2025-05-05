-- State Stack module
-- Manages game states with a stack-based approach allowing pushing, popping, and peeking states
-- Each state can define its own enter, leave, update, and draw methods

-- Initialize the state stack
local StateStack = {}
local stack = {}

-- Initialize the state stack system
-- Called once at game startup to ensure the stack is ready for use
-- @return self - For method chaining
function StateStack:init()
  -- Clear any existing states
  stack = {}
  
  -- Log initialization if logging is available
  if _G.SafeLog then
    SafeLog("SYSTEM", "State stack initialized")
  elseif Logger and Logger.info then
    Logger:info("State stack initialized")
  else
    print("State stack initialized")
  end
  
  return self
end

-- Push a new state onto the stack and call its enter method if available
-- @param state - The state table to push onto the stack
function StateStack:push(state)
  if state.enter then
    state:enter()
  end
  table.insert(stack, state)
end

-- Remove the top state from the stack and call its leave method if available
-- @return The state that was popped from the stack
function StateStack:pop()
  if #stack == 0 then
    return nil
  end
  
  local state = stack[#stack]
  if state.leave then
    state:leave()
  end
  
  table.remove(stack)
  return state
end

-- Get the top state from the stack without removing it
-- @return The top state or nil if stack is empty
function StateStack:peek()
  if #stack == 0 then
    return nil
  end
  
  return stack[#stack]
end

-- Update the current top state
-- @param dt - Delta time in seconds since the last update
function StateStack:update(dt)
  local currentState = self:peek()
  if currentState and currentState.update then
    currentState:update(dt)
  end
end

-- Pass keypressed events to the current top state
-- @param key - The key that was pressed
-- @return boolean - True if the key was handled by the state, false otherwise
function StateStack:keypressed(key)
  local currentState = self:peek()
  if currentState and currentState.keypressed then
    -- Call the state's keypressed handler and get if it was handled
    local handled = currentState:keypressed(key)
    -- Return whether the key was handled by the state
    return handled
  end
  -- No state or no handler means the key wasn't handled
  return false
end

-- Pass keyreleased events to the current top state
-- @param key - The key that was released
function StateStack:keyreleased(key)
  local currentState = self:peek()
  if currentState and currentState.keyreleased then
    currentState:keyreleased(key)
  end
end

-- Pass mousepressed events to the current top state
-- @param x - Mouse X coordinate
-- @param y - Mouse Y coordinate
-- @param button - Mouse button that was pressed
function StateStack:mousepressed(x, y, button)
  local currentState = self:peek()
  if currentState and currentState.mousepressed then
    currentState:mousepressed(x, y, button)
  end
end

-- Pass mousereleased events to the current top state
-- @param x - Mouse X coordinate
-- @param y - Mouse Y coordinate
-- @param button - Mouse button that was released
function StateStack:mousereleased(x, y, button)
  local currentState = self:peek()
  if currentState and currentState.mousereleased then
    currentState:mousereleased(x, y, button)
  end
end

-- Pass mousemoved events to the current top state
-- @param x - Mouse X coordinate
-- @param y - Mouse Y coordinate
-- @param dx - X movement delta
-- @param dy - Y movement delta
function StateStack:mousemoved(x, y, dx, dy)
  local currentState = self:peek()
  if currentState and currentState.mousemoved then
    currentState:mousemoved(x, y, dx, dy)
  end
end

-- Draw the current top state
function StateStack:draw()
  local currentState = self:peek()
  if currentState and currentState.draw then
    currentState:draw()
  end
end

-- Return the module
return StateStack
