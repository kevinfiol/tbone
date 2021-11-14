local vars = require 'vars'
local GameObject = require 'engine.GameObject'
local Collider = require 'engine.Collider'
local sodapop = require 'lib.sodapop'

local Spear = GameObject:extend()

function Spear:new(area, x, y, opts)
    Spear.super.new(self, 'Spear', area, x, y, opts)
    local opts = opts or {}

    self.width = opts.width or 8
    self.height = opts.height or 3
    self.is_active = opts.is_active or false
    self.body_updates = {}

    self.collider = Collider(self.area.world, 'Rectangle', {
        collision_class = 'Spear',
        x = self.x,
        y = self.y,
        width = self.width,
        height = self.height,
        body_type = 'dynamic',
        body_offset = {
            x = (self.width / 2)
        }
    })

    -- spear.png 8x5
    local image = love.graphics.newImage('assets/spear.png')
    local frame_width = 8
    local frame_height = 5

    self.sprite = sodapop.newAnimatedSprite(self.x + (frame_width / 2), self.y + (frame_height / 2))
    self.sprite:addAnimation('default', {
        image = image,
        frameWidth = frame_width,
        frameHeight = frame_height,
        frames = {
            {1, 1, 1, 1, 1}
        }
    })

    self.sprite:setAnchor(function()
        return self.x + (frame_width / 2), self.y + (frame_height / 2)
    end)

    -- default to inactive
    self:setActive(self.is_active)
end

function Spear:update(dt)
    Spear.super.update(self, dt)

    if self.is_active then
        self.sprite:update(dt)

        if #self.body_updates > 0 then
            while #self.body_updates ~= 0 do
                local update = table.remove(self.body_updates, 1)
                if update.prop == 'type' then
                    self.collider.body:setType(update.value)
                end
            end
        end

        if self.x < 0 or self.x > vars.gw then
            self:setActive(false)
        end
    end
end

function Spear:draw()
    if self.is_active then
        self.sprite:draw()

        -- local x, y = self.collider.body:getPosition()
        -- love.graphics.setColor(1, 0, 0)
        -- love.graphics.rectangle('line', x - self.collider.body_offset.x / 2, y, self.collider.width, self.collider.height)
    end
end

function Spear:setActive(is_active)
    if not is_active then
        self.collider.body:setLinearVelocity(0, 0)
        self.collider:setCollisionClass('Ghost')
    else
        self.sprite:switch('default')
        self.collider:setCollisionClass('Spear')
        self.collider.body:setType('dynamic')
    end

    self.is_active = is_active
    self.collider.fixture:setSensor(not is_active)
    self.collider.body:setAwake(is_active)
end

function Spear:setPosition(x, y)
    self.x = x
    self.y = y
    self.collider.body:setPosition(x, y)
end

function Spear:launch(x, y, x_velocity)
    if x_velocity < 0 then
        self.sprite.flipX = true
    else
        self.sprite.flipX = false
    end

    self:setPosition(x, y)
    self.collider.body:setLinearVelocity(x_velocity, 0)
end

function Spear:beginContact(fixture_a, fixture_b, collision)
    local colliders = self.collider:checkCollision(fixture_a, fixture_b)
    if colliders.is_colliding then
        local other_collider = colliders.other_collider

        if other_collider.collision_class == 'Ground' then
            -- stick
            self.collider.body:setLinearVelocity(0, 0)
            table.insert(self.body_updates, {
                prop = 'type',
                value = 'static'
            })
        end
    end
end

return Spear