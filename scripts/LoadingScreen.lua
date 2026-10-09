-- Fills the loading bar while SceneManager loads the next scene

local LoadingScreen = {
    properties = {
        { name = "fill", displayName = "Fill", type = "Image" },
    },
}

function LoadingScreen:init()
    self.width = self.fill.width
    self.shown = 0
    RegisterEngineEvent(self, "onUpdate")
end

function LoadingScreen:onUpdate()
    if not SceneManager.loading then
        self.shown = 0
        return
    end
    -- eased, so a big step in the progress still reads as movement
    local target = SceneManager.loadingProgress
    self.shown = self.shown + (target - self.shown) * math.min(1, 8 * Engine.deltatime)
    self.fill.width = math.max(18, math.floor(self.width * self.shown))
end

return LoadingScreen
