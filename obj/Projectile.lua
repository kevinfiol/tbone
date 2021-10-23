local vars = require 'vars'
local GameObject = require 'engine.GameObject'
local Collider = require 'engine.Collider'
local sodapop = require 'lib.sodapop'

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

    -- load sprite
    local image = love.graphics.newImage('assets/projectile.png')
    local frame_width = 8
    local half_width = frame_width / 2

    self.sprite = sodapop.newAnimatedSprite(self.x + half_width, self.y + half_width)
    self.sprite:addAnimation('default', {
        image = image,
        frameWidth = frame_width,
        frameHeight = frame_width,
        frames = {
            {1, 1, 3, 1, 0.1}
        }
    })

    self.sprite:setAnchor(function()
        return self.x + half_width, self.y + half_width
    end)
end

function Projectile:update(dt)
    Projectile.super.update(self, dt)
    if self.is_active then
        self.sprite:update(dt)
        if self.x < vars.bounds.left or self.y < vars.bounds.top or self.x > vars.bounds.right or self.y > vars.bounds.bottom then
            print('destroy projectile')
            self:setActive(false)
        end
    end
end

function Projectile:draw()
    if self.is_active then
        self.sprite:draw()
        -- love.graphics.setColor(1, 0, 0)
        -- love.graphics.circle('fill', self.x, self.y, self.radius)
    end
end

function Projectile:setActive(is_active)
    if not is_active then
        self.collider.body:setLinearVelocity(0, 0)
        self.collider.fixture:setCategory(1)
        self.collider.fixture:setMask(1)
    else
        self.sprite:switch('default')
        self.collider.fixture:setCategory(1)
        self.collider.fixture:setMask(2)
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
    if x_velocity < 0 then
        self.sprite.flipX = true
    else
        self.sprite.flipX = false
    end

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