-- The title menu over the intro scene

local GameState = require("scripts.GameState")

local TitleMenu = {
    properties = {
        { name = "quitButton", displayName = "Quit Button", type = "Button" },
    },
}

function TitleMenu:init()
    GameState.clear()
    -- a browser tab has nothing to quit to
    if self.quitButton and Engine.platform == Platform.Web then
        self.quitButton.visible = false
    end
    RegisterEngineEvent(self, "onKeyDown")
end

function TitleMenu:onKeyDown(key, repeated, mods)
    if not repeated and (key == Input.KEY_ENTER or key == Input.KEY_SPACE) then
        SceneManager.loadScene("Green Vale")
    end
end

return TitleMenu
