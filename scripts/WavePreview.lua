-- Shows what the next wave brings while the player is still building

local GameState = require("scripts.GameState")

local WavePreview = {
    properties = {
        { name = "background", displayName = "Background", type = "Image" },
        { name = "icon1", displayName = "Icon 1", type = "Image" },
        { name = "count1", displayName = "Count 1", type = "Text" },
        { name = "icon2", displayName = "Icon 2", type = "Image" },
        { name = "count2", displayName = "Count 2", type = "Text" },
        { name = "icon3", displayName = "Icon 3", type = "Image" },
        { name = "count3", displayName = "Count 3", type = "Text" },
        { name = "icon4", displayName = "Icon 4", type = "Image" },
        { name = "count4", displayName = "Count 4", type = "Text" },
    },
}

local ICONS = {
    scout = "ui/icon_scout.png",
    raider = "ui/icon_raider.png",
    brute = "ui/icon_brute.png",
    boss = "ui/icon_mothership.png",
}

function WavePreview:init()
    self.slots = {
        { icon = self.icon1, count = self.count1 },
        { icon = self.icon2, count = self.count2 },
        { icon = self.icon3, count = self.count3 },
        { icon = self.icon4, count = self.count4 },
    }
    RegisterEngineEvent(self, "onUpdate")
end

-- each part on its own: a parent made visible would show the unused slots too
function WavePreview:show(wave)
    self.background.visible = wave ~= nil
    for i, slot in ipairs(self.slots) do
        local group = wave and wave[i]
        slot.icon.visible = group ~= nil
        slot.count.visible = group ~= nil
        if group then
            slot.icon:setTexture(ICONS[group[1]])
            slot.count.text = "x" .. group[2]
        end
    end
end

function WavePreview:onUpdate()
    local director = GameState.director
    local wave = nil
    if director and GameState.phase == "build" then
        wave = director.waves[GameState.wave + 1]
    end
    if wave ~= self.wave then
        self.wave = wave
        self:show(wave)
    end
end

return WavePreview
