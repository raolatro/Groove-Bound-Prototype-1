-- Weapons configuration for Groove Bound
-- Defines all weapon types and their properties

local PATHS = require("config.paths")

-- Weapon categories
local CATEGORIES = {
    PISTOL = "pistol",
    SHOTGUN = "shotgun", 
    RIFLE = "rifle"
}

-- Weapon definition table
local WEAPONS = {
    -- Pistol Category
    pistol = {
        id = "pistol",
        name = "Pistol",
        slot = "sidearm",
        category = CATEGORIES.PISTOL,
        damage = 10,
        cooldown = 0.4,
        projectileSpeed = 600,
        projectileCount = 1,
        spread = 0.05,          -- radians
        area = 5,               -- projectile radius
        sprite = PATHS.ASSETS.SPRITES.WEAPONS.PISTOL,
        projectileSprite = PATHS.ASSETS.SPRITES.PROJECTILES.BULLET,
        sfx = PATHS.ASSETS.AUDIO.SFX.WEAPONS.PISTOL,
        -- Category-specific attributes
        catAttrib = {
            clipSize = 8,
            reloadTime = 1.0
        },
        -- Weapon-specific attributes
        weaponAttrib = {
            accuracy = 0.9,     -- 0.0 to 1.0
            critChance = 0.05   -- 5% chance
        }
    },
    
    revolver = {
        id = "revolver",
        name = "Revolver",
        slot = "sidearm",
        category = CATEGORIES.PISTOL,
        damage = 25,
        cooldown = 0.7,
        projectileSpeed = 700,
        projectileCount = 1,
        spread = 0.02,
        area = 6,
        sprite = PATHS.ASSETS.SPRITES.WEAPONS.PISTOL, -- Placeholder
        projectileSprite = PATHS.ASSETS.SPRITES.PROJECTILES.BULLET,
        sfx = PATHS.ASSETS.AUDIO.SFX.WEAPONS.PISTOL,  -- Placeholder
        catAttrib = {
            clipSize = 6,
            reloadTime = 1.5
        },
        weaponAttrib = {
            accuracy = 0.95,
            critChance = 0.15
        }
    },
    
    -- Pistol Evolution (placeholder)
    magnum = {
        id = "magnum",
        name = "Magnum",
        slot = "sidearm",
        category = CATEGORIES.PISTOL,
        damage = 40,
        cooldown = 0.8,
        projectileSpeed = 800,
        projectileCount = 1,
        spread = 0.01,
        area = 7,
        sprite = PATHS.ASSETS.SPRITES.WEAPONS.PISTOL, -- Placeholder
        projectileSprite = PATHS.ASSETS.SPRITES.PROJECTILES.BULLET,
        sfx = PATHS.ASSETS.AUDIO.SFX.WEAPONS.PISTOL,  -- Placeholder
        catAttrib = {
            clipSize = 6,
            reloadTime = 1.8
        },
        weaponAttrib = {
            accuracy = 0.98,
            critChance = 0.25,
            piercing = 1        -- Can pierce through 1 enemy
        }
    },
    
    -- Shotgun Category
    shotgun = {
        id = "shotgun",
        name = "Shotgun",
        slot = "primary",
        category = CATEGORIES.SHOTGUN,
        damage = 8,
        cooldown = 1.0,
        projectileSpeed = 500,
        projectileCount = 6,    -- Multiple pellets
        spread = 0.2,           -- Wide spread
        area = 3,               -- Each pellet is small
        sprite = PATHS.ASSETS.SPRITES.WEAPONS.SHOTGUN,
        projectileSprite = PATHS.ASSETS.SPRITES.PROJECTILES.SHELL,
        sfx = PATHS.ASSETS.AUDIO.SFX.WEAPONS.SHOTGUN,
        catAttrib = {
            shellsPerReload = 2,
            reloadTime = 0.5,   -- Per shell
            knockback = 100     -- Force applied to hit enemies
        },
        weaponAttrib = {
            range = 300,        -- Effective range
            falloff = 0.5       -- Damage reduction at maximum range
        }
    },
    
    autoshotgun = {
        id = "autoshotgun",
        name = "Auto Shotgun",
        slot = "primary",
        category = CATEGORIES.SHOTGUN,
        damage = 7,
        cooldown = 0.7,
        projectileSpeed = 550,
        projectileCount = 5,
        spread = 0.25,
        area = 3,
        sprite = PATHS.ASSETS.SPRITES.WEAPONS.SHOTGUN, -- Placeholder
        projectileSprite = PATHS.ASSETS.SPRITES.PROJECTILES.SHELL,
        sfx = PATHS.ASSETS.AUDIO.SFX.WEAPONS.SHOTGUN,  -- Placeholder
        catAttrib = {
            shellsPerReload = 8,
            reloadTime = 0.3,   -- Per shell, faster reload
            knockback = 80
        },
        weaponAttrib = {
            range = 250,
            falloff = 0.6
        }
    },
    
    -- Shotgun Evolution (placeholder)
    combatshotgun = {
        id = "combatshotgun",
        name = "Combat Shotgun",
        slot = "primary",
        category = CATEGORIES.SHOTGUN,
        damage = 9,
        cooldown = 0.5,
        projectileSpeed = 600,
        projectileCount = 8,
        spread = 0.18,
        area = 4,
        sprite = PATHS.ASSETS.SPRITES.WEAPONS.SHOTGUN, -- Placeholder
        projectileSprite = PATHS.ASSETS.SPRITES.PROJECTILES.SHELL,
        sfx = PATHS.ASSETS.AUDIO.SFX.WEAPONS.SHOTGUN,  -- Placeholder
        catAttrib = {
            shellsPerReload = 12,
            reloadTime = 0.25,
            knockback = 120
        },
        weaponAttrib = {
            range = 350,
            falloff = 0.4,
            armorPiercing = 0.5 -- Ignores 50% of enemy armor
        }
    },
    
    -- Rifle Category
    rifle = {
        id = "rifle",
        name = "Rifle",
        slot = "primary",
        category = CATEGORIES.RIFLE,
        damage = 15,
        cooldown = 0.15,
        projectileSpeed = 900,
        projectileCount = 1,
        spread = 0.08,
        area = 4,
        sprite = PATHS.ASSETS.SPRITES.WEAPONS.RIFLE,
        projectileSprite = PATHS.ASSETS.SPRITES.PROJECTILES.BULLET,
        sfx = PATHS.ASSETS.AUDIO.SFX.WEAPONS.RIFLE,
        catAttrib = {
            clipSize = 30,
            reloadTime = 2.0,
            recoil = 0.05       -- Added spread per consecutive shot
        },
        weaponAttrib = {
            fireRate = 600,     -- RPM (rounds per minute)
            accuracy = 0.85,
            recoilRecovery = 0.1 -- How quickly spread decreases when not firing
        }
    },
    
    sniper = {
        id = "sniper",
        name = "Sniper Rifle",
        slot = "special",
        category = CATEGORIES.RIFLE,
        damage = 80,
        cooldown = 1.5,
        projectileSpeed = 1500,
        projectileCount = 1,
        spread = 0.01,
        area = 3,
        sprite = PATHS.ASSETS.SPRITES.WEAPONS.SNIPER,
        projectileSprite = PATHS.ASSETS.SPRITES.PROJECTILES.BULLET,
        sfx = PATHS.ASSETS.AUDIO.SFX.WEAPONS.SNIPER,
        catAttrib = {
            clipSize = 5,
            reloadTime = 3.0,
            recoil = 0.2
        },
        weaponAttrib = {
            accuracy = 0.99,
            piercing = 3,        -- Can pierce through multiple enemies
            critMultiplier = 2.5 -- Critical hit multiplier
        }
    },
    
    -- Rifle Evolution (placeholder)
    assaultrifle = {
        id = "assaultrifle",
        name = "Assault Rifle",
        slot = "primary",
        category = CATEGORIES.RIFLE,
        damage = 20,
        cooldown = 0.1,
        projectileSpeed = 950,
        projectileCount = 1,
        spread = 0.05,
        area = 4,
        sprite = PATHS.ASSETS.SPRITES.WEAPONS.RIFLE, -- Placeholder
        projectileSprite = PATHS.ASSETS.SPRITES.PROJECTILES.BULLET,
        sfx = PATHS.ASSETS.AUDIO.SFX.WEAPONS.RIFLE,  -- Placeholder
        catAttrib = {
            clipSize = 45,
            reloadTime = 1.8,
            recoil = 0.03
        },
        weaponAttrib = {
            fireRate = 750,
            accuracy = 0.88,
            recoilRecovery = 0.12,
            armorPiercing = 0.2  -- Ignores 20% of enemy armor
        }
    }
}

return WEAPONS
