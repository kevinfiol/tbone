local GameObject = require 'engine.GameObject'
local Collider = require 'engine.Collider'

local Projectile = GameObject:extend()

function Projectile:new(area, x, y, opts)
    Projectile.super.new(self, 'Projectile', area, x, y, opts)
    local opts = opts or {}
    self.radius = opts.radius or 4

    self.collider = Collider(self.area.world, 'Circle', {
        x = self.x,
        y = self.y,
        radius = self.radius,
        body_type = 'dynamic'
    })
end

function Projectile:update(dt)
    Projectile.super.update(self, dt)
end

function Projectile:draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.circle('fill', self.x, self.y, self.radius)
end

return Projectile