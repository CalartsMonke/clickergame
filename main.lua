love = require 'love'
love.graphics.setDefaultFilter('nearest', 'nearest')

--Require libs
local anim8 = require 'libs.anim8'
local baton = require 'libs.baton'
require("libs.batteries"):export()
--ASSETS
local assets = {}
assets.images = {}
assets.images.bigFlower = love.graphics.newImage("img/bigFlower.png")
assets.images.stem = love.graphics.newImage("img/flowerstem.png")
assets.images.flowerhead = love.graphics.newImage("img/flowerhead.png")

assets.fonts = {}
assets.fonts.default = love.graphics.getFont()
assets.fonts.it32 = love.graphics.newFont('fonts/Ithaca-LVB75.ttf', 32, 'mono')





--game preresqs
local mouseX, mouseY = 0, 0
local gameWidth, gameHeight = 640, 360

--Canvas and scale
--make a new canvas
local gameCanvas = love.graphics.newCanvas(640, 360)

--Canvas scaling
local maxScaleX 
local maxScaleY 
    
local scale = 1
_G.screenScale = scale

function updateScale()
    maxScaleX = love.graphics.getWidth() / gameCanvas:getWidth()
    maxScaleY = love.graphics.getHeight() / gameCanvas:getHeight()
    scale = math.min(maxScaleX, maxScaleY)
    local scaledScreenX, scaledScreenY = love.graphics.getWidth() / scale, love.graphics.getHeight() / scale
    local screenX, screenY = gameWidth, gameHeight
    local mouseOffX = (screenX - scaledScreenX) / 2
    local mouseOffY = (screenY - scaledScreenY) / 2
    mouseX, mouseY = (love.mouse.getX() / scale) + mouseOffX, (love.mouse.getY() / scale) + mouseOffY
end


--INPUT
input = baton.new {
  controls = {
    toggleWindowMode = {'key:f11', 'key:f'},

    clickLeft = {'mouse:1'}
  },
  joystick = love.joystick.getJoysticks()[1],
}

--CLASSES

--CLASS ENTITY
local Object = class({
    name = "Object"
})

function Object:new()
    self.objectName = "Object"
    if _G.global_objectId == nil then
        _G.global_objectId = 1
        self._objectId = global_objectId
    else
        self._objectId = _G.global_objectId
        _G.global_objectId = _G.global_objectId + 1
    end
    self.createdAt = love.timer.getTime()
    self.updating = true
    self.visible = true
    self.children = {}
end

function Object:setScript(scriptfunc)
    self.update = scriptfunc
    print("Changed script")
end

function Object:addChild(child)
    child.parent = self
    table.push(self.children, child)


    --Cache global pos
end

function Object:destroy()
    print("Add destroying function and also remove children")
end

function Object:updateChildren(dt)
    if self.updating then
        if self.updateGlobalPosition then
            self:updateGlobalPosition()
        end
        if self.children then
            for i, v in ipairs(self.children) do
                if v.update ~= nil then
                    v:update(dt)
                    v:updateGlobalPosition()
                    v:updateChildren()
                end
            end
        end
    end
end

function Object:drawChildren()
    if self.visible then
        if self.children then
            for i, v in ipairs(self.children) do
                if v.draw ~= nil then
                    v:draw()
                    v:drawChildren()
                end
            end
        end
    end
end

--CLASS ENTITY
local Entity = class({
    name = "Entity",
    extends = Object
})

function Entity:new(x, y)
    self:super()
    self.visible = true
    self.updating = true
    self._transformDirty = false
    self.position = vec2(x or 0, y or 0)
    self.globalPosition = vec2(0, 0)
    self.scale = vec2(1, 1)
    self.rotation = 0
end

function Entity:updateGlobalPosition()
    self:_get_global_position()
    if self._transformDirty == false and self.parent then
        local gpos = self:_get_global_position()
        local gParentpos = self.parent:_get_global_position()
        local posx, posy = self.position.x + gParentpos.x, self.position.y + gParentpos.y
        _G._transformCache[self._objectId] = {x = posx, y = posy}
        print(posx, posy)
    end
    if self.parent then
        self.globalPosition.x = self.parent.globalPosition.x + self.position.x
        self.globalPosition.y = self.parent.globalPosition.y + self.position.y
    else
        local posx, posy = self.position.x, self.position.y
        _G._transformCache[self._objectId] = {x = posx, y = posy}
    end
end

function Entity:_get_global_position()
    if _G._transformCache == nil then
        _G._transformCache = {}
        local pos = {x = self.globalPosition.x, y = self.globalPosition.y}
        _G._transformCache[self._objectId] = pos
    end
    return _G._transformCache[self._objectId]
end

--CLASS SPRITE
local Sprite = class({
    name = "Sprite",
    extends = Entity
})

function Sprite:new(texture, x, y)
    self:super(x, y)
    self.texture = texture
end

function Sprite:draw()
    if true then
        love.graphics.draw(
        self.texture, -- Texture
        _G._transformCache[self._objectId].x, --Position X
        _G._transformCache[self._objectId].y, --Position Y
        self.rotation, --Rotation
        self.scale.x, --Scale X
        self.scale.y, --Scale Y
        0,
        0,
        0,
        0
    )
    end
end

--CLASS LABEL
local Label = class({
    name = "Label",
    extends = Entity
})

function Label:new(text, x, y)
    self:super(x, y)
    self.text = text

    self.color = {r = 1, g = 1, b = 1}
    self.alpha = 1
    self.alignMode = 'left'
    self.wrapLimit = 256
    self.font = assets.fonts.default
end

--Number of pixels before text wraps
function Label:setWrapLimit(limit)
    self.wrapLimit = limit
end

--Set mode to 'center', 'left', right', or 'justify'
function Label:setAlignMode(mode)
    if mode == 'center' or mode == 'left' or mode == 'right' or mode == 'justify' then
        self.alignMode = mode
    else
        error("Set Mode to center, left, right, or justify")
    end
end

function Label:setFont(font)
    self.font = font
end

function Label:setText(text)
    if type(text) ~= 'string' then
        self.text = tostring(text)
    else
        self.text = text
    end

end

function Label:draw()
    love.graphics.setFont(self.font)
    love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.alpha)
        love.graphics.printf (
        self.text, -- Text
        self.parent.globalPosition.x + self.position.x, --Position X
        self.parent.globalPosition.y + self.position.y, --Position Y
        self.wrapLimit, --Wrap Limit
        self.alignMode, --AlignMode
        self.rotation, --Rotation
        self.scale.x, --Scale X
        self.scale.y --Scale Y
    )
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(assets.fonts.default)
end

--CLASS AUDIOSTREAMPLAYER

local SourcePlayer = class({
    name = "AudioStreamPlayer",
    extends = Object,
})

function SourcePlayer:new(source, vol)
    self.source = source or nil
    self.vol = vol or 1.0
end

function SourcePlayer:play()
    self.source:play()
end

function SourcePlayer:pause()
    self.source:pause()
end

function SourcePlayer:stop()
    self.source:stop()
end

function SourcePlayer:isPlaying()
    return self.source:isPlaying()
end

--GAME SPECIAL CLASSES


--CLASS BIGFLOWER
local BigFlower = class({
    name = "BigFlower",
    extends = Entity,
})

function BigFlower:new(x, y)
    self:super(x, y)
    local sprite = Sprite(assets.images.bigFlower, self.position.x, self.position.y)
    --self:addChild(sprite)
    self.sprite1 = sprite

    local stem = Sprite(assets.images.stem, 250, 0)
    self:addChild(stem)

    local flowerhead = Sprite(assets.images.flowerhead, 100, 0)
    stem:addChild(flowerhead)
    
    local count = Label("0", 0, -30)
    count:setAlignMode('center')
    count:setWrapLimit(64)
    count:setFont(assets.fonts.it32)
    self:addChild(count)
    self.countText = count

    local startClickText = Label("START CLICKING", 0, -30)
    startClickText:setScript(require 'scripts.startText')
    startClickText:setFont(assets.fonts.it32)
    startClickText.timer = 5
    self:addChild(startClickText)
    self.startClickText = startClickText

    local startClickText = Label("CLICK 100 TIMES", 0, -30)
    startClickText:setScript(require 'scripts.startText2')
    startClickText:setFont(assets.fonts.it32)
    startClickText.timer = 6
    startClickText.timer2 = 12
    self:addChild(startClickText)
    self.startClickText = startClickText

    self.count = 0
end

function BigFlower:update(dt)
    if input:pressed('clickLeft') then
        self.count = self.count + 1
        self.countText:setText(self.count)
        print("U ARE AWESOME")
    end
end
--------------------------------------------------------
local entities = {}

local Game = Object()
Game:setScript(require 'scripts.game')
table.insert(entities, Game)

--GAME
local bigFlower = BigFlower()
bigFlower.position.x = 0
bigFlower.position.y = 0
table.insert(entities, bigFlower)


function love.load()

end

function love.update(dt)
    --preresqs
    input:update()
    updateScale()


    for i, v in ipairs(entities) do
        if v.update then
            v:update(dt)
        end
        if v.updateGlobalPosition then
            v:updateGlobalPosition()        
        end
        if v.updateChildren then
            v:updateChildren(dt)
        end
    end
end

function love.draw()
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear(0.2, 0.6, 0.9)

    --DRAW GAME
    for i, v in ipairs(entities) do
        if v.draw then
            v:draw()
        end
        v:drawChildren()
    end

    love.graphics.setCanvas()
    love.graphics.draw(gameCanvas, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, 0, scale, scale, gameCanvas:getWidth() / 2, gameCanvas:getHeight() / 2)
end