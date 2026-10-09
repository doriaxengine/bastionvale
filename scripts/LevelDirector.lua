-- Runs a level: the road, the waves, pause and the end screens

local GameState = require("scripts.GameState")
local Waves = require("scripts.Waves")

local LevelDirector = {
    properties = {
        { name = "levelName", displayName = "Level Name", type = "string", default = "Green Vale" },
        { name = "nextLevel", displayName = "Next Level", type = "string", default = "" },
        { name = "startGold", displayName = "Start Gold", type = "int", default = 190 },
        { name = "lives", displayName = "Lives", type = "int", default = 20 },
        { name = "firstWaveDelay", displayName = "First Wave Delay", type = "float", default = 20 },
        { name = "waveDelay", displayName = "Wave Delay", type = "float", default = 12 },
        { name = "road", displayName = "Road", type = "Object" },
    },
}

local ENEMIES = {
    scout = "bundles/Scout",
    raider = "bundles/Raider",
    brute = "bundles/Brute",
    boss = "bundles/Mothership",
}

local SOUNDS = { "Build", "Upgrade", "Sell", "Denied", "Select", "Wave", "Leak", "Explosion" }

function LevelDirector:init()
    self.waves = Waves[self.levelName] or {}
    self.queue = {}
    self.spawnTimer = 0
    self.endTimer = 0

    GameState.reset(self)

    for _, name in ipairs(SOUNDS) do
        local entity = self.scene:findEntity(name .. " Sound")
        if entity ~= NULL_ENTITY then
            GameState.sounds[name:lower()] = Sound(self.scene, entity)
        end
    end

    GameState.say("Build towers along the road", 4)

    RegisterEngineEvent(self, "onUpdate")
    RegisterEngineEvent(self, "onKeyDown")
end

-- world positions are only known after the first update
function LevelDirector:readRoad()
    local path = {}
    while true do
        local entity = self.scene:findEntity("Waypoint " .. (#path + 1), self.road.entity)
        if entity == NULL_ENTITY then break end
        path[#path + 1] = Object(self.scene, entity):getWorldPosition()
    end
    if #path < 2 then
        Log.error("LevelDirector: the road needs at least two waypoints")
    end
    GameState.path = path
end

function LevelDirector:startWave()
    local wave = self.waves[GameState.wave + 1]
    if not wave then return end

    GameState.wave = GameState.wave + 1
    GameState.waveHealth = wave.health
    GameState.phase = "wave"

    self.queue = {}
    for _, group in ipairs(wave) do
        for _ = 1, group[2] do
            self.queue[#self.queue + 1] = group[1]
        end
    end
    self.gap = wave.gap
    self.spawnTimer = 0

    GameState.say("Wave " .. GameState.wave .. " of " .. #self.waves)
    GameState.play("wave")
end

-- the seconds left on the clock pay out as gold
function LevelDirector:callWave()
    if GameState.phase ~= "build" or GameState.paused then return end
    local bonus = math.floor(GameState.countdown)
    self:startWave()
    if bonus > 0 then
        GameState.gold = GameState.gold + bonus
        GameState.say("Early call  +" .. bonus .. " gold")
    end
end

function LevelDirector:waveCleared()
    if GameState.wave >= #self.waves then
        self:endLevel(true)
        return
    end
    local bonus = 20 + GameState.wave * 5
    GameState.gold = GameState.gold + bonus
    GameState.phase = "build"
    GameState.countdown = self.waveDelay
    GameState.say("Wave cleared  +" .. bonus .. " gold", 3)
end

function LevelDirector:endLevel(won)
    if GameState.phase == "won" or GameState.phase == "lost" then return end
    GameState.phase = won and "won" or "lost"
    GameState.select(nil)
    self.endTimer = won and 1.5 or 1.0

    local key = self.levelName:lower():gsub(" ", "")
    local score = GameState.kills * 10 + GameState.lives * 50 + GameState.gold
    local stars = 0
    if won then
        stars = 1
        if GameState.lives >= GameState.maxLives / 2 then stars = 2 end
        if GameState.lives == GameState.maxLives then stars = 3 end
        if stars > UserSettings.getIntegerForKey(key .. "_stars", 0) then
            UserSettings.setIntegerForKey(key .. "_stars", stars)
        end
    end
    local best = math.max(score, UserSettings.getIntegerForKey(key .. "_best", 0))
    UserSettings.setIntegerForKey(key .. "_best", best)

    GameState.result = {
        won = won,
        score = score,
        best = best,
        stars = stars,
        levelName = self.levelName,
        nextLevel = self.nextLevel,
    }
end

function LevelDirector:setPaused(paused)
    GameState.paused = paused
    self.scene:getActionSystem().paused = paused
    self.scene:getAudioSystem().paused = paused
end

function LevelDirector:togglePause()
    if GameState.phase == "won" or GameState.phase == "lost" then return end
    if GameState.paused then
        SceneManager.removeChildScene("Pause Scene")
        self:setPaused(false)
    else
        self:setPaused(true)
        SceneManager.addChildScene("Pause Scene")
    end
end

function LevelDirector:onKeyDown(key, repeated, mods)
    if repeated then return end

    if key == Input.KEY_ESCAPE and GameState.selected and not GameState.paused then
        GameState.select(nil)
    elseif key == Input.KEY_ESCAPE or key == Input.KEY_P then
        self:togglePause()
    elseif GameState.paused then
        return
    elseif key == Input.KEY_1 then
        GameState.build("ballista")
    elseif key == Input.KEY_2 then
        GameState.build("cannon")
    elseif key == Input.KEY_3 then
        GameState.build("frost")
    elseif key == Input.KEY_U then
        GameState.upgrade()
    elseif key == Input.KEY_X or key == Input.KEY_DELETE then
        GameState.sell()
    elseif key == Input.KEY_SPACE or key == Input.KEY_N then
        self:callWave()
    elseif key == Input.KEY_F then
        GameState.toggleSpeed()
    end
end

function LevelDirector:onUpdate()
    if not self.ready then
        self:readRoad()
        self.ready = true
    end
    if GameState.paused then return end

    local realDelta = math.min(Engine.deltatime, 0.1)
    local dt = realDelta * GameState.speed

    if GameState.messageTime > 0 then
        GameState.messageTime = GameState.messageTime - realDelta
        if GameState.messageTime <= 0 then GameState.message = "" end
    end

    if GameState.phase == "build" then
        GameState.countdown = GameState.countdown - dt
        if GameState.countdown <= 0 then
            self:startWave()
        end
    elseif GameState.phase == "wave" then
        if #self.queue > 0 then
            self.spawnTimer = self.spawnTimer - dt
            if self.spawnTimer <= 0 then
                self.spawnTimer = self.gap
                BundleManager.createBundle(ENEMIES[table.remove(self.queue, 1)], self.scene)
            end
        elseif #GameState.enemies == 0 then
            self:waveCleared()
        end
    elseif not self.finished then
        self.endTimer = self.endTimer - realDelta
        if self.endTimer <= 0 then
            self.finished = true
            self:setPaused(true)
            SceneManager.addChildScene(GameState.phase == "won" and "Victory Scene" or "Defeat Scene")
        end
    end
end

return LevelDirector
