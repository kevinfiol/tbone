local Object = require 'lib.classic'

local Collider = Object:extend()

local classes = {}

function Collider:new(world, collider_type, opts)
    --[[
        opts = {
            class,
            ignores,
            x, y,
            body_type,
            body_offset?,
            fixed_rotation?
            radius?,
            width?,
            height?,
            fixture_density?,
            restitution?
        }
    --]]

    self.class = opts.class
    self.ignores = opts.ignores or {}
    self.world = world
    self.type = collider_type
    self.body = nil
    self.shape = nil
    self.fixture = nil
    self.body_offset = { x = nil, y = nil }

    local x, y = opts.x, opts.y
    local body_type = opts.body_type or 'dynamic'

    -- default fixed_rotation to true
    local fixed_rotation
    if opts.fixed_rotation == nil then
        fixed_rotation = true
    else
        fixed_rotation = opts.fixed_rotation
    end

    -- get body offsets if present
    if opts.body_offset then
        self.body_offset.x = opts.body_offset.x or nil
        self.body_offset.y = opts.body_offset.y or nil
        x = x + self.body_offset.x
        y = y + self.body_offset.y
    end

    -- create body
    self.body = love.physics.newBody(self.world, x, y, body_type)
    self.body:setFixedRotation(fixed_rotation)

    -- create shape
    if self.type == 'Circle' then
        local radius = opts.radius
        self.shape = love.physics.newCircleShape(radius)
    elseif self.type == 'Rectangle' then
        local width, height = opts.width, opts.height
        self.shape = love.physics.newRectangleShape(width, height)
    end

    -- create fixture
    local fixture_density = opts.fixture_density or 1
    self.fixture = love.physics.newFixture(self.body, self.shape, fixture_density)

    if opts.restitution then
        self.fixture:setRestitution(opts.restitution)
    end

    -- set collider as user data on fixture
    -- this is useful because we are only given the fixture on collision callbacks
    self.fixture:setUserData(self)
end

function Collider:destroy()
    self.body:destroy()

    self.world = nil
    self.type = nil
    self.body = nil
    self.shape = nil
    self.fixture = nil
    self.body_offset = nil
end

function Collider:getPosition()
    local x, y = self.body:getPosition()

    if self.body_offset.x then x = x - self.body_offset.x end
    if self.body_offset.y then y = y - self.body_offset.y end

    return x, y
end

function Collider:setPosition(x, y)
    local new_x, new_y = x, y

    if self.body_offset.x then new_x = x - self.body_offset.x end
    if self.body_offset.y then new_y = y - self.body_offset.y end

    self.body:setPosition(new_x, new_y)
end

function Collider:setClass(class)
    self.class = class
end

return Collider