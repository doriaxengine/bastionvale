-- Strategy camera: pans over the vale, turns, zooms, and picks build pads on click or tap

local GameState = require("scripts.GameState")

local CameraRig = {
    properties = {
        { name = "focus", displayName = "Focus", type = "vector3", default = { 8, 3, -2 } },
        { name = "distance", displayName = "Distance", type = "float", default = 90 },
        { name = "minDistance", displayName = "Min Distance", type = "float", default = 35 },
        { name = "maxDistance", displayName = "Max Distance", type = "float", default = 110 },
        { name = "pitch", displayName = "Pitch", type = "float", default = 56 },
        { name = "yaw", displayName = "Yaw", type = "float", default = 180 },
        { name = "panSpeed", displayName = "Pan Speed", type = "float", default = 30 },
        { name = "panLimit", displayName = "Pan Limit", type = "float", default = 40 },
        { name = "groundHeight", displayName = "Ground Height", type = "float", default = 3 },
        { name = "pickRadius", displayName = "Pick Radius", type = "float", default = 5 },
    },
}

-- a touch that moves less than this is a tap
local TAP_SLOP = 12

function CameraRig:init()
    self.camera = Camera(self.scene, self.entity)
    self.focusX, self.focusZ = self.focus.x, self.focus.z
    self.zoom = self.distance
    self.ground = Plane(0, 1, 0, -self.groundHeight)
    self.touches = {}

    RegisterEngineEvent(self, "onUpdate")
    RegisterEngineEvent(self, "onMouseDown")
    RegisterEngineEvent(self, "onMouseUp")
    RegisterEngineEvent(self, "onMouseScroll")
    RegisterEngineEvent(self, "onTouchStart")
    RegisterEngineEvent(self, "onTouchMove")
    RegisterEngineEvent(self, "onTouchEnd")

    self:apply()
end

function CameraRig:apply()
    local pitch, yaw = math.rad(self.pitch), math.rad(self.yaw)
    local horizontal = math.cos(pitch) * self.distance
    self.camera:setPosition(
        self.focusX - math.sin(yaw) * horizontal,
        self.groundHeight + math.sin(pitch) * self.distance,
        self.focusZ - math.cos(yaw) * horizontal)
    self.camera:setTarget(self.focusX, self.groundHeight, self.focusZ)
end

-- right and forward on the ground follow the camera's yaw
function CameraRig:pan(right, forward)
    local yaw = math.rad(self.yaw)
    local sin, cos = math.sin(yaw), math.cos(yaw)
    local limit = self.panLimit
    self.focusX = math.max(-limit, math.min(limit, self.focusX - right * cos + forward * sin))
    self.focusZ = math.max(-limit, math.min(limit, self.focusZ + right * sin + forward * cos))
end

-- screen pixels to world units at the current zoom
function CameraRig:dragScale()
    return self.distance / math.max(1, Engine.canvasHeight) * 1.6
end

function CameraRig:pick(x, y)
    local hit = self.camera:screenToRay(x, y):intersects(self.ground)
    if hit and hit.hit then
        GameState.select(GameState.padAt(hit.point.x, hit.point.z, self.pickRadius))
    end
end

function CameraRig:onUpdate()
    local dt = math.min(Engine.deltatime, 0.1)

    if not GameState.paused then
        local step = self.panSpeed * self.distance / 90 * dt
        local right, forward = 0, 0
        if Input.isKeyPressed(Input.KEY_A) or Input.isKeyPressed(Input.KEY_LEFT) then right = right - step end
        if Input.isKeyPressed(Input.KEY_D) or Input.isKeyPressed(Input.KEY_RIGHT) then right = right + step end
        if Input.isKeyPressed(Input.KEY_W) or Input.isKeyPressed(Input.KEY_UP) then forward = forward + step end
        if Input.isKeyPressed(Input.KEY_S) or Input.isKeyPressed(Input.KEY_DOWN) then forward = forward - step end
        if Input.isKeyPressed(Input.KEY_Q) then self.yaw = self.yaw - 70 * dt end
        if Input.isKeyPressed(Input.KEY_E) then self.yaw = self.yaw + 70 * dt end

        if self.dragging then
            local mouse = Input.getMousePosition()
            local scale = self:dragScale()
            right = right - (mouse.x - self.dragX) * scale
            forward = forward + (mouse.y - self.dragY) * scale
            self.dragX, self.dragY = mouse.x, mouse.y
        end
        if right ~= 0 or forward ~= 0 then
            self:pan(right, forward)
        end
    end

    self.distance = self.distance + (self.zoom - self.distance) * math.min(1, 10 * dt)
    self:apply()
end

function CameraRig:onMouseDown(button, x, y, mods)
    if GameState.paused then return end
    if button == Input.MOUSE_BUTTON_LEFT then
        self:pick(x, y)
    elseif button == Input.MOUSE_BUTTON_RIGHT or button == Input.MOUSE_BUTTON_MIDDLE then
        self.dragging = true
        self.dragX, self.dragY = x, y
    end
end

function CameraRig:onMouseUp(button, x, y, mods)
    if button == Input.MOUSE_BUTTON_RIGHT or button == Input.MOUSE_BUTTON_MIDDLE then
        self.dragging = false
    end
end

function CameraRig:onMouseScroll(xoffset, yoffset, mods)
    if GameState.paused then return end
    self.zoom = math.max(self.minDistance, math.min(self.maxDistance, self.zoom - yoffset * 8))
end

-- one finger pans (or taps a pad), two fingers pinch to zoom
function CameraRig:onTouchStart(pointer, x, y)
    self.touches[pointer] = { x = x, y = y, startX = x, startY = y }
    self.pinch = nil
end

function CameraRig:touchCount()
    local count = 0
    for _ in pairs(self.touches) do count = count + 1 end
    return count
end

function CameraRig:onTouchMove(pointer, x, y)
    local touch = self.touches[pointer]
    if not touch or GameState.paused then return end

    if self:touchCount() == 1 then
        if math.abs(x - touch.startX) + math.abs(y - touch.startY) > TAP_SLOP then
            touch.moved = true
        end
        if touch.moved then
            local scale = self:dragScale()
            self:pan(-(x - touch.x) * scale, (y - touch.y) * scale)
        end
    else
        touch.moved = true
        local a, b
        for _, other in pairs(self.touches) do
            if not a then a = other else b = other end
        end
        touch.x, touch.y = x, y
        local spread = math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)
        if self.pinch and spread > 0 then
            self.zoom = math.max(self.minDistance, math.min(self.maxDistance, self.zoom * self.pinch / spread))
            self.distance = self.zoom
        end
        self.pinch = spread
    end
    touch.x, touch.y = x, y
end

function CameraRig:onTouchEnd(pointer, x, y)
    local touch = self.touches[pointer]
    self.touches[pointer] = nil
    self.pinch = nil
    if touch and not touch.moved and self:touchCount() == 0 and not GameState.paused then
        self:pick(x, y)
    end
end

return CameraRig
