-- What the level scripts and the HUD share

local Towers = require("scripts.Towers")

local GameState = {}

-- the state outside a level, such as on the title screen: no road and no enemies
function GameState.clear()
    GameState.director = nil
    GameState.paused = false
    GameState.speed = 1
    GameState.waveHealth = 1
    GameState.path = {}
    GameState.pads = {}
    GameState.enemies = {}
    GameState.sounds = {}
    GameState.selected = nil
    GameState.building = nil
end

-- LevelDirector calls this from init(). Pads register on their first update, after it.
function GameState.reset(director)
    GameState.clear()
    GameState.director = director
    GameState.levelName = director.levelName
    GameState.gold = director.startGold
    GameState.lives = director.lives
    GameState.maxLives = director.lives
    GameState.wave = 0
    GameState.waveCount = #director.waves
    GameState.countdown = director.firstWaveDelay
    GameState.phase = "build"
    GameState.kills = 0
    GameState.message = ""
    GameState.messageTime = 0
    GameState.result = nil
end

function GameState.say(text, seconds)
    GameState.message = text
    GameState.messageTime = seconds or 2.5
end

function GameState.play(name)
    local sound = GameState.sounds[name]
    if sound then
        sound:stop()
        sound:play()
    end
end

function GameState.refuse(text)
    GameState.say(text)
    GameState.play("denied")
end

function GameState.select(pad)
    local previous = GameState.selected
    GameState.selected = pad
    if previous then previous:refresh() end
    if pad then
        pad:refresh()
        if pad ~= previous then GameState.play("select") end
    end
end

-- the pad closest to a point on the ground, when the point is near one
function GameState.padAt(x, z, radius)
    local best, bestDistance = nil, radius * radius
    for _, pad in ipairs(GameState.pads) do
        local dx, dz = pad.x - x, pad.z - z
        local distance = dx * dx + dz * dz
        if distance < bestDistance then
            best, bestDistance = pad, distance
        end
    end
    return best
end

function GameState.upgradeCost(pad)
    if not pad or not pad.kind then return nil end
    return Towers[pad.kind].upgrades[pad.tier]
end

function GameState.sellValue(pad)
    return math.floor(pad.spent * 0.6)
end

function GameState.build(kind)
    local pad = GameState.selected
    if not pad then
        GameState.refuse("Pick a build pad first")
    elseif pad.kind then
        GameState.refuse("This pad already has a tower")
    elseif GameState.gold < Towers[kind].cost then
        GameState.refuse("Not enough gold")
    else
        GameState.gold = GameState.gold - Towers[kind].cost
        pad:build(kind)
        GameState.play("build")
    end
end

function GameState.upgrade()
    local pad = GameState.selected
    local cost = GameState.upgradeCost(pad)
    if not cost then
        GameState.refuse(pad and pad.kind and "Fully upgraded" or "Pick a tower first")
    elseif GameState.gold < cost then
        GameState.refuse("Not enough gold")
    else
        GameState.gold = GameState.gold - cost
        pad:upgrade(cost)
        GameState.play("upgrade")
    end
end

function GameState.sell()
    local pad = GameState.selected
    if not pad or not pad.kind then
        GameState.refuse("Pick a tower first")
    else
        GameState.gold = GameState.gold + GameState.sellValue(pad)
        pad:sell()
        GameState.play("sell")
    end
end

function GameState.toggleSpeed()
    GameState.speed = GameState.speed == 1 and 2 or 1
end

-- the enemy in range that is furthest down the road
function GameState.findTarget(x, z, range)
    local target
    for _, enemy in ipairs(GameState.enemies) do
        if enemy.health > 0 and (not target or enemy.progress > target.progress) then
            local dx, dz = enemy.x - x, enemy.z - z
            if dx * dx + dz * dz <= range * range then
                target = enemy
            end
        end
    end
    return target
end

function GameState.damageArea(x, z, radius, damage, slow, slowTime)
    for _, enemy in ipairs(GameState.enemies) do
        local dx, dz = enemy.x - x, enemy.z - z
        if enemy.health > 0 and dx * dx + dz * dz <= radius * radius then
            enemy:hit(damage, slow, slowTime)
        end
    end
end

function GameState.removeEnemy(enemy)
    for i, other in ipairs(GameState.enemies) do
        if other == enemy then
            table.remove(GameState.enemies, i)
            return
        end
    end
end

function GameState.enemyKilled(enemy)
    GameState.gold = GameState.gold + enemy.reward
    GameState.kills = GameState.kills + 1
    GameState.play("explosion")
end

function GameState.enemyReachedKeep(enemy)
    if GameState.phase ~= "wave" then return end
    GameState.lives = math.max(0, GameState.lives - enemy.damage)
    GameState.play("leak")
    if GameState.lives == 0 then
        GameState.director:endLevel(false)
    end
end

GameState.clear()

return GameState
