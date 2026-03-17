love = require 'love'
love.graphics.setDefaultFilter('nearest', 'nearest')

--Require libs
local anim8 = require 'libs.anim8'
local baton = require 'libs.baton'
flux = require 'libs.flux'
require("libs.batteries"):export()
--ASSETS
local assets = {}
assets.images = {}
assets.images.bigFlower = love.graphics.newImage("img/bigFlower.png")
assets.images.stem = love.graphics.newImage("img/flowerstem.png")
assets.images.flowerhead = love.graphics.newImage("img/flowerhead.png")
assets.images.testbuttonnormal = love.graphics.newImage("img/testbuttonnormal.png")
assets.images.testbuttonhover = love.graphics.newImage("img/testbuttonhover.png")
assets.images.testbuttonpressed = love.graphics.newImage("img/testbuttonpressed.png")

assets.images.buyButtonNormal = love.graphics.newImage("img/buybuttonnormal.png")
assets.images.buyButtonHover = love.graphics.newImage("img/buybuttonhover.png")
assets.images.buyButtonPressed = love.graphics.newImage("img/buybuttonpressed.png") 
assets.images.itemframe = love.graphics.newImage("img/itemframe.png")



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

local function updateScale()
    maxScaleX = love.graphics.getWidth() / gameCanvas:getWidth()
    maxScaleY = love.graphics.getHeight() / gameCanvas:getHeight()
    scale = math.min(maxScaleX, maxScaleY)
    local scaledScreenX, scaledScreenY = love.graphics.getWidth() / scale, love.graphics.getHeight() / scale
    local screenX, screenY = gameWidth, gameHeight
    local mouseOffX = (screenX - scaledScreenX) / 2
    local mouseOffY = (screenY - scaledScreenY) / 2
    mouseX, mouseY = (love.mouse.getX() / scale) + mouseOffX, (love.mouse.getY() / scale) + mouseOffY
end

--Collision functions
local function PointAABB(px, py, x, y, w, h)
    return (px >= x and px <= x + w and py >= y and py <= y + h)
end


--Entities and scene objects
local entities = {}
local function addObject(object)
    table.push(entities, object)
end


--INPUT
input = baton.new {
  controls = {
    toggleWindowMode = {'key:f11', 'key:f'},

    clickLeft = {'mouse:1'},

    ui_clickLeft = {'mouse:1'},
    ui_clickRight = {'mouse:2'},
  },
  joystick = love.joystick.getJoysticks()[1],
}


--test pubsub
--TODO: don't leave this here naked

local pubbus = pubsub()

local function awesomePrint(anExtraMessage, ipx, ipy)
    print("YOU ARE SEEING THIS BECAUSE YOU ARE SUBSCRIBED")
    print(anExtraMessage or "There was no extra message")
    print(ipx, ipy)

end

pubbus:subscribe('thedrink', awesomePrint)

pubbus:publish('thedrink', "A awesome message", 10, 100)


--We are making signals
local Signal = class({
    name = "Signal"
})

function Signal:new()
    --connection = {object, function}
    self._connections = {}

end

function Signal:connect(func, object)
    local connection = {callback = func, connector = object}
    print(connection.callback)
    print(connection.connector)
    table.insert(self._connections, connection)
end

function Signal:disconnect(item)
    for i, v in ipairs(self._connections) do
        local connector = v.connector
        local callback = v.callback

        if item == connector or item == callback then
            table.remove(self._connections, i)
            break
        end
        
    end
end

function Signal:emit(...)
    for i, v in ipairs(self._connections) do
        local connector = v.connector
        print(connector)
        local callback = v.callback
        print(callback)

        if connector ~= nil then
            callback(connector, ...)
        else
            callback(...)
        end
    end
end



--CLASSES

--CLASS ENTITY
local Object = class({
    name = "Object"
})

function Object:new()
    --Change soon
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

function Object:makeNewEvent(eventName)


end

--Subscribe to a named event from the given objects eventbus, giving it a function to call when it publishes something
function Object:subscribeTo(object, eventname, callback)
    if object._eventbus == nil then
        object._eventbus = pubsub()
    end
    object._eventbus:subscribe(eventname, callback)
end

function Object:emitEvent(eventname, ...)
    --self._eventbus:publish(eventname, ...)
end

function Object:setScript(scriptfunc)
    self.update = scriptfunc
    print("Changed script")
end

--FOR NOW PARENTS CANNOT HAVE GRANDCHILDREN UNTILL I LEARN POSITIONS LOL, THINK OF THIS ENGINE LIKE ADDING PETALS TO A FLOWER BUD, AND ONLY THAT FLOWERBUD AND NOT OTHER PETALS
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
    self:_get_global_position()


end

function Entity:updateGlobalPosition()
    self:_get_global_position()
    if self.parent then
        local gpos = self:_get_global_position()
        local gParentpos = self.parent:_get_global_position()
        local posx, posy = self.position.x + gParentpos.x, self.position.y + gParentpos.y
        _G._transformCache[self._objectId] = {x = posx, y = posy}
    else
        _G._transformCache[self._objectId].x = self.position.x
        _G._transformCache[self._objectId].y = self.position.y
    end
    if self.parent then

    else

    end
end

function Entity:_get_global_position()
    if _G._transformCache == nil then
        _G._transformCache = {}
        local pos = {x = self.position.x, y = self.position.y}
        _G._transformCache[self._objectId] = pos
    end
    if _G._transformCache[self._objectId] == nil then
        local pos = {x = self.position.x, y = self.position.y}
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
    local posx, posy = self.position.x, self.position.y
    if self.parent then
        posx = posx + self.parent.position.x
        posy = posy + self.parent.position.y
    end
    if true then
        love.graphics.draw(
        self.texture, -- Texture
        posx, --Position X
        posy, --Position Y
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

function Label:setAlpha(num)
    self.alpha = num
end

function Label:setText(text)
    if type(text) ~= 'string' then
        self.text = tostring(text)
    else
        self.text = text
    end

end

function Label:draw()
    local posx, posy = self.position.x, self.position.y
    if self.parent then
        posx = posx + self.parent.position.x
        posy = posy + self.parent.position.y
    end
    love.graphics.setFont(self.font)
    love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.alpha)
        love.graphics.printf (
        self.text, -- Text
        posx, --Position X
        posy, --Position Y
        self.wrapLimit, --Wrap Limit
        self.alignMode, --AlignMode
        self.rotation, --Rotation
        self.scale.x, --Scale X
        self.scale.y --Scale Y
    )
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(assets.fonts.default)
end
--CLASS CONTROL
local Control = class({
    name = "Control",
    extends = Entity
})

function Control:new(x, y, ...)
    self:super(x, y, ...)
end

local CircleShape = class({
    name = "CircleShape",
})

function CircleShape:new(radius)
    self.radius = radius or 32
end

function CircleShape.draw(obj)
    if true then
        love.graphics.circle(
        obj.drawMode,
        obj.position.x,
        obj.position.y,
        obj.shape.radius
        )
    end
end

function CircleShape:setRadius(radius)
    self.radius = radius
end

local RectShape = class({
    name = "RectShape",
})

--Defaults to 32
function RectShape:setSize(w, h)
    self.size.w = w or 32
    self.size.h = h or 32
end

function RectShape:new(w, h)
    self.size = {w = w, h = h}
    self.cornerRadius = {x = 0, y = 0}
end

function RectShape.draw(obj)
    if true then
        love.graphics.rectangle(
        obj.drawMode,
        obj.position.x,
        obj.position.y,
        obj.shape.size.w,
        obj.shape.size.h,
        obj.shape.cornerRadius.x,
        obj.shape.cornerRadius.y,
        obj.segements
        )
    end
end

local Color = class({
    name = "Color",
})

function Color:new (...)
  local length = select("#", ...) 

  if length == 1 then
    local color = ...
    self.r = color.r
    self.g = color.g
    self.b = color.b
    self.a = color.a
  elseif length >= 3 then
    local r, g, b, a = ...
    self.r = r
    self.g = g
    self.b = b
    self.a = a or 1
  else
    error("this shit dont got the right amount of args")
  end
end
--Set color constants
Color.Red = Color(1, 0, 0)
Color.Green = Color(0, 1, 0)
Color.Blue = Color(0, 0, 1)
Color.White = Color(1, 1, 1)
Color.Black = Color(0, 0, 0)

function Color:setColor(r, g, b, a)
    if r then
        if type(r) == "table" then
            self.r = r.r
            self.g = r.g
            self.b = r.b
            if g then
                self.a = g
            else
                self.a = 1
            end
        else
            self.r = r or 1
            self.g = g or 1
            self.b = b or 1
            self.a = a or 1
        end
    else
        self.r = r or 1
        self.g = g or 1
        self.b = b or 1
        self.a = a or 1
    end
end

local ColorShape = class({
    name = "ColorShape",
    extends = Control,
})

function ColorShape:new(shape, x, y, color, alpha)
    self:super(x, y)
    self.shape = shape or RectShape(32, 32)
    self.color = color or Color(Color.White)
    self.color.a = alpha or 1
    self.drawMode = "fill"
end

function ColorShape:draw()
    love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.color.a)
    self.shape.draw(self)
    love.graphics.setColor(1, 1, 1, 1)
end

--CLASS BUTTON
local Button = class({
    name = "Button",
    extends = Control,
})

function Button:new(text, x, y)
    self:super(x, y)
    self.text = text or ""

    self.pressedFunction = nil
end

local TextureButton = class({
    name = "TextureButton",
    extends = Control,
})

function TextureButton:new(normaltexture, x, y)
    self:super(x, y)
    self.text = nil

    self.color = {r = 1, g = 1, b = 1}
    self.alpha = 1

    self.sPressed = Signal()

    self.pressedFunction = nil

    self.textureNormal = normaltexture or nil
    self.texturePressed = nil
    self.textureHover = nil

    self.dimensions = {w = 64, h = 16}

    if self.textureNormal then
        self.dimensions.w = self.textureNormal:getWidth()
        self.dimensions.h = self.textureNormal:getHeight()
    end

    self.isPressed = false
    self.isHovered = false
end

function TextureButton:setTextureNormal(texture)
    self.textureNormal = texture
end
function TextureButton:setTextureHover(texture)
    self.textureHover = texture
end
function TextureButton:setTexturePressed(texture)
    self.texturePressed = texture
end

function TextureButton:getTextureNormal()
    return self.textureNormal
end
function TextureButton:getTextureHover()
    return self.textureHover
end
function TextureButton:getTexturePressed()
    return self.texturePressed
end

function TextureButton:update()
    if self.visible == true then
        local posx, posy = self.position.x, self.position.y
        local mx, my = mouseX, mouseY
        if self.parent then
            posx = posx + self.parent.position.x
            posy = posy + self.parent.position.y
        end

        if PointAABB(mx, my, posx, posy, self.dimensions.w, self.dimensions.h) then
            self.isHovered = true

            if input:pressed('ui_clickLeft') then
                
                if self.pressedFunction ~= nil then
                    --self:pressedFunction()
                    self.sPressed:emit()
                end
            end

            if input:down('ui_clickLeft') then
                self.isPressed = true
            else
                self.isPressed = false
            end
        else
            self.isHovered = false
            self.isPressed = false
        end
    end
end

function TextureButton:setPressFunction(fn)
    self.pressedFunction = fn
end

function TextureButton:draw()
    if self.visible == true then
        local posx, posy = self.position.x, self.position.y
        if self.parent then
            posx = posx + self.parent.position.x
            posy = posy + self.parent.position.y
        end

        if self.isPressed == false and self.isHovered == false then
            if self.textureNormal then
                local scale = self.scale
                love.graphics.draw(
                    self.textureNormal,
                    posx,
                    posy,
                    self.rotation,
                    scale.x,
                    scale.y,
                    0,
                    0,
                    0,
                    0
                )
            end
        end

        if self.isPressed == false and self.isHovered == true then
            if self.textureHover then
                local scale = self.scale
                love.graphics.draw(
                    self.textureHover,
                    posx,
                    posy,
                    self.rotation,
                    scale.x,
                    scale.y,
                    0,
                    0,
                    0,
                    0
                )
            end
        end

        if self.isPressed == true then
            if self.texturePressed or self.textureHover then
                local texture = self.texturePressed or self.textureHover
                local scale = self.scale
                love.graphics.draw(
                    texture,
                    posx,
                    posy,
                    self.rotation,
                    scale.x,
                    scale.y,
                    0,
                    0,
                    0,
                    0
                )
            end
        end

        if self.text ~= nil then
            love.graphics.printf (
            self.text, -- Text
            posx, --Position X
            posy, --Position Y
            self.wrapLimit or 256, --Wrap Limit
            'left', --AlignMode
            self.rotation, --Rotation
            self.scale.x, --Scale X
            self.scale.y --Scale Y
        )
        end
    end
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



--CLASS CAMERA

local Camera = class({
    extends = Entity
})

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

    local stem = Sprite(assets.images.stem, 0, 50)
    self:addChild(stem)

    local flowerhead = Sprite(assets.images.flowerhead, 10, 10)
    self:addChild(flowerhead)
    
    local count = Label("0", -200, -200)
    count:setAlignMode('left')
    count:setWrapLimit(64)
    count:setFont(assets.fonts.it32)
    count:setScript(require 'scripts.counttext')
    count:setAlpha(0)
    self:addChild(count)
    self.countText = count
    count.flower = self

    local startClickText = Label("START CLICKING", 0, -30)
    startClickText:setScript(require 'scripts.startText')
    startClickText:setFont(assets.fonts.it32)
    startClickText.timer = 5
    self:addChild(startClickText)
    self.startClickText = startClickText

    local startClickText = Label("CLICK MANY MANY TIMES", 0, -30)
    startClickText:setScript(require 'scripts.startText2')
    startClickText:setFont(assets.fonts.it32)
    startClickText:setWrapLimit(512)
    startClickText.timer = 6
    startClickText.timer2 = 12
    self:addChild(startClickText)
    self.startClickText = startClickText

    self.count = 1
end

function BigFlower:update(dt)
    if input:pressed('clickLeft') then
        self.count = self.count + 1
        self.countText:setText(self.count)
    end
end

--CLASS SHOP CHOICE
local ShopChoice = class({
    name = "ShopChoice",
    extends = Entity
})

function ShopChoice:new(x, y)
    self:super(x, y)
    self.itemId = 1
    self.price = 0

    --Needs buttons for buying and selling buildings
    addObject(Sprite(assets.images.itemframe, self.position.x, self.position.y))
    local sprite = Sprite(assets.images.bigFlower, self.position.x, self.position.y)
    addObject(sprite)

    local buyButton = TextureButton(assets.images.buyButtonNormal, self.position.x - 20, self.position.y + 50)
    buyButton:setTextureHover(assets.images.buyButtonHover)
    buyButton:setTexturePressed(assets.images.buyButtonPressed)
    addObject(buyButton)
    local sellButton = TextureButton(assets.images.buyButtonNormal, self.position.x + 30, self.position.y + 50)
    sellButton:setTextureHover(assets.images.buyButtonHover)
    sellButton:setTexturePressed(assets.images.buyButtonPressed)
    addObject(sellButton)

    addObject(ColorShape(CircleShape(4), self.position.x, self.position.y))


end

--------------------------------------------------------

local Game = Object()
Game:setScript(require 'scripts.game')
table.insert(entities, Game)

--GAME
local bigFlower = BigFlower()
bigFlower.position.x = 200
bigFlower.position.y = 200
addObject(bigFlower)

local countHintText1 = Label("<-- get this to 100", 60, 0)
countHintText1:setScript(require 'scripts.counthinttext')
countHintText1:setFont(assets.fonts.it32)
countHintText1:setAlpha(0)
countHintText1.flower = bigFlower
countHintText1.disappeartimer = 0
countHintText1.timer = 1
countHintText1.state = 1
countHintText1.targetx = 50
countHintText1.originPos = {x = countHintText1.position.x, countHintText1.position.y}
addObject(countHintText1)

local buildingShop = Entity(0, 300)
buildingShop.choices = {}
local bg = ColorShape(RectShape(420, 300), buildingShop.position.x, buildingShop.position.y, Color.Blue)
addObject(bg)
local xstart = 30
local ystart = 300
    local xoff = 100
    local c1 = ShopChoice(xstart + xoff * 0, ystart)
    c1.bigFlower = bigFlower
    local c1 = ShopChoice(xstart + xoff * 1, ystart)
    c1.bigFlower = bigFlower
    local c1 = ShopChoice(xstart + xoff * 2, ystart)
    c1.bigFlower = bigFlower
    local c1 = ShopChoice(xstart + xoff * 3, ystart)
    c1.bigFlower = bigFlower

function love.update(dt)
    --preresqs
    flux.update(dt)
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
