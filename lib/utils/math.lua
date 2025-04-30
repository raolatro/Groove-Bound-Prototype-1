-- math.lua
-- Math utility functions for Groove Bound

local Math = {}

-- Normalize a vector to unit length (magnitude of 1)
function Math.normalize(x, y)
    local length = math.sqrt(x * x + y * y)
    if length > 0 then
        return x / length, y / length
    else
        return 0, 0
    end
end

-- Calculate distance between two points
function Math.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Linear interpolation
function Math.lerp(a, b, t)
    return a + (b - a) * t
end

-- Clamp a value between min and max
function Math.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Return a random value between min and max
function Math.random(min, max)
    return min + math.random() * (max - min)
end

-- Return the module
return Math
