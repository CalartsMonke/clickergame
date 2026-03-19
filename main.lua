love = require 'love'
love.graphics.setDefaultFilter('nearest', 'nearest')

--Require libs
local anim8 = require 'libs.anim8'
local baton = require 'libs.baton'
flux = require 'libs.flux'
require("libs.batteries"):export()

--Engine
local Engine = {}
Engine._currentCamera = nil

function setCamera(cam)
    Engine._currentCamera = cam
end




--OBJECT GROUPS CAUSE I LOVE GODOT
local _objectgroups = {}


function addObjectToGroup(name, object)
    if name == nil then error("include a name") end
    if _objectgroups[name] == nil then
        _objectgroups[name] = {}
    end
    if object == nil then error("include a object after name") end
    table.push(_objectgroups[name], object)
end

function getFirstObjectFromGroup(name)
    if _objectgroups[name] == nil then
        error("'"..name.."' name does not exists in groups")
    end
    return _objectgroups[name][1]
end

--ASSETS
local assets = {}
assets.images = {}
assets.images.bigFlower = love.graphics.newImage("img/bigFlower.png")
assets.images.stem = love.graphics.newImage("img/flowerstem.png")
assets.images.flowerhead = love.graphics.newImage("img/flowerhead.png")
assets.images.testbuttonnormal = love.graphics.newImage("img/testbuttonnormal.png")
assets.images.testbuttonhover = love.graphics.newImage("img/testbuttonhover.png")
assets.images.testbuttonpressed = love.graphics.newImage("img/testbuttonpressed.png")
assets.images.grassbg = love.graphics.newImage("img/backgroundgrass.png")
assets.images.pinkflower = love.graphics.newImage("img/pinkflower.png")
assets.images.redflower = love.graphics.newImage("img/redflower.png")
assets.images.yellowflower = love.graphics.newImage("img/yellowflower.png")
assets.images.greenflower = love.graphics.newImage("img/greenflower.png")


assets.images.buildingboardbg = love.graphics.newImage("img/buildingboardbg.png")
assets.images.buildingboardbutton = love.graphics.newImage("img/buildingboardbutton.png")
assets.images.pinkbunny = love.graphics.newImage("img/bunnypink.png")

assets.images.buyButtonNormal = love.graphics.newImage("img/buybuttonnormal.png")
assets.images.buyButtonHover = love.graphics.newImage("img/buybuttonhover.png")
assets.images.buyButtonPressed = love.graphics.newImage("img/buybuttonpressed.png")
assets.images.sellButtonNormal = love.graphics.newImage("img/sellbuttonnormal.png")
assets.images.sellButtonHover = love.graphics.newImage("img/sellbuttonhover.png")
assets.images.sellButtonPressed = love.graphics.newImage("img/sellbuttonpressed.png")
assets.images.itemframe = love.graphics.newImage("img/itemframe.png")



assets.fonts = {}
assets.fonts.default = love.graphics.getFont()
assets.fonts.it32 = love.graphics.newFont('fonts/Ithaca-LVB75.ttf', 32, 'mono')
assets.fonts.sl32 = love.graphics.newFont('fonts/Cutehandwriting-Regular.otf', 32, 'mono')



--game preresqs
local mouseX, mouseY = 0, 0
local screenMouseX, screenMouseY, worldMouseX, worldMouseY = 0, 0, 0, 0
local gameWidth, gameHeight = 640, 360

--Canvas and scale
--make a new canvas
local gameCanvas = love.graphics.newCanvas(640, 360)
local uiCanvas = love.graphics.newCanvas(640, 360)

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

    --Update mouse based on camera
    if Engine._currentCamera then
        screenMouseX = mouseX
        screenMouseY = mouseY
        worldMouseX, worldMouseY = Engine._currentCamera:toWorldPosition(mouseX, mouseY)
    else
        screenMouseX = mouseX
        screenMouseY = mouseY
        worldMouseX = mouseX
        worldMouseY = mouseY
    end
end

--Collision functions
local function PointAABB(px, py, x, y, w, h)
    return (px >= x and px <= x + w and py >= y and py <= y + h)
end

--Math functions
local function Percent(num, den)
    return (num/den)
end

--Entities and scene objects
local entities = {}
local function addObject(object)
    table.push(entities, object)
    return object
end

local function sortByZ(a, b)
    return a.zIndex > b.zIndex
end

--INPUT
input = baton.new {
  controls = {
    toggleWindowMode = {'key:f11', 'key:f'},

    clickLeft = {'mouse:1', 'key:space'},

    ui_clickLeft = {'mouse:1'},
    ui_clickRight = {'mouse:2'},
    debug_characterSpawn = {'key:f1'}
  },
  joystick = love.joystick.getJoysticks()[1],
}

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
        local callback = v.callback
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
    self._postReady = false
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
    self._guiDraw = false
    self.children = {}
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
end

--FOR NOW PARENTS CANNOT HAVE GRANDCHILDREN UNTILL I LEARN POSITIONS LOL, THINK OF THIS ENGINE LIKE ADDING PETALS TO A FLOWER BUD, AND ONLY THAT FLOWERBUD AND NOT OTHER PETALS
function Object:addChild(child)
    child.parent = self
    table.push(self.children, child)

    --Cache global pos
end

function Object:setDrawToGui(bool)
    self._guiDraw = bool
end

function Object:getDrawToGui()
    return self._guiDraw
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
    self.zIndex = 1
    self._transformDirty = false
    self.position = vec2(x or 0, y or 0)
    self.globalPosition = vec2(0, 0)
    self.scale = vec2(1, 1)
    self.rotation = 0
    self:_get_global_position()
end

function Entity:setZIndex(num)
    self.zIndex = num
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

function Sprite:setTexture(texture)
    self.texture = texture
end

function Sprite:getTexture()
    return self.texture
end

function Sprite:draw()
    local posx, posy = self.position.x, self.position.y
    if self.parent then
        posx = posx + self.parent.position.x
        posy = posy + self.parent.position.y
    end
    posx, posy = math.floor(posx), math.floor(posy)
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
        local posx, posy = obj.position.x, obj.position.y
        if obj.parent then
            posx = posx + obj.parent.position.x
            posy = posy + obj.parent.position.y
        end
        posx, posy = math.floor(posx), math.floor(posy)
        love.graphics.circle(
        obj.drawMode,
        posx,
        posy,
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
        local posx, posy = obj.position.x, obj.position.y
        if obj.parent then
            posx = posx + obj.parent.position.x
            posy = posy + obj.parent.position.y
        end
        posx, posy = math.floor(posx), math.floor(posy)
        love.graphics.rectangle(
        obj.drawMode,
        posx,
        posy,
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

--CLASS LABEL
local Label = class({
    name = "Label",
    extends = Entity
})

function Label:new(text, x, y)
    self:super(x, y)
    text = tostring(text)
    self.text = text or "Hello World"
    self.visibleCharacters = 0
    self.visibleCharactersMax = 0
    self.visibleRatio = 0
    self.characterLimitChangeOnTextChange = true
    if text ~= nil then
        self.visibleCharacters = text:len()
        self.visibleCharactersMax = self.visibleCharacters

        self.visibleRatio = 1
    end

    self.color = Color(1, 1, 1, 1)
    self.dropColor = Color(0.1, 0.1, 0.1, 1)
    self.dropShadowOffset = vec2(0, 0)
    self.alpha = 1
    self.alignMode = 'left'
    self.wrapLimit = 256
    self.font = assets.fonts.default
    self.dropShadow = false
end

--Number of pixels before text wraps
function Label:setWrapLimit(limit)
    self.wrapLimit = limit
end

function Label:setDropShadow(bool)
    self.dropShadow = bool
end

function Label:setDropShadowOffset(x, y)
    self.dropShadowOffset.x = x
    self.dropShadowOffset.y = y
end

function Label:setVisibleCharacterLimit(num)
    self.visibleCharacters = num or 0
    self.visibleCharacters = math.clamp(self.visibleCharacters, 0, self.visibleCharactersMax)
end

function Label:setVisibleCharacterRatio(ratio)
    self.visibleRatio = ratio
    self.visibleRatio = math.clamp(self.visibleRatio, 0, 1)
end

function Label:getVisibleRatio()
    return self.visibleRatio
end

function Label:setCharacterLimitChangeOnText(bool)
    self.characterLimitChangeOnTextChange = bool
end

function Label:getVisibleCharacterLimit()
    return self.visibleCharacters
end

function Label:_update()
    --self.visibleChracters = math.lerp(self.visibleCharacters, self.visibleCharactersMax, self.visibleRatio)
    self.visibleCharacters = math.clamp(self.visibleCharacters, 0, self.visibleCharactersMax)

    --self.visibleRatio = Percent(self.visibleCharacters, self.visibleCharactersMax)
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

function Label:getFont()
return self.font
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
    self.visibleCharactersMax = self.text:len()
    if self.characterLimitChangeOnTextChange then
        self.visibleCharacters = self.visibleCharactersMax
    end

end

function Label:draw()
    local posx, posy = self.position.x, self.position.y

    local string = self.text
    string = string:sub(1, self.visibleCharacters)
    
    if self.parent then
        posx = posx + self.parent.position.x
        posy = posy + self.parent.position.y
    end
    love.graphics.setFont(self.font)

    if self.dropShadow then
        love.graphics.setColor(self.dropColor.r, self.dropColor.g, self.dropColor.b, self.dropColor.a)
         love.graphics.printf (
        string, -- Text
        posx, --Position X
        posy, --Position Y
        self.wrapLimit, --Wrap Limit
        self.alignMode, --AlignMode
        self.rotation, --Rotation
        self.scale.x, --Scale X
        self.scale.y, --Scale Y
        self.dropShadowOffset.x,
        self.dropShadowOffset.y
    )
    end


    love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.alpha)
        love.graphics.printf (
        string, -- Text
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
    self.sHovered = Signal()

    self.pressedFunction = nil

    self.textureNormal = normaltexture or nil
    self.texturePressed = nil
    self.textureHover = nil

    self.dimensions = {w = 64, h = 16}

    if self.textureNormal then
        self.dimensions.w = self.textureNormal:getWidth()
        self.dimensions.h = self.textureNormal:getHeight()
    end

    self._postHover = false
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
        local mx, my = worldMouseX, worldMouseY
        if self.parent then
            posx = posx + self.parent.position.x
            posy = posy + self.parent.position.y
        end

        if PointAABB(mx, my, posx, posy, self.dimensions.w, self.dimensions.h) then
            self.isHovered = true

            if self._postHover ~= true then
                self.sHovered:emit()
                self._postHover = true
            end

            if input:pressed('ui_clickLeft') then
                self.sPressed:emit()
                if self.pressedFunction ~= nil then
                    --self:pressedFunction()
                end
            end

            if input:down('ui_clickLeft') then
                self.isPressed = true
            else
                self.isPressed = false
            end
        else
            self._postHover = false
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
        posx, posy = math.floor(posx), math.floor(posy)

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

function Camera:new(...)
    self:super(...)
end

function Camera:toWorldPosition(x, y)
    return x + self.position.x, y + self.position.y
end

function Camera:toScreenPosition(x, y)
    return x - self.position.x, y - self.position.y
end

--GAME SPECIAL CLASSES

--Class BuildingFlower
local BuildingFlower = class({
    name = "BuildingFlower",
    extends = Entity
})

function BuildingFlower:new(x, y)
    self:super(x, y)

    self.bigFlower = getFirstObjectFromGroup("bigflower")
    self.cps = 0.2
    self.count = 0
    self.itemId = 1
    self.price = 0
    self.basePrice = 10



     --Needs buttons for buying and selling buildings
    addObject(Sprite(assets.images.itemframe, self.position.x, self.position.y))
    local sprite = Sprite(assets.images.yellowflower, self.position.x, self.position.y)
    self.sprite = sprite
    addObject(sprite)
end

function BuildingFlower:ready()


    local buyButton = TextureButton(assets.images.buyButtonNormal, self.position.x - 20, self.position.y + 50)
    buyButton:setTextureHover(assets.images.buyButtonHover)
    buyButton:setTexturePressed(assets.images.buyButtonPressed)
    buyButton.sPressed:connect(self.buyItem, self)
    self.buyButton = buyButton
    addObject(buyButton)
    local sellButton = TextureButton(assets.images.sellButtonNormal, self.position.x + 30, self.position.y + 50)
    sellButton.sPressed:connect(self.sellItem, self)
    sellButton:setTextureHover(assets.images.sellButtonHover)
    sellButton:setTexturePressed(assets.images.sellButtonPressed)
    self.sellButton = sellButton
    addObject(sellButton)

    self.priceLabel = Label(self.price, self.position.x - 20, self.position.y + 65 )
    self.priceLabel:setFont(assets.fonts.it32)
    self.priceLabel:setAlignMode('center')
    self.priceLabel:setWrapLimit(100)
    self.priceLabel:setDropShadow(true)
    self.priceLabel:setDropShadowOffset(-1, -1)
    addObject(self.priceLabel)

    --ddObject(ColorShape(CircleShape(4), self.position.x, self.position.y))
end

function BuildingFlower:buyItem()
    if self.bigFlower then
        if self.bigFlower.count >= self.price then
            self.bigFlower.count = self.bigFlower.count - self.price
            self.count = self.count + 1
        end
    end
end

function BuildingFlower:sellItem()
    if self.bigFlower then
        if self.count > 0 then
            self.count = self.count - 1
            self.bigFlower.count = self.bigFlower.count + self.price * 0.2
        end
    end
end

function BuildingFlower:update(dt)
    self.price = self.basePrice * (1.4^self.count)
    local pricestring = tostring(self.price)
    pricestring = pricestring:sub(1, 6)
    self.priceLabel:setText(pricestring)
    self.bigFlower.count = self.bigFlower.count + (self.cps * self.count )* dt
end


--CLASS BIGFLOWER
local BigFlower = class({
    name = "BigFlower",
    extends = Entity,
})

function BigFlower:new(x, y)
    self:super(x, y)
    addObjectToGroup("bigflower", self)
    local sprite = Sprite(assets.images.bigFlower, self.position.x, self.position.y)
    --self:addChild(sprite)
    self.sprite1 = sprite

    local stem = Sprite(assets.images.stem, 0, 50)
    self:addChild(stem)

    local flowerhead = Sprite(assets.images.flowerhead, 10, 10)
    self:addChild(flowerhead)
    
    local count = Label("0", 10, 0)
    count:setAlignMode('left')
    count:setWrapLimit(256)
    count:setFont(assets.fonts.it32)
    count:setScript(require 'scripts.counttext')
    count:setAlpha(0)
    count:setDrawToGui(true)
    addObject(count)
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

function BigFlower:ready()

end

function BigFlower:update(dt)
    if input:pressed('clickLeft') then
        self.count = self.count + 1
    end
    self.countText:setText(math.floor(self.count))
end

--Class GameCamera
local GameCamera = class({
    name = "GameCamera",
    extends = Camera
})

function GameCamera:new(x, y)
    self:super(x, y)
    self.camTargetY = self.position.y or 0
    self.targetArea = "menu" --menu will be the downwards one

end

function GameCamera:switchMenu()
    if self.targetArea == 'menu' then
        self.camTargetY = 200
        self.targetArea = 'main'
    elseif self.targetArea == 'main' then
        self.camTargetY = 0
        self.targetArea = 'menu'
    end
end

function GameCamera:update(dt)
    --self.position.y = self.camTargetY
    flux.to(self.position, 0.2, {y = self.camTargetY})
end

--Class DialougeBox
local DialougeBox = class({
    name = "DialougeBox",
    extends = Entity
})

function DialougeBox:new(x, y)

    self.testString = "This... will be... fun, I really\n hope so......."

    self:super(x, y)
    self.textStrings = {}
    self.textStringIndex = 1
    self.charactersShowing = 1
    self.previouscharactersShowing = self.charactersShowing

    self.textWriteDelay = 0.1

    self.boxSprite = nil
    self.textLabel = Label("Test", x, y)
    self.border = addObject(ColorShape(RectShape(640, 120), 0, 250, Color(0.3, 0.3, 0.3), 1))
    self.box = addObject(ColorShape(RectShape(460, 100), 80, 250, Color(Color.Black), 1))
    self.nameTag = addObject(Label("Bunny:", 90, 250))
    self.nameTag:setFont(assets.fonts.sl32)
    self.text = addObject(Label("This will be fun, I really\n hope so.", 90, 250 + 32))
    self.text:setWrapLimit(450)
    self.text:setFont(assets.fonts.sl32)

    self._letterFont = assets.fonts.sl32
    self._fontWidth = 16
    self._fontHeight = 32
    self._letterX = 0
    self._letterY = 0
    self._letterIndex = 1
end

function DialougeBox:spawnLetter(x, y, index)
    local string = self.testString

    local letter = string:sub(index, index)
    local nextletter = string:sub(index + 1, index + 1)
    print("letter "..letter)


    self.textWriteDelay = 0.02

    local label = Label(letter, x, y+10)
    label.targetPositionY = y
    label:setScript(require 'scripts.letterSlideUp')
    label:setText(letter)
    label:setFont(self.text:getFont())
    addObject(label)

    local fontoffy = self._letterFont:getHeight(letter)
    local fontoffx = self._letterFont:getWidth(letter)

    if letter == "\n" then
        self._letterX = 0
        self._letterY = self._letterY + fontoffy
    end

    if letter == "." then
        self.textWriteDelay = 0.1
    end

    self._letterX = self._letterX + fontoffx
    self._letterIndex = self._letterIndex + 1
end

function DialougeBox:update(dt)
    self.previousCharactersShowing = self.charactersShowing
    self.textWriteDelay = self.textWriteDelay - dt
    if self.textWriteDelay <= 0 then
        self.charactersShowing = self.charactersShowing + 1
        self:spawnLetter(self.text.position.x + (self._letterX), self.text.position.y + self._letterY, self._letterIndex)
    end

    self.text:setVisibleCharacterLimit(math.floor(0))
end

function DialougeBox:advanceText()
    self.charactersShowing = 1
    self.textStringIndex = self.textStringIndex + 1
end

function DialougeBox:setIndexedText(string, index)
    local i = index or 1
    self.textStrings[i] = tostring(string)
end

function DialougeBox:reset()
    self.charactersShowing = 1
    self.textStringIndex = 1
end

--------------------------------------------------------

local Game = Object()
Game:setScript(require 'scripts.game')
table.insert(entities, Game)

local gamebg = ColorShape(RectShape(6000, 6000), 0, 0, Color(0.2, 0.1, 0.8))
addObject(gamebg)

local grassbg = addObject(Sprite(assets.images.grassbg))

--GAME
local bigFlower = BigFlower()
bigFlower.position.x = 200
bigFlower.position.y = 150
addObject(bigFlower)

local countHintText1 = Label("<-- get this to 100", 60, 0)
countHintText1:setScript(require 'scripts.counthinttext')
countHintText1:setFont(assets.fonts.it32)
countHintText1:setAlpha(0)
countHintText1:setDrawToGui(true)
countHintText1.flower = bigFlower
countHintText1.disappeartimer = 0
countHintText1.timer = 1
countHintText1.state = 1
countHintText1.targetx = 50
countHintText1.originPos = {x = countHintText1.position.x, countHintText1.position.y}
addObject(countHintText1)

local camera = GameCamera(0, 0)
addObject(camera)
setCamera(camera)

local buildingShop = Entity(0, 360)
buildingShop.choices = {}
local bg = Sprite(assets.images.buildingboardbg, buildingShop.position.x, buildingShop.position.y)
addObject(bg)
local xstart = 30
local ystart = buildingShop.position.y + 5
    local xoff = 100
    --Yellow flower
    local c1 = BuildingFlower(xstart + xoff * 0, ystart)
    c1.bigFlower = bigFlower
    addObject(c1)

    --Pink flower
    local c1 = BuildingFlower(xstart + xoff * 1, ystart)
    c1.bigFlower = bigFlower
    c1.sprite:setTexture(assets.images.pinkflower)
    c1.basePrice = 50
    c1.itemId = 2
    c1.cps = 1.4
    addObject(c1)

    --Red flower
    local c1 = BuildingFlower(xstart + xoff * 2, ystart)
    c1.bigFlower = bigFlower
    c1.sprite:setTexture(assets.images.redflower)
    c1.basePrice = 800
    c1.itemId = 3
    c1.cps = 6
    addObject(c1)

    --Green flower
    local c1 = BuildingFlower(xstart + xoff * 3, ystart)
    c1.bigFlower = bigFlower
    c1.sprite:setTexture(assets.images.greenflower)
    c1.basePrice = 6000
    c1.itemId = 4
    c1.cps = 40
    addObject(c1)
buildingShop.menuButton = addObject(TextureButton(assets.images.buildingboardbutton, 300, 350))
buildingShop.menuButton.sHovered:connect(camera.switchMenu, camera)

local bunny = addObject(Sprite(assets.images.pinkbunny, 0, 0))

addObject(DialougeBox())





--GAME UPDATE LOOPS
function love.update(dt)
    --preresqs
    flux.update(dt)
    input:update()
    updateScale()

    for i, v in ipairs(entities) do
        if v._postReady ~= true then
            v._postReady = true
            if v.ready then
                v:ready() --only ran once at the start of its life
            end
        end

        if v._update then
            v:_update(dt) --Objects original update
        end
        if v.update then
            v:update(dt) --Personailized script update
        end
        if v.updateGlobalPosition then
            v:updateGlobalPosition() --Idk not ready yet
        end
        if v.updateChildren then
            v:updateChildren(dt) -- Update children
        end
    end
end

function love.draw()
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear()

    --Camera
    love.graphics.push()
    if Engine._currentCamera then
        local cam = Engine._currentCamera
        love.graphics.translate(-cam.position.x, -cam.position.y)
    end

    --DRAW GAME
    --EVERYTHING DRAWN HERE IS TRANSLATED BY THE ENGINES CURRENT CAMERA
    for i, v in ipairs(entities) do
        if v:getDrawToGui() == false then
            if v.draw then
                v:draw()
            end
            v:drawChildren()
        end
    end
    love.graphics.pop() --pop camera

    --UI CANVAS
    --EVERYTHING DRAWN HERE IS PUT ON THE SCREEN WITH NO TRANSLATIONS
    love.graphics.setCanvas(uiCanvas)
    love.graphics.clear()

    for i, v in ipairs(entities) do
        if v:getDrawToGui() then
            if v.draw then
                v:draw()
            end
            v:drawChildren()
        end
    end

    --Reset back to normal canvas
    love.graphics.setCanvas()
    --Draw game canvas
    love.graphics.draw(gameCanvas, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, 0, scale, scale, gameCanvas:getWidth() / 2, gameCanvas:getHeight() / 2)

    --Draw game canvas
    love.graphics.draw(uiCanvas, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, 0, scale, scale, gameCanvas:getWidth() / 2, gameCanvas:getHeight() / 2)

    --
end
