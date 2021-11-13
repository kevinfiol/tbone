local GameObject = require 'engine.GameObject'
local Collider = require 'engine.Collider'
local baton = require 'lib.baton'
local sodapop = require 'lib.sodapop'
local ripple = require 'lib.ripple'
local Projectile = require 'obj.Projectile'
local Spear = require 'obj.Spear'

local Player = GameObject:extend()

function Player:new(area, x, y, opts)
    Player.super.new(self, 'Player', area, x, y, opts)
    local opts = opts or {}
    self.width = opts.width or 16
    self.height = opts.height or 16

    -- physics
    self.collider = Collider(self.area.world, 'Rectangle', {
        collision_class = 'Player',
        x = self.x,
        y = self.y,
        width = 8, -- this is the actual hitbox
        height = 9, -- this is the actual hitbox 8x9
        body_type = 'dynamic',
        body_offset = {
            x = 8,
            y = 11
        }
    })

    -- tbone.png 208x16
    local image = love.graphics.newImage('assets/tbone.png')
    self:setSpriteConfig(image)
    self.sprite.flipX = opts.flipX or false

    -- define controls
    self.input = baton.new({
        controls = {
            left = { 'key:left' },
            right = { 'key:right' },
            jump = { 'key:z' },
            shoot = { 'key:x' }
        }
    })

    -- projectiles
    self.projectiles = {}
    for i = 1, 1 do
        table.insert(self.projectiles,
            -- projectiles are inactive by default
            -- Projectile(self.area, -100, -100)
            Spear(self.area, -100, -100)
        )
    end

    self.area:addGameObjects(self.projectiles)

    -- flags
    self.is_walking = false
    self.is_grounded = false
    self.is_jumping = false
    self.jump_timer = 0
    self.current_ground_collision = nil

    -- self.rotation = -math.pi / 2 -- angle the player is moving towards, pointing up; math.pi/2 is down, -math.pi/2 is up
    self.velocity = { x = 0, y = 0 }
    self.max_velocity = { x = 80, y = 300 }
    self.acceleration = 900
    self.friction = 800
    self.gravity = 1500

    -- load sounds
    local jump = love.audio.newSource('assets/audio/jump.wav', 'static')
    local shoot = love.audio.newSource('assets/audio/shoot.wav', 'static')
    self.sounds = {
        jump = ripple.newSound(jump, { volume = 1, loop = false }),
        shoot = ripple.newSound(shoot, { volume = 1, loop = false }),
    }
end

function Player:update(dt)
    Player.super.update(self, dt)
    self.collider.body:setLinearVelocity(self.velocity.x, self.velocity.y)

    -- -- inputs
    self.input:update()

    -- -- movement
    self:move(dt)
    self:applyGravity(dt)
    self:jump(dt)

    -- attacks
    self:attack(dt)

    -- sprite animation update
    self.sprite:update(dt)

    -- update sounds
    for _, sound in ipairs(self.sounds) do
        sound:update(dt)
    end
end

function Player:draw()
    self.sprite:draw()

    local x, y = self.collider.body:getPosition()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle('line', x - self.collider.body_offset.x / 2, y - self.collider.body_offset.y / 2, self.collider.width, self.collider.height)
end

function Player:jump(dt)
    local is_jump_pressed = self.input:pressed('jump')
    local is_jump_down = self.input:down('jump')

    -- first, if the player is not touching the ground, show fall animation
    if not self.is_grounded then
        self.sprite:switch('fall')
    end

    -- if the player had been jumping last frame, but is no longer jumping, switch to falling
    if self.is_jumping and not is_jump_down then
        self.sprite:switch('fall')
        self.is_jumping = false
    elseif self.is_jumping and self.is_grounded then
        -- if player had been jumping but has landed
        self.is_jumping = false
    end

    -- initialize jump
    if self.is_grounded and self.jump_timer == 0 and is_jump_pressed then
        self.sounds.jump:play()
        self.is_jumping = true
        self.is_grounded = false -- kinda hacky and redunant because of Player:endContact should handle this
    end

    -- continue jump is jump is being held
    if self.is_jumping and is_jump_down then
        self.sprite:switch('jump')
        self.jump_timer = self.jump_timer + dt
    else
        self.jump_timer = 0
    end

    if self.jump_timer > 0 and self.jump_timer < 0.15 then
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
            if not self.input:down('right') and not self.input:down('left') then
                self.sprite:switch('idle')
            end
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

function Player:attack(dt)
    -- first check if any projectiles are inactive
    local can_shoot = false
    for _, projectile in ipairs(self.projectiles) do
        if not projectile.is_active then
            can_shoot = true
            break
        end
    end

    if self.input:pressed('shoot') and can_shoot then
        self.sounds.shoot:play()
        self.sprite:switch('attack', false)
        -- 16 + 4 = 20
        -- 0 - 4 = -4
        local x_velocity = self.sprite.flipX and -400 or 400
        local x_spawn = self.x + (self.sprite.flipX and -4 or 20)
        local y_spawn = self.y + 8

        -- get next projectile, move to back of the list
        local projectile = table.remove(self.projectiles, 1)
        table.insert(self.projectiles, projectile)

        projectile:setActive(true)
        projectile:launch(x_spawn, y_spawn, x_velocity)
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
    if self.input:down('right') or self.input:down('left') then
        self.sprite:switch('walk')
    else
        self.sprite:switch('idle')
    end

    self.current_ground_collision = collision
    self.velocity.y = 0
    self.is_grounded = true
end

function Player:beginContact(fixture_a, fixture_b, collision)
    if self.is_grounded then return end

    local _, normal_y = collision:getNormal()
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

function Player:setSpriteConfig(image)
    local frame_width = 16
    local frame_height = 16

    local frame_width_half = frame_width / 2
    local frame_height_half = frame_height / 2

    self.sprite = sodapop.newAnimatedSprite(self.x + frame_width_half, self.y + frame_height_half)

    -- this is important; it sets the sprite image to be anchored to the actual coordinates of the Body used for Physics
    self.sprite:setAnchor(function()
        return self.x + frame_width_half, self.y + frame_height_half
    end)

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

    self.sprite:addAnimation('attack', {
        image = image,
        frameWidth = frame_width,
        frameHeight = frame_height,
        onReachedEnd = function()
            if self.is_grounded then
                if self.input:down('right') or self.input:down('left') then
                    self.sprite:switch('walk')
                else
                    self.sprite:switch('idle')
                end
            end
        end,
        frames = {
            {5, 1, 7, 1, 0.1}
        }
    })
end

return Player