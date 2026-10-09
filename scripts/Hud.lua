-- Shows the level state. Every action goes through HudButton and GameState.

local GameState = require("scripts.GameState")
local Towers = require("scripts.Towers")

local Hud = {
    properties = {
        { name = "livesText", displayName = "Lives Text", type = "Text" },
        { name = "livesFill", displayName = "Lives Fill", type = "Image" },
        { name = "goldText", displayName = "Gold Text", type = "Text" },
        { name = "waveText", displayName = "Wave Text", type = "Text" },
        { name = "countdownText", displayName = "Countdown Text", type = "Text" },
        { name = "messagePanel", displayName = "Message Panel", type = "Image" },
        { name = "messageText", displayName = "Message Text", type = "Text" },
        { name = "hintPanel", displayName = "Hint Panel", type = "Image" },
        { name = "buildPanel", displayName = "Build Panel", type = "Image" },
        { name = "ballistaButton", displayName = "Ballista Button", type = "Button" },
        { name = "cannonButton", displayName = "Cannon Button", type = "Button" },
        { name = "frostButton", displayName = "Frost Button", type = "Button" },
        { name = "towerPanel", displayName = "Tower Panel", type = "Image" },
        { name = "towerIcon", displayName = "Tower Icon", type = "Image" },
        { name = "towerName", displayName = "Tower Name", type = "Text" },
        { name = "towerStats", displayName = "Tower Stats", type = "Text" },
        { name = "star2", displayName = "Star 2", type = "Image" },
        { name = "star3", displayName = "Star 3", type = "Image" },
        { name = "upgradeButton", displayName = "Upgrade Button", type = "Button" },
        { name = "sellButton", displayName = "Sell Button", type = "Button" },
        { name = "waveButton", displayName = "Wave Button", type = "Button" },
        { name = "speedButton", displayName = "Speed Button", type = "Button" },
    },
}

local ICONS = {
    ballista = "ui/icon_ballista.png",
    cannon = "ui/icon_cannon.png",
    frost = "ui/icon_frost.png",
}

function Hud:init()
    self.shown = {}
    self.livesWidth = self.livesFill.width
    RegisterEngineEvent(self, "onUpdate")
end

-- texts only change when their value does
function Hud:set(text, value)
    if self.shown[text] ~= value then
        self.shown[text] = value
        text.text = value
    end
end

function Hud:setLabel(button, value)
    if self.shown[button] ~= value then
        self.shown[button] = value
        button.label = value
    end
end

function Hud:showTower(pad)
    local tower = pad.tower
    if self.towerKind ~= pad.kind then
        self.towerKind = pad.kind
        self.towerIcon:setTexture(ICONS[pad.kind])
    end
    self:set(self.towerName, Towers[pad.kind].name)
    self.star2:setColor(1, 1, 1, pad.tier >= 2 and 1 or 0.25)
    self.star3:setColor(1, 1, 1, pad.tier >= 3 and 1 or 0.25)
    if tower then
        self:set(self.towerStats, string.format("Damage %d   Range %d   %.1f shots/s",
            math.floor(tower:stat("damage") + 0.5), math.floor(tower:stat("range") + 0.5), 1 / tower:stat("reload")))
    end

    local cost = GameState.upgradeCost(pad)
    self.upgradeButton.disabled = not cost or GameState.gold < cost
    self:setLabel(self.upgradeButton, cost and ("Upgrade  " .. cost) or "Max level")
    self:setLabel(self.sellButton, "Sell  " .. GameState.sellValue(pad))
end

function Hud:onUpdate()
    if not GameState.director then return end

    self:set(self.goldText, tostring(GameState.gold))
    self:set(self.livesText, tostring(GameState.lives))
    self.livesFill.width = math.max(18, math.floor(self.livesWidth * GameState.lives / GameState.maxLives))

    if GameState.phase == "build" then
        self:set(self.waveText, "Wave " .. (GameState.wave + 1) .. " of " .. GameState.waveCount)
        self:set(self.countdownText, "Starts in " .. math.max(0, math.ceil(GameState.countdown)))
    else
        self:set(self.waveText, "Wave " .. GameState.wave .. " of " .. GameState.waveCount)
        local left = #GameState.enemies + #GameState.director.queue
        self:set(self.countdownText, left .. (left == 1 and " enemy left" or " enemies left"))
    end

    local calling = GameState.phase == "build"
    self.waveButton.visible = calling
    if calling then
        self:setLabel(self.waveButton, "Next wave  +" .. math.floor(GameState.countdown))
    end
    self:setLabel(self.speedButton, GameState.speed == 1 and "x1" or "x2")

    self.messagePanel.visible = GameState.message ~= ""
    self:set(self.messageText, GameState.message)

    local pad = GameState.selected
    self.hintPanel.visible = pad == nil and GameState.phase ~= "won" and GameState.phase ~= "lost"
    self.buildPanel.visible = pad ~= nil and pad.kind == nil
    self.towerPanel.visible = pad ~= nil and pad.kind ~= nil

    if self.buildPanel.visible then
        self.ballistaButton.disabled = GameState.gold < Towers.ballista.cost
        self.cannonButton.disabled = GameState.gold < Towers.cannon.cost
        self.frostButton.disabled = GameState.gold < Towers.frost.cost
    elseif self.towerPanel.visible then
        self:showTower(pad)
    end
end

return Hud
