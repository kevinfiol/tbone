local GameObject = require 'engine.GameObject'
local Collider = require 'engine.Collider'

local Box = GameObject:extend()

-- This object is for testing purposes
function Box:new(area, x, y, opts)
    Box.super.new(self, 'Default', area, x, y, opts)
    local opts = opts or {}
    self.width = opts.width or 16
    self.height = opts.height or 16

    self.collider = Collider(self.area.world, 'Rectangle', {
        collision_class = 'Default',
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

function Box:update(dt)
    Box.super.update(self, dt)
end

function Box:draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
end

return Box
