-- The victory and defeat screens, shown over the frozen level

local GameState = require("scripts.GameState")
local MenuButton = require("scripts.MenuButton")

local ResultScreen = {
    properties = {
        { name = "scoreText", displayName = "Score Text", type = "Text" },
        { name = "bestText", displayName = "Best Text", type = "Text" },
        { name = "detailText", displayName = "Detail Text", type = "Text" },
        { name = "star1", displayName = "Star 1", type = "Image" },
        { name = "star2", displayName = "Star 2", type = "Image" },
        { name = "star3", displayName = "Star 3", type = "Image" },
        { name = "nextButton", displayName = "Next Button", type = "Button" },
        { name = "jingle", displayName = "Jingle", type = "Sound" },
    },
}

function ResultScreen:init()
    RegisterEngineEvent(self, "onUpdate")
    RegisterEngineEvent(self, "onKeyDown")
end

function ResultScreen:show()
    local result = GameState.result
    self.won = result.won
    self.hasNext = result.nextLevel ~= ""

    if self.scoreText then self.scoreText.text = "Score  " .. result.score end
    if self.bestText then self.bestText.text = "Best  " .. result.best end
    if self.detailText then
        self.detailText.text = "Broke through on wave " .. GameState.wave .. " of " .. GameState.waveCount
    end
    if self.star1 then
        for i, star in ipairs({ self.star1, self.star2, self.star3 }) do
            if i > result.stars then star:setColor(0.35, 0.26, 0.18, 1) end
        end
    end
    if self.nextButton then
        self.nextButton.visible = self.hasNext
    end
    if self.jingle then self.jingle:play() end
end

-- built with the level and only run when the level ends, so it fills in once it shows
function ResultScreen:onUpdate()
    if not Engine.isSceneRunning(self.scene) then
        self.shown = false
        return
    end
    if not self.shown and GameState.result then
        self.shown = true
        self.wait = 0.4 -- not the key press that ended the level
        self:show()
    end
    if self.wait then self.wait = self.wait - Engine.deltatime end
end

function ResultScreen:onKeyDown(key, repeated, mods)
    if repeated or not self.shown or self.wait > 0 then return end
    if key == Input.KEY_ENTER or key == Input.KEY_SPACE then
        if not self.won then
            MenuButton.run("restart")
        else
            MenuButton.run(self.hasNext and "next" or "menu", "Intro Scene")
        end
    elseif key == Input.KEY_ESCAPE then
        MenuButton.run("menu", "Intro Scene")
    end
end

return ResultScreen
