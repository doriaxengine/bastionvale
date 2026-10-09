-- Aims the head at the enemy furthest down the road and fires the shot at it.
-- Each tier shows one more story and multiplies the base numbers below.

local GameState = require("scripts.GameState")

local Tower = {
    properties = {
        { name = "damage", displayName = "Damage", type = "float", default = 12 },
        { name = "range", displayName = "Range", type = "float", default = 14 },
        { name = "reload", displayName = "Reload", type = "float", default = 1 },
        { name = "shotSpeed", displayName = "Shot Speed", type = "float", default = 40 },
        { name = "arc", displayName = "Shot Arc", type = "float", default = 0 },
        { name = "splash", displayName = "Splash Radius", type = "float", default = 0 },
        { name = "slow", displayName = "Slow", type = "float", default = 0 },
        { name = "slowTime", displayName = "Slow Time", type = "float", default = 0 },
        { name = "storyHeight", displayName = "Story Height", type = "float", default = 2.4 },
        { name = "middle", displayName = "Middle", type = "Object" },
        { name = "upper", displayName = "Upper", type = "Object" },
        { name = "top", displayName = "Top", type = "Object" },
        { name = "head", displayName = "Head", type = "Object" },
        { name = "shot", displayName = "Shot", type = "Object" },
        { name = "muzzle", displayName = "Muzzle", type = "Particles" },
        { name = "impact", displayName = "Impact", type = "Object" },
        { name = "impactParticles", displayName = "Impact Particles", type = "Particles" },
        { name = "fireSound", displayName = "Fire Sound", type = "Sound" },
    },
}

local TIERS = {
    { damage = 1, range = 1, reload = 1 },
    { damage = 1.6, range = 1.1, reload = 0.88 },
    { damage = 2.5, range = 1.2, reload = 0.76 },
}

function Tower:init()
    -- built on a pad by TowerSlot, or placed in a scene by hand
    self.pad = GameState.building
    if self.pad then
        self.pad.tower = self
        self.x, self.y, self.z = self.pad.x, self.pad.y, self.pad.z
    end

    self.cooldown = 0
    self.yaw = 0
    self.topHeight = self.top.position.y
    self.shot.visible = false
    self:setTier(1)

    RegisterEngineEvent(self, "onUpdate")
end

function Tower:stat(name)
    return self[name] * TIERS[self.tier][name]
end

function Tower:setTier(tier)
    self.tier = tier
    self.middle.visible = tier >= 2
    self.upper.visible = tier >= 3
    self.top:setPosition(0, self.topHeight + (tier - 1) * self.storyHeight, 0)
end

function Tower:muzzlePosition()
    return 0, self.top.position.y + self.head.position.y, 0
end

function Tower:fire(target)
    self.cooldown = self:stat("reload")
    self.target = target

    local x, y, z = self:muzzlePosition()
    local dx, dy, dz = target.x - self.x - x, target.y - self.y - y, target.z - self.z - z
    self.from = { x, y, z }
    self.flight = 0
    self.flightTime = math.sqrt(dx * dx + dy * dy + dz * dz) / self.shotSpeed

    self.shot:setPosition(x, y, z)
    self.shot.visible = true
    self.muzzle:reset()
    self.muzzle:start()
    if self.fireSound then
        self.fireSound:stop()
        self.fireSound:play()
    end
end

-- homes in on the target, so it lands even if the enemy turns a corner
function Tower:moveShot(dt)
    local target = self.target
    if not target then return end

    self.flight = self.flight + dt
    local t = math.min(1, self.flight / self.flightTime)
    local from = self.from
    local x = from[1] + (target.x - self.x - from[1]) * t
    local y = from[2] + (target.y - self.y - from[2]) * t + self.arc * 4 * t * (1 - t)
    local z = from[3] + (target.z - self.z - from[3]) * t

    local last = self.shot.position
    local mx, my, mz = x - last.x, y - last.y, z - last.z
    local length = math.sqrt(mx * mx + my * my + mz * mz)
    if length > 0.001 then
        self.shot:setRotation(-math.deg(math.asin(my / length)), math.deg(math.atan(mx, mz)), 0)
    end
    self.shot:setPosition(x, y, z)

    if t >= 1 then
        self:land()
    end
end

function Tower:land()
    local target = self.target
    self.target = nil
    self.shot.visible = false

    local damage = self:stat("damage")
    if self.splash > 0 then
        GameState.damageArea(target.x, target.z, self.splash, damage, self.slow, self.slowTime)
    else
        target:hit(damage, self.slow, self.slowTime)
    end

    self.impact:setPosition(target.x - self.x, target.y - self.y, target.z - self.z)
    self.impactParticles:reset()
    self.impactParticles:start()
end

function Tower:onUpdate()
    if GameState.paused then return end
    if not self.x then
        local position = Object(self.scene, self.entity):getWorldPosition()
        self.x, self.y, self.z = position.x, position.y, position.z
    end

    local dt = math.min(Engine.deltatime, 0.1) * GameState.speed
    self:moveShot(dt)
    self.cooldown = self.cooldown - dt

    local target = GameState.findTarget(self.x, self.z, self:stat("range"))
    if not target then return end

    local yaw = math.deg(math.atan(target.x - self.x, target.z - self.z))
    local turn = (yaw - self.yaw + 180) % 360 - 180
    self.yaw = self.yaw + turn * math.min(1, 12 * dt)
    self.head:setRotation(0, self.yaw, 0)

    if self.cooldown <= 0 and not self.target and math.abs(turn) < 20 then
        self:fire(target)
    end
end

return Tower
