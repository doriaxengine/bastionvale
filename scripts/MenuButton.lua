-- A button on the menus and on the pause and end screens

local GameState = require("scripts.GameState")

local MenuButton = {
    properties = {
        { name = "action", displayName = "Action", type = "string", default = "play" },
        { name = "targetScene", displayName = "Target Scene", type = "string", default = "Green Vale" },
        { name = "click", displayName = "Click Sound", type = "Sound" },
    },
}

function MenuButton:init()
    local button = Button(self.scene, self.entity)
    RegisterEvent(self, button:getButtonComponent().onPress, "onPress")
end

function MenuButton:onPress()
    if self.click then
        self.click:stop()
        self.click:play()
    end
    MenuButton.run(self.action, self.targetScene)
end

-- also used by the keyboard shortcuts of the screens
function MenuButton.run(action, targetScene)
    local result = GameState.result
    if action == "resume" then
        GameState.director:togglePause()
    elseif action == "restart" then
        SceneManager.loadScene(GameState.levelName)
    elseif action == "next" then
        local nextLevel = result and result.nextLevel or ""
        SceneManager.loadScene(nextLevel ~= "" and nextLevel or "Intro Scene")
    elseif action == "quit" then
        System.quit()
    else
        SceneManager.loadScene(targetScene)
    end
end

return MenuButton
