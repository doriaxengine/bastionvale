-- A HUD button. The same commands are on the keyboard, see LevelDirector:onKeyDown().

local GameState = require("scripts.GameState")

local HudButton = {
    properties = {
        { name = "action", displayName = "Action", type = "string", default = "build" },
        { name = "tower", displayName = "Tower", type = "string", default = "ballista" },
        { name = "click", displayName = "Click Sound", type = "Sound" },
    },
}

function HudButton:init()
    local button = Button(self.scene, self.entity)
    RegisterEvent(self, button:getButtonComponent().onPress, "onPress")
end

function HudButton:onPress()
    local director = GameState.director
    if not director or (GameState.paused and self.action ~= "pause") then return end

    if self.click then
        self.click:stop()
        self.click:play()
    end

    if self.action == "build" then
        GameState.build(self.tower)
    elseif self.action == "upgrade" then
        GameState.upgrade()
    elseif self.action == "sell" then
        GameState.sell()
    elseif self.action == "wave" then
        director:callWave()
    elseif self.action == "speed" then
        GameState.toggleSpeed()
    elseif self.action == "pause" then
        director:togglePause()
    end
end

return HudButton
