local GameObject = require 'engine.GameObject'
local Collider = require 'engine.Collider'
local baton = require 'lib.baton'
local sodapop = require 'lib.sodapop'

local Player = GameObject:extend()

function Player:new(area, x, y, opts)
    Player.super.new(self, 'Player', area, x, y, opts)
    local opts = opts or {}
    self.width = opts.width or 16
    self.height = opts.height or 16

    -- physics
    self.collider = Collider(self.area.world, 'Rectangle', {
        x = self.x,
        y = self.y,
        width = self.width,
        height = self.height,
        body_type = 'dynamic',
        body_offset = {
            x = (self.width / 2),
            y = (self.height / 2)
        }
    })

    -- tbone.png 208x16
    local image = love.graphics.newImage('assets/tbone.png')

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
            {1, 1, 4, 1, 0.1}
        }
    })

    self.sprite:addAnimation('walk', {
        image = image,
        frameWidth = frame_width,
        frameHeight = frame_height,
        frames = {
            {8, 1, 11, 1, 0.1}
        }
    })

    self.sprite:addAnimation('fall', {
        image = image,
        frameWidth = frame_width,
        frameHeight = frame_height,
        frames = {
            {13, 1, 13, 1, 0.1}
        }
    })

    self.sprite:addAnimation('jump', {
        image = image,
        frameWidth = frame_width,
        frameHeight = frame_height,
        frames = {
            {12, 1, 12, 1, 0.1}
        }
    })

    -- this is important; it sets the sprite image to be anchored to the actual coordinates of the Body used for Physics
    self.sprite:setAnchor(function()
        return self.x + frame_width_half, self.y + frame_height_half
    end)

    -- define controls
    self.input = baton.new({
        controls = {
            left = { 'key:left' },
            right = { 'key:right' },
            jump = { 'key:z' }
        }
    })

    -- flags
    self.is_grounded = false
    self.is_jumping = false
    self.jump_timer = 0
    self.current_ground_collision = nil

    -- self.rotation = -math.pi / 2 -- angle the player is moving towards, pointing up; math.pi/2 is down, -math.pi/2 is up
    self.velocity = { x = 0, y = 0 }
    self.max_velocity = { x = 60, y = 300 }
    self.acceleration = 900
    self.friction = 800
    self.gravity = 1500
end

function Player:update(dt)
    Player.super.update(self, dt)
    self.collider.body:setLinearVelocity(self.velocity.x, self.velocity.y)

    -- -- inputs
    self.input:update()

    -- -- movement
    self:move(dt)
    self:applyGravity(dt)
    -- self:jump(dt)

    -- sprite animation update
    self.sprite:update(dt)
end

function Player:draw()
    self.sprite:draw()
end

function Player:jump(dt)
    local is_on_ground = self.collider:isTouching('Ground')
    local is_jump_pressed = self.input:down('jump')

    if not is_on_ground then
        self.sprite:switch('fall')
    end

    if self.is_jumping and not is_jump_pressed then
        self.sprite:switch('fall')
        self.is_jumping = false
    end

    if is_on_ground and not self.is_jumping then
        self.jump_timer = 0
    end

    if self.jump_timer >= 0 and is_jump_pressed then
        self.sprite:switch('jump')
        self.is_jumping = true
        self.jump_timer = self.jump_timer + dt
    else
        self.jump_timer = -1
    end

    if self.jump_timer > 0 and self.jump_timer < 0.5 then
        self.velocity.y = -200
    end
end

function Player:move(dt)
    local current_acceleration = (self.acceleration * dt)

    if self.is_grounded then
        if self.input:pressed('right') or self.input:pressed('left') then
            self.sprite:switch('walk')
        end
        if self.input:released('right') or self.input:released('left') then
            self.sprite:switch('idle')
        end
    end

    if self.input:down('right') then
        self.sprite.flipX = false
        if self.velocity.x < self.max_velocity.x then
            if self.velocity.x + current_acceleration < self.max_velocity.x then
                self.velocity.x = self.velocity.x + current_acceleration
            else
                self.velocity.x = self.max_velocity.x
            end
        end
    elseif self.input:down('left') then
        self.sprite.flipX = true
        if self.velocity.x > -self.max_velocity.x then
            if self.velocity.x - current_acceleration > -self.max_velocity.x then
                self.velocity.x = self.velocity.x - current_acceleration
            else
                self.velocity.x = -self.max_velocity.x
            end
        end
    else
        self:applyFriction(dt)
    end
end

function Player:applyFriction(dt)
    local current_friction = (self.friction * dt)

   if self.velocity.x > 0 then
      if self.velocity.x - current_friction > 0 then
         self.velocity.x = self.velocity.x - current_friction
      else
         self.velocity.x = 0
      end
   elseif self.velocity.x < 0 then
      if self.velocity.x + current_friction < 0 then
         self.velocity.x = self.velocity.x + current_friction
      else
         self.velocity.x = 0
      end
   end
end

function Player:applyGravity(dt)
    if not self.is_grounded then
        self.velocity.y = self.velocity.y + (self.gravity * dt)
    end
end

function Player:land(collision)
    self.current_ground_collision = collision
    self.velocity.y = 0
    self.is_grounded = true
end

function Player:beginContact(fixture_a, fixture_b, collision)
    if self.is_grounded then return end

    local normal_x, normal_y = collision:getNormal()
    if fixture_a == self.collider.fixture then
        if normal_y > 0 then
            -- ground is below player
            self:land(collision)
        end
    elseif fixture_b == self.collider.fixture then
        if normal_y < 0 then
            self:land(collision)
        end
    end
end

function Player:endContact(fixture_a, fixture_b, collision)
    if fixture_a == self.collider.fixture or fixture_b == self.collider.fixture then
        if self.current_ground_collision == collision then
            self.is_grounded = false
        end
    end
end

return Player