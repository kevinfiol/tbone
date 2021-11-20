local GameObject = require 'engine.GameObject'
local Collider = require 'engine.Collider'
local sodapop = require 'lib.sodapop'

local Gacko = GameObject:extend()

function Gacko:new(area, x, y, opts)
    Gacko.super.new(self, 'Gacko', area, x, y, opts)
    local opts = opts or {}
    self.width = opts.width or 16
    self.height = opts.height or 16

    -- physics
    self.collider = Collider(self.area.world, 'Rectangle', {
        collision_class = 'Gacko',
        x = self.x,
        y = self.y,
        width = 8, -- this is the actual hitbox
        height = 9, -- this is the actual hitbox 8x9
        body_type = 'static',
        body_offset = {
            x = 8,
            y = 11
        }
    })

    -- tbone.png 208x16
    local image = love.graphics.newImage('assets/gacko.png')
    self:setSpriteConfig(image)
    self.sprite.flipX = opts.flipX or false
    self.has_been_killed = false
end

function Gacko:update(dt)
    Gacko.super.update(self, dt)

    -- sprite animation update
    self.sprite:update(dt)

end

function Gacko:draw()
    self.sprite:draw()
end

function Gacko:setSpriteConfig(image)
    local frame_width = 16
    local frame_height = 16

    local frame_width_half = frame_width / 2
    local frame_height_half = frame_height / 2

    self.sprite = sodapop.newAnimatedSprite(self.x + frame_width_half, self.y + frame_height_half)

    self.sprite:addAnimation('idle', {
        image = image,
        frameWidth = frame_width,
        frameHeight = frame_height,
        frames = {
            {1, 1, 1, 1, 0.1}
        }
    })

    self.sprite:switch('idle')

    -- this is important; it sets the sprite image to be anchored to the actual coordinates of the Body used for Physics
    self.sprite:setAnchor(function()
        return self.x + frame_width_half, self.y + frame_height_half
    end)
end

function Gacko:beginContact(fixture_a, fixture_b, collision)
    local colliders = self.collider:checkCollision(fixture_a, fixture_b)
    if colliders.is_colliding then
        local other_collider = colliders.other_collider

        if other_collider.collision_class == 'Spear' then
            self.has_been_killed = true
        end
    end
end

function Gacko:endContact(fixture_a, fixture_b, collision)
    -- noop
end

return Gacko