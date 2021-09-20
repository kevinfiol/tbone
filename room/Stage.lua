local vars = require 'vars'
local Area = require 'engine.Area'
local Object = require 'lib.classic'
local Timer = require 'lib.timer'
local cartographer = require 'lib.cartographer'

local Ground = require 'obj.Ground'
local Player = require 'obj.Player'

local Stage = Object:extend()

function Stage:new()
    self.area = Area(Stage)
    self.main_canvas = love.graphics.newCanvas(vars.gw, vars.gh)
    self.timer = Timer()

    -- create physics world for this area
    self.area.world = love.physics.newWorld(0, 0)

    -- create tiled map
    local tiledMap = cartographer.load('assets/maps/map1.lua')
    local ground_1 = tiledMap.layers.ground_1
    self.area:setTiledMap(tiledMap)

    -- create ground collisions
    for _, o in ipairs(ground_1.objects) do
        -- create collidable objects for all collidable Tiled objects
        local ground_tile = Ground(self.area, o.x, o.y, {
            width = o.width,
            height = o.height
        })

        self.area:addGameObjects({ ground_tile })
    end

    -- create player object
    self.player = Player(self.area, vars.gw / 16, vars.gh / 2)
    self.area:addGameObjects({ self.player })

    -- set collision callbacks
    local beginContact = function(fixture_a, fixture_b, collision)
        self.player:beginContact(fixture_a, fixture_b, collision)
    end

    local endContact = function(fixture_a, fixture_b, collision)
        self.player:endContact(fixture_a, fixture_b, collision)
    end

    self.area.world:setCallbacks(beginContact, endContact)
end

function Stage:update(dt)
    if self.area then self.area:update(dt) end
    if self.timer then self.timer:update(dt) end
end

function Stage:draw()
    if self.area then
        love.graphics.setCanvas(self.main_canvas)
        love.graphics.clear()
            camera:attach(0, 0, vars.gw, vars.gh)
            self.area:draw()
            camera:detach()
        love.graphics.setCanvas()

        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.setBlendMode('alpha', 'premultiplied')
        love.graphics.draw(self.main_canvas, 0, 0, 0, vars.sx, vars.sy)
        love.graphics.setBlendMode('alpha')
    end
end

function Stage:destroy()
    self.timer:destroy()
    self.timer = nil

    self.main_canvas:release()
    self.main_canvas = nil

    self.area:destroy()
    self.area = nil
end

return Stage