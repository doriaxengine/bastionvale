-- An enemy craft. It flies the road from the portal and hurts the keep if it gets there.

local GameState = require("scripts.GameState")

local Enemy = {
    properties = {
        { name = "health", displayName = "Health", type = "float", default = 60 },
        { name = "speed", displayName = "Speed", type = "float", default = 5 },
        { name = "reward", displayName = "Reward", type = "int", default = 8 },
        { name = "damage", displayName = "Damage", type = "int", default = 1 },
        { name = "hoverHeight", displayName = "Hover Height", type = "float", default = 2.8 },
        { name = "hull", displayName = "Hull", type = "Model" },
        { name = "healthBar", displayName = "Health Bar", type = "Object" },
        { name = "healthFill", displayName = "Health Fill", type = "Mesh" },
        { name = "explosion", displayName = "Explosion", type = "Particles" },
    },
}

function Enemy:init()
    self.object = Object(self.scene, self.entity)
    -- spawned at the scene root, so the oldest parent is the bundle instance
    self.root = self.scene:findOldestParent(self.entity)

    self.maxHealth = self.health * GameState.waveHealth
    self.health = self.maxHealth
    self.fillWidth = self.healthFill.scale.x
    self.leg = 1
    self.progress = 0
    self.slowFactor = 1
    self.slowTimer = 0
    self.yaw = 0
    self.bank = 0

    local path = GameState.path
    if #path >= 2 then
        self.x, self.y, self.z = path[1].x, path[1].y + self.hoverHeight, path[1].z
        self.yaw = math.deg(math.atan(path[2].x - path[1].x, path[2].z - path[1].z))
        self.object:setPosition(self.x, self.y, self.z)
        self.object:setRotation(0, self.yaw, 0)
    else
        local position = self.object:getWorldPosition()
        self.x, self.y, self.z = position.x, position.y, position.z
    end
    self:updateHealthBar()

    GameState.enemies[#GameState.enemies + 1] = self
    RegisterEngineEvent(self, "onUpdate")
end

function Enemy:updateHealthBar()
    local fraction = math.max(0, self.health / self.maxHealth)
    self.healthBar.visible = fraction < 1
    self.healthFill.scale = Vector3(self.fillWidth * fraction, self.healthFill.scale.y, self.healthFill.scale.z)
    self.healthFill:setPosition(-self.fillWidth * (1 - fraction) / 2, 0, 0)
    -- green to yellow to red
    self.healthFill:setColor(math.min(1, 2 - fraction * 2), math.min(1, fraction * 2), 0.15)
end

function Enemy:hit(damage, slow, slowTime)
    if self.dead then return end

    self.health = self.health - damage
    if slow > 0 then
        self.slowFactor = math.min(self.slowFactor, 1 - slow)
        self.slowTimer = math.max(self.slowTimer, slowTime)
        self.hull:setColor(0.6, 0.85, 1.0)
    end

    if self.health <= 0 then
        self:die()
    else
        self:updateHealthBar()
    end
end

function Enemy:die()
    self.dead = true
    self.health = 0
    self.removeTimer = 1.5
    self.hull.visible = false
    self.healthBar.visible = false
    self.explosion:reset()
    self.explosion:start()
    GameState.enemyKilled(self)
end

-- off the list here rather than in die(): towers may be walking it then
function Enemy:remove()
    GameState.removeEnemy(self)
    BundleManager.destroyBundle(self.scene, self.root)
end

function Enemy:fly(distance)
    local path = GameState.path
    while distance > 0 do
        local nextPoint = path[self.leg + 1]
        if not nextPoint then
            GameState.enemyReachedKeep(self)
            self.dead = true
            self:remove()
            return
        end

        local dx, dz = nextPoint.x - self.x, nextPoint.z - self.z
        local length = math.sqrt(dx * dx + dz * dz)
        if length <= distance then
            self.x, self.z = nextPoint.x, nextPoint.z
            self.leg = self.leg + 1
            self.progress = self.progress + length
            distance = distance - length
        else
            self.x = self.x + dx / length * distance
            self.z = self.z + dz / length * distance
            self.progress = self.progress + distance
            distance = 0
        end
    end
end

function Enemy:onUpdate()
    if GameState.paused then return end
    local dt = math.min(Engine.deltatime, 0.1) * GameState.speed

    if self.dead then
        self.removeTimer = self.removeTimer - dt
        if self.removeTimer <= 0 and not self.removed then
            self.removed = true
            self:remove()
        end
        return
    end
    if #GameState.path < 2 then return end

    if self.slowTimer > 0 then
        self.slowTimer = self.slowTimer - dt
        if self.slowTimer <= 0 then
            self.slowFactor = 1
            self.hull:setColor(1, 1, 1)
        end
    end

    self:fly(self.speed * self.slowFactor * dt)
    if self.dead then return end

    -- turn toward the next waypoint and lean into the turn
    local nextPoint = GameState.path[self.leg + 1]
    local yaw = math.deg(math.atan(nextPoint.x - self.x, nextPoint.z - self.z))
    local turn = (yaw - self.yaw + 180) % 360 - 180
    local step = turn * math.min(1, 6 * dt)
    self.yaw = self.yaw + step
    self.bank = self.bank + (math.max(-25, math.min(25, -step * 12)) - self.bank) * math.min(1, 5 * dt)

    self.object:setPosition(self.x, self.y, self.z)
    self.object:setRotation(0, self.yaw, self.bank)
end

return Enemy
