local vars = require 'vars'
local utils = require 'engine.utils'
local RoomManager = require 'engine.RoomManager'
local Camera = require 'lib.camera'
local baton = require 'lib.baton'

local input
local rooms

local resize = function(s)
    love.window.setMode(s * vars.gw, s * vars.gh)
    vars.sx, vars.sy = s, s
end

function love.load()
    rooms = RoomManager()

    camera = Camera() -- global camera
    camera:setFollowStyle('PLATFORMER')

    -- scale window
    resize(2)

    -- adjust filter mode and line style for pixelated look
    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.graphics.setLineStyle('rough')

    -- first room
    rooms:goToRoom('Stage')
end

function love.update(dt)
    -- keep the bounds updated via the camera position
    vars.bounds.top = camera.y - (vars.gh / 2)
    vars.bounds.bottom = camera.y + (vars.gh / 2)
    vars.bounds.right = camera.x + (vars.gw / 2)
    vars.bounds.left = camera.x - (vars.gw / 2)

    if rooms.current_room then rooms.current_room:update(dt) end
end

function love.draw()
    if rooms.current_room then rooms.current_room:draw() end
end