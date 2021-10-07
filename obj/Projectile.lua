local vars = require 'vars'
local GameObject = require 'engine.GameObject'
local Collider = require 'engine.Collider'

local Projectile = GameObject:extend()

function Projectile:new(area, x, y, opts)
    Projectile.super.new(self, 'Projectile', area, x, y, opts)
    local opts = opts or {}
    self.radius = opts.radius or 4
    self.is_active = opts.is_active or false

    self.collider = Collider(self.area.world, 'Circle', {
        x = self.x,
        y = self.y,
        radius = self.radius,
        body_type = 'dynamic'
    })

    -- default to inactive
    self:setActive(self.is_active)
end

function Projectile:update(dt)
    Projectile.super.update(self, dt)

    if self.is_active then
        if self.x < 0 or self.y < 0 or self.x > vars.gw or self.y > vars.gh then
            self:setActive(false)
        end
    end
end

function Projectile:draw()
    if self.is_active then
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle('fill', self.x, self.y, self.radius)
    end
end

function Projectile:setActive(is_active)
    if not is_active then
        self.collider.body:setLinearVelocity(0, 0)
        self.collider.fixture:setFilterData(1, 0, 0)
    else
        self.collider.fixture:setFilterData(1, 65535, 0)
    end

    self.is_active = is_active
    self.collider.fixture:setSensor(not is_active)
    self.collider.body:setAwake(is_active)
end

function Projectile:setPosition(x, y)
    self.x = x
    self.y = y
    self.collider.body:setPosition(x, y)
end

function Projectile:launch(x, y, x_velocity)
    self:setPosition(x, y)
    self.collider.body:setLinearVelocity(x_velocity, 0)
end

function Projectile:beginContact(fixture_a, fixture_b, collision)
    if fixture_a == self.collider.fixture or fixture_b == self.collider.fixture then
        local fixture = fixture_a == self.collider.fixture and fixture_a or fixture_b
        self:setActive(false)
    end
end

return Projectile