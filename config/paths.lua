-- Path configuration for Groove Bound
-- Centralizes all file path references

local PATHS = {
    -- Asset paths
    ASSETS = {
        ROOT = "assets/",
        SPRITES = {
            ROOT = "assets/sprites/",
            PLAYER = "assets/sprites/player_walk.png",
            WEAPONS = {
                ROOT = "assets/sprites/weapons/",
                PISTOL = "assets/sprites/weapons/pistol.png",
                SHOTGUN = "assets/sprites/weapons/shotgun.png",
                MACHINEGUN = "assets/sprites/weapons/machinegun.png",
                RIFLE = "assets/sprites/weapons/rifle.png",
                SNIPER = "assets/sprites/weapons/sniper.png",
                LAUNCHER = "assets/sprites/weapons/launcher.png"
            },
            PROJECTILES = {
                ROOT = "assets/sprites/projectiles/",
                BULLET = "assets/sprites/projectiles/bullet.png",
                SHELL = "assets/sprites/projectiles/shell.png",
                ROCKET = "assets/sprites/projectiles/rocket.png"
            },
            -- Arena graphics
            FLOOR = "assets/sprites/environment/floor.png",
            WALL = "assets/sprites/environment/wall.png",
            OBSTACLE = "assets/sprites/environment/obstacle.png"
        },
        FONTS = {
            ROOT = "assets/fonts/",
            PRESS_START = "assets/fonts/m6x11plus.ttf"
        },
        AUDIO = {
            ROOT = "assets/audio/",
            SFX = {
                ROOT = "assets/audio/sfx/",
                WEAPONS = {
                    ROOT = "assets/audio/sfx/weapons/",
                    PISTOL = "assets/audio/sfx/weapons/pistol.wav",
                    SHOTGUN = "assets/audio/sfx/weapons/shotgun.wav",
                    MACHINEGUN = "assets/audio/sfx/weapons/machinegun.wav",
                    RIFLE = "assets/audio/sfx/weapons/rifle.wav",
                    SNIPER = "assets/audio/sfx/weapons/sniper.wav",
                    LAUNCHER = "assets/audio/sfx/weapons/launcher.wav"
                }
            }
        }
    },
    
    -- Source code paths
    SRC = {
        ROOT = "src/",
        STATES = {
            PLAY = "src/game_play.lua"
        },
        ENTITIES = {
            PLAYER = "src/player.lua",
            PROJECTILE = "src/projectile.lua"
        },
        WEAPONS = {
            ROOT = "src/weapons/",
            BASE = "src/weapons/base.lua",
            MANAGER = "src/weapon_manager.lua"
        }
    },
    
    -- Config paths
    CONFIG = {
        ROOT = "config/",
        SETTINGS = "config/settings.lua",
        PATHS = "config/paths.lua",
        WEAPONS = "config/weapons.lua"
    },
    
    -- Libraries
    LIB = {
        ROOT = "lib/",
        LOADER = "lib/loader.lua",
        HUMP = {
            ROOT = "lib/hump/",
            GAMESTATE = "lib/hump/gamestate.lua",
            TIMER = "lib/hump/timer.lua",
            CLASS = "lib/hump/class.lua",
            VECTOR = "lib/hump/vector.lua"
        },
        WINDFIELD = "lib/windfield/",
        ANIM8 = "lib/anim8/anim8.lua"
    }
}

return PATHS
