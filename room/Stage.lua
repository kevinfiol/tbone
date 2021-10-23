local vars = require 'vars'
local Area = require 'engine.Area'
local Object = require 'lib.classic'
local Timer = require 'lib.timer'
local cartographer = require 'lib.cartographer'
local lume = require 'lib.lume'

local Ground = require 'obj.Ground'
local Player = require 'obj.Player'

local Stage = Object:extend()

function Stage:new()
    self.area = Area(Stage, { debug = false })
    self.main_canvas = love.graphics.newCanvas(vars.gw, vars.gh)
    self.timer = Timer()

    -- create physics world for this area
    self.area.world = love.physics.newWorld(0, 0)

    -- create tiled map
    self.tiled_map = cartographer.load('assets/maps/map1.lua')

    -- the bg_tileset is 64x64 (see /assets/bg.png)
    -- our game is 480x270 (see vars.lua)
    -- therefore, we will repeat the bg tile enough times on the x & y axis to cover the screen
    -- to ensure that we cover the whole screen
    -- https://love2d.org/wiki/Tutorial:Efficient_Tile-based_Scrolling
    -- https://love2d.org/forums/viewtopic.php?t=32969

    -- build background
    local bg_img = love.graphics.newImage('assets/bg.png')
    local bg_quad = love.graphics.newQuad(0, 0, 64, 64, bg_img:getDimensions())

    local tile_width = 64
    local bg_width = 9 -- in tiles
    local bg_height = 5 -- in tiles
    local bg_batch = love.graphics.newSpriteBatch(bg_img, bg_width * bg_height)

    self.bg = {
        tile = { img = bg_img, height = tile_width, width = tile_width },
        offset = { x = 0, y = 0 },
        quad = bg_quad,
        batch = bg_batch,
        x = 0,
        y = 0,
        width = bg_width, -- in tiles
        height = bg_height, -- in tiles
        pixel_width = bg_width * tile_width,
        pixel_height = bg_height * tile_width,
        -- tiles = {}
    }

    -- create ground collisions
    -- `ground_1` is an object layer; contains no sprite data
    local ground_1 = self.tiled_map.layers.ground_1
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
    local function beginContact(fixture_a, fixture_b, collision)
        self.player:beginContact(fixture_a, fixture_b, collision)

        -- set all player's projectiles collision callbacks
        for _, projectile in ipairs(self.player.projectiles) do
            projectile:beginContact(fixture_a, fixture_b, collision)
        end
    end

    local function endContact(fixture_a, fixture_b, collision)
        self.player:endContact(fixture_a, fixture_b, collision)
    end

    self.area.world:setCallbacks(beginContact, endContact)
end

function Stage:update(dt)
    if self.area then self.area:update(dt) end
    if self.timer then self.timer:update(dt) end
    if self.player then
        camera:follow(self.player.x, self.player.y)
    end

    camera:update(dt)
end

function Stage:draw()
    if self.area then
        love.graphics.setCanvas(self.main_canvas)
        love.graphics.clear()
            camera:attach(0, 0, vars.gw, vars.gh)

            -- handle tiled map drawing here
            if self.tiled_map then
                -- self.tiled_map.layers.bg:draw()
                self:drawBgTiles()
                self.tiled_map.layers.fg:draw()
            end

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

    self.tiled_map = nil
end

function Stage:drawBgTiles()
    local half_tile_width = self.bg.tile.width / 2
    local increment = -(half_tile_width / (self.bg.tile.width)) * 1

    if self.bg.x == -(self.bg.pixel_width) then
        self.bg.x = 0
    end

    self.bg.x = self.bg.x + increment
    self.bg.batch:clear()
    local bg_double_width = self.bg.width * 2 -- let's draw the bg twice, one next to the other

    for i = 1, bg_double_width do
        for j = 1, self.bg.height do
            local x = (64 * i) - 64 + self.bg.offset.x + self.bg.x
            local y = (64 * j) - 64 + self.bg.offset.y + self.bg.y
            self.bg.batch:add(self.bg.quad, x, y)
        end
    end

    self.bg.batch:flush()
    love.graphics.draw(self.bg.batch)
end

return Stage
