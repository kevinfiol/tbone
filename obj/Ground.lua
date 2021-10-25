local GameObject = require 'engine.GameObject'
local Collider = require 'engine.Collider'

local Ground = GameObject:extend()

function Ground:new(area, x, y, opts)
    Ground.super.new(self, 'Ground', area, x, y, opts)
    self.width = opts.width or 8
    self.height = opts.height or 8

    self.collider = Collider(self.area.world, 'Rectangle', {
        collision_class = 'Ground',
        x = self.x,
        y = self.y,
        width = self.width,
        height = self.height,
        body_type = 'static',
        body_offset = {
            x = (self.width / 2),
            y = (self.height / 2)
        }
    })
end

function Ground:update(dt)
    Ground.super.update(self, dt)
end

function Ground:draw()
    -- love.graphics.setColor(1, 0, 0)
    -- love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
end

return Ground
