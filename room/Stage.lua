local vars = require 'vars'
local Area = require 'engine.Area'
local Object = require 'lib.classic'
local Timer = require 'lib.timer'
local cartographer = require 'lib.cartographer'
local ripple = require 'lib.ripple'

local Ground = require 'obj.Ground'
local Player = require 'obj.Player'

local Stage = Object:extend()

function Stage:new()
    self.player = nil
    self.area = nil
    self.tiled_map = nil
    self.neighbors = {
        up = nil,
        down = nil,
        right = nil,
        left = nil
    }

    self.main_canvas = love.graphics.newCanvas(vars.gw, vars.gh)
    self.timer = Timer()

    -- music!
    local source = love.audio.newSource('assets/audio/theme.wav', 'static')
    self.music = ripple.newSound(source, { loop = true })
    self.music:play()

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
    }

    -- load the default area
    self:loadArea('map1.lua', { x = vars.gw / 16, y = vars.gh / 2 })
end

function Stage:update(dt)
    if self.area then self.area:update(dt) end
    if self.timer then self.timer:update(dt) end
    -- if self.player then
    --     camera:follow(self.player.x, self.player.y)
    -- end

    if self.player then
        self:triggerMapTransition()
    end

    -- camera:update(dt)
    self.music:update(dt)
end

function Stage:draw()
    if self.area then
        love.graphics.setCanvas(self.main_canvas)
        love.graphics.clear()
            -- camera:attach(0, 0, vars.gw, vars.gh)

            -- handle tiled map drawing here
            if self.tiled_map then
                -- self.tiled_map.layers.bg:draw()
                self:drawBgTiles()
                self.tiled_map.layers.fg:draw()
            end

            self.area:draw()
            -- camera:detach()
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

    self.music:stop()
    self.music = nil

    self.tiled_map = nil
    self.player = nil
    self.neighbors = nil
    self.bg = nil
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

function Stage:triggerMapTransition()
    local half_player_width = self.player.width / 2
    local half_player_height = self.player.height / 2

    local right_threshold = vars.gw - half_player_width
    local left_threshold = 0
    local up_threshold = 0
    local down_threshold = vars.gh - half_player_height

    -- transition up

    -- transition left
    if self.player.x < left_threshold then
        local x = vars.gw - self.player.width
        local y = self.player.y
        local new_map = self.neighbors.left
        self:loadArea(new_map, { x = x, y = y, flipX = true })
    end

    -- transition right
    if self.player.x >= right_threshold then
        local x = 0 -- since we move right, player should appear on left side
        local y = self.player.y
        local new_map = self.neighbors.right
        self:loadArea(new_map, { x = x, y = y })
    end

    -- transition down
end

function Stage:loadArea(map_file_name, player_position)
    if self.area then
        -- destroy existing area
        self.area:destroy()
    end

    self.area = Area(Stage, { debug = false })
    self.area.world = love.physics.newWorld(0, 0)

    -- load map
    self.tiled_map = cartographer.load('assets/maps/' .. map_file_name)

    -- register neighboring maps
    if self.tiled_map.properties then
        for direction, number in pairs(self.tiled_map.properties) do
            self.neighbors[direction] = 'map' .. number .. '.lua'
        end
    end

    -- create ground collisions based on tilemap
    -- `collidables` is an object layer; contains no sprite data
    local ground_1 = self.tiled_map.layers.collidables
    local ground_tiles = {}
    for _, o in ipairs(ground_1.objects) do
        -- create collidable objects for all collidable Tiled objects
        local ground_tile = Ground(self.area, o.x, o.y, {
            width = o.width,
            height = o.height
        })

        table.insert(ground_tiles, ground_tile)
    end

    self.area:addGameObjects(ground_tiles)

    -- create player object
    self.player = Player(self.area, player_position.x, player_position.y, { flipX = player_position.flipX })
    self.area:addGameObjects({ self.player })

    -- local Box = require 'obj.Box'
    -- local box = Box(self.area, vars.gw / 2, vars.gh / 2)
    -- self.area:addGameObjects({ box })

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

return Stage
