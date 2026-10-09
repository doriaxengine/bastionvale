-- A level on the title menu: stars and best score, locked until the level before is won

local LevelCard = {
    properties = {
        { name = "levelName", displayName = "Level Name", type = "string", default = "Green Vale" },
        { name = "unlockedBy", displayName = "Unlocked By", type = "string", default = "" },
        { name = "star1", displayName = "Star 1", type = "Image" },
        { name = "star2", displayName = "Star 2", type = "Image" },
        { name = "star3", displayName = "Star 3", type = "Image" },
        { name = "bestText", displayName = "Best Text", type = "Text" },
        { name = "playButton", displayName = "Play Button", type = "Button" },
        { name = "lockText", displayName = "Lock Text", type = "Text" },
    },
}

local function key(levelName)
    return levelName:lower():gsub(" ", "")
end

function LevelCard:init()
    local stars = UserSettings.getIntegerForKey(key(self.levelName) .. "_stars", 0)
    local best = UserSettings.getIntegerForKey(key(self.levelName) .. "_best", 0)
    local locked = self.unlockedBy ~= "" and UserSettings.getIntegerForKey(key(self.unlockedBy) .. "_stars", 0) == 0

    for i, star in ipairs({ self.star1, self.star2, self.star3 }) do
        if i > stars then star:setColor(0.35, 0.26, 0.18, 1) end
    end
    self.bestText.text = best > 0 and ("Best  " .. best) or "Not played yet"
    self.bestText.visible = not locked
    self.playButton.disabled = locked
    self.lockText.visible = locked
    self.locked = locked
end

return LevelCard
