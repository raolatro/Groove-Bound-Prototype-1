-- Paths module
-- Contains all file paths used in the game to avoid hard-coding
-- All assets and file paths should be referenced from here

-- Get the game source directory using LÖVE's file system
-- This ensures we have the correct path regardless of platform
local root = love.filesystem.getSource()

-- Define paths relative to the game's root directory
-- Using forward slashes which work on all platforms
local sprites = root .. "/assets/placeholders/"
local audio = root .. "/assets/placeholders/"
local fonts = root .. "/assets/placeholders/"
local logs = root .. "/logs/"

-- Return module to make it available for require
return {
  root = root,
  sprites = sprites,
  audio = audio,
  fonts = fonts,
  logs = logs
}
