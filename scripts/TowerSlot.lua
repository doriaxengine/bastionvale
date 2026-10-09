-- A build pad. Building spawns the tower bundle on it, selling destroys it.

local GameState = require("scripts.GameState")
local Towers = require("scripts.Towers")

local TowerSlot = {
    properties = {
        { name = "marker", displayName = "Marker", type = "Object" },
        { name = "selection", displayName = "Selection", type = "Object" },
        { name = "rangeRing", displayName = "Range Ring", type = "Object" },
        { name = "dust", displayName = "Dust", type = "Particles" },
    },
}

function TowerSlot:init()
    self.object = Object(self.scene, self.entity)
    self.tier = 0
    self.spent = 0
    RegisterEngineEvent(self, "onUpdate")
end

function TowerSlot:onUpdate()
    -- after LevelDirector:init(), which clears the list
    if not self.registered then
        local position = self.object:getWorldPosition()
        self.x, self.y, self.z = position.x, position.y, position.z
        GameState.pads[#GameState.pads + 1] = self
        self.registered = true
        self:refresh()
    end
end

function TowerSlot:refresh()
    local selected = GameState.selected == self
    self.marker.visible = self.kind == nil
    self.selection.visible = selected
    self.rangeRing.visible = selected and self.tower ~= nil
    if self.tower then
        local range = self.tower:stat("range")
        self.rangeRing.scale = Vector3(range, 1, range)
    end
end

function TowerSlot:puff()
    self.dust:reset()
    self.dust:start()
end

function TowerSlot:build(kind)
    -- Tower:init() picks this up and hands itself back as self.tower
    GameState.building = self
    self.towerRoot = BundleManager.createBundle(Towers[kind].bundle, self.scene, self.entity)
    GameState.building = nil

    self.kind = kind
    self.tier = 1
    self.spent = Towers[kind].cost
    self:puff()
    self:refresh()
end

function TowerSlot:upgrade(cost)
    self.tier = self.tier + 1
    self.spent = self.spent + cost
    self.tower:setTier(self.tier)
    self:puff()
    self:refresh()
end

function TowerSlot:sell()
    BundleManager.destroyBundle(self.scene, self.towerRoot)
    self.towerRoot = nil
    self.tower = nil
    self.kind = nil
    self.tier = 0
    self.spent = 0
    self:puff()
    self:refresh()
end

return TowerSlot
