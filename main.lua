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
Engine._signals = {}
Engine._currentScene = nil

function setCamera(cam)
    Engine._currentCamera = cam
end




--OBJECT GROUPS CAUSE I LOVE GODOT
local _objectgroups = {}
local _destroyQueue = {}


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
assets.images.weirdWorm = love.graphics.newImage("img/weirdWorm.png")

assets.images.partGrow = love.graphics.newImage("img/partGrow.png")


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

assets.particles = {}
assets.particles.growpart = require 'particles.growpart'
assets.particles.levelstars = require 'particles.levelstars'

assets.sounds = {}
assets.sounds.twinkle = love.audio.newSource("sounds/twinkle.wav", 'static')
assets.sounds.twinkle2 = love.audio.newSource("sounds/twinkle2.wav", 'static')
assets.sounds.penscratch = love.audio.newSource("sounds/penscratch.mp3", 'static')

assets.music = {}
assets.music.daytheme = love.audio.newSource("music/p2yukino.mp3", 'stream')



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

local function sortByCreatedAt(a, b)
    return a.createdAt > b.createdAt
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

    table.insert(Engine._signals, self)

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
    self._signals = {}
    self._components = {}
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

--Make sure name is a string
function Object:addSignal(name)
    self._signals[name] = Signal()
end

--Make sure name is a string
function Object:getSignal(name)
    if self._signals[name] then
        return self._signals[name]
    else
        error("That signal name does not exists")
    end
end

function Object:addComponent(object, name)
    self._components[name] = object
end

function Object:getComponent(name)
    if self._components[name] then
        return self._components[name]
    else
        error("That component name does not exists")
    end
end

function Object:emitEvent(eventname, ...)
    --self._eventbus:publish(eventname, ...)
end

function Object:setScript(script)
    --self.update = script

    for function_name, funct in pairs(script) do
        self[function_name] = script[function_name]
    end
end

--FOR NOW PARENTS CANNOT HAVE GRANDCHILDREN UNTILL I LEARN POSITIONS LOL, THINK OF THIS ENGINE LIKE ADDING PETALS TO A FLOWER BUD, AND ONLY THAT FLOWERBUD AND NOT OTHER PETALS
function Object:addChild(child)
    child.parent = self
    table.push(self.children, child)

    --Cache global pos
end

function Object.addObject(object)
    return addObject(object)
end

function Object:setDrawToGui(bool)
    self._guiDraw = bool
end

function Object:getDrawToGui()
    return self._guiDraw
end

function Object:queueDestroy()
    --Check if in queue already
    local foundItem = false
    for i, v in ipairs(_destroyQueue) do
        if v == self then
            foundItem = true
        end
    end
    if foundItem == false then
        table.insert(_destroyQueue, self)
    else
        print("ITEM IS ALREADY IN QUEUE")
    end
end

function Object:_destroyObject()
    --Remove from entities list
    local queueobjectremoval = {}
    for i, v in ipairs(entities) do
        if v == self then
            table.insert(queueobjectremoval, table.remove(entities, i))
        end
    end
    --Remove any signals
    if self._signals then
        for i, signal in ipairs(self._signals) do
            table.insert(queueobjectremoval, signal)
        end
    end

    --Remove any components
    if self._components then
        for i, component in ipairs(self._components) do
            table.insert(queueobjectremoval, component)
        end
    end

    --Remove from any groups
    for stringname, actualstring in pairs(_objectgroups) do
        for i, v in ipairs(_objectgroups[stringname]) do
            if v == self then
                table.remove(_objectgroups, i)
            end
        end
    end
    --Final remove
    for i, v in ipairs(queueobjectremoval) do
        if v.destroy then
            v:destroy()
        end
        table.clear(v)
    end
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

function Entity:setX(x)
    self.position.x = x
end

function Entity:setY(y)
    self.position.y = y
end

function Entity:setScaleX(x)
    self.scale.x = x
end

function Entity:setScaleY(y)
    self.scale.y = y
end

function Entity:setRotation(r)
    self.roation = r
end

function Entity:setZDepth(z)
    self.zIndex = z
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

    self.originX = 0
    self.originY = 0
    self.shearX = 0
    self.shearY = 0
end

function Sprite:setTexture(texture)
    self.texture = texture
end

function Sprite:getTexture()
    return self.texture
end

function Sprite:setOriginX(x)
    self.originX = x
end

function Sprite:setOriginY(y)
    self.originY = y
end

function Sprite:setShearX(x)
    self.shearX = x
end

function Sprite:setShearY(y)
    self.shearY = y
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
        posx + self.originX, --Position X
        posy + self.originY, --Position Y
        self.rotation, --Rotation
        self.scale.x, --Scale X
        self.scale.y, --Scale Y
        self.originX,
        self.originY,
        self.shearX,
        self.shearY
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
Color.Yellow = Color(1, 1, 0)
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

function Label:setColor(Color)
    self.color = Color
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

    self:addSignal("Pressed")
    self:addSignal("Hovered")

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
                self:getSignal("Hovered"):emit()
                self._postHover = true
            end

            if input:pressed('ui_clickLeft') then
                self:getSignal("Pressed"):emit()
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

function SourcePlayer:new(source, vol, loops)
    self.source = source or nil
    self.vol = vol or 1.0
    local loops = loops or false
    if loops == true then
        if self.source then
            self.source:setLooping(loops)
        end
    end
end

function SourcePlayer:play()
    self.source:stop()
    self.source:play()
end

function SourcePlayer:setPitch(num)
    self.source:setPitch(num)
end

function  SourcePlayer:setLooping(bool)
    self.source:setLooping(bool)
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


local Particles = class({
    name = "Particles",
    extends = Entity
})

function Particles:new(particles, x, y)
    self:super(x, y)
    self.particles = particles
    self.system = particles[1].system



    self.emitting = true
    self.particleRate = 32
    self.emitOnce = false
    self._emitted = false
end

function Particles:update(dt)
    self.system:update(dt)
end

function Particles:setSpeed(num)
    self.system:setSpeed(num)
end

function Particles:emit(num)
    self.system:emit(num or 16)
end

function Particles:setEmissionRate(num)
    self.system:setEmissionRate(num)
end

function Particles:draw()
    love.graphics.draw(self.system, self.position.x, self.position.y)
end

function Particles:getsystem()
    return self.system
end

function Particles:destroy()
    self.system:release()
end

-------------------------------------------------------------
--GAME SPECIAL CLASSES---------------------------------------
-------------------------------------------------------------

--Class BuildingFlower
local BuildingFlower = class({
    name = "BuildingFlower",
    extends = Entity
})

function BuildingFlower:new(x, y)
    self:super(x, y)
    self.cps = 0.2
    self.count = 0
    self.itemId = 1
    self.price = 0
    self.basePrice = 10
    self.clickXpBuyValue = 0

    self.bigFlower = nil
    self.characterEventManager = nil



     --Needs buttons for buying and selling buildings
    addObject(Sprite(assets.images.itemframe, self.position.x, self.position.y))
    local sprite = Sprite(assets.images.yellowflower, self.position.x, self.position.y)
    --sprite:setShearX(1.1)
    sprite:setOriginX(32)
    sprite:setOriginY(32)
    self.sprite = sprite
    addObject(sprite)
end

function BuildingFlower:ready()
    self.bigFlower = getFirstObjectFromGroup("bigflower")
    self.characterEventManager = getFirstObjectFromGroup("charactereventmanager")

    local buyButton = TextureButton(assets.images.buyButtonNormal, self.position.x - 20, self.position.y + 50)
    buyButton:setTextureHover(assets.images.buyButtonHover)
    buyButton:setTexturePressed(assets.images.buyButtonPressed)
    buyButton:getSignal("Pressed"):connect(self.buyItem, self)
    self.buyButton = buyButton
    addObject(buyButton)
    local sellButton = TextureButton(assets.images.sellButtonNormal, self.position.x + 30, self.position.y + 50)
    sellButton:getSignal("Pressed"):connect(self.sellItem, self)
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

function BuildingFlower:destroy()
    self.buyButton:queueDestroy()
    self.sellButton:queueDestroy()
    self.priceLabel:queueDestroy()
    self.sprite:queueDestroy()
end

function BuildingFlower:buyItem()
    if self.bigFlower then
        if self.bigFlower.count >= self.price then
            self.bigFlower.count = self.bigFlower.count - self.price
            self.count = self.count + 1
            self.bigFlower.clickXp = self.bigFlower.clickXp + self.clickXpBuyValue
            self.sprite.shearX = 0.2
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
    self.clickXpBuyValue = self.price * 0.2
    local pricestring = tostring(self.price)
    pricestring = pricestring:sub(1, 6)
    self.priceLabel:setText(pricestring)

    --update sprite shear
    flux.to(self.sprite, 0.1, {shearX = 0})


    if not self.characterEventManager.isInEvent then
        self.bigFlower.count = self.bigFlower.count + (self.cps * self.count )* dt
        self.bigFlower.tempCps = self.bigFlower.tempCps + (self.cps * self.count)
    end
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

    self.clickLevel = 1
    self.clickPower = 1
    self.clickXp = 0
    self.clickXpNextLevel = 100

    local xplabel = addObject(Label("0", 10, 300))
    self.xpLabel = xplabel
    xplabel:setFont(assets.fonts.it32)
    xplabel:setDrawToGui(true)

    local nextXplabel = addObject(Label("50", 10, 330))
    nextXplabel:setFont(assets.fonts.it32)
    nextXplabel:setDrawToGui(true)
    self.nextXpLabel = nextXplabel

    local levelLabel = addObject(Label("1", 10, 40))
    levelLabel:setDrawToGui(true)
    levelLabel:setFont(assets.fonts.it32)
    self.levelLabel = levelLabel

    local cpsLabel = addObject(Label("0", 10, 20))
    cpsLabel:setDrawToGui(true)
    cpsLabel:setFont(assets.fonts.it32)
    self.cpsLabel = cpsLabel

    local stem = Sprite(assets.images.stem, 0, 50)
    self.stemSprite = stem
    self:addChild(stem)

    local levelUpLabel = addObject(Label("LEVEL UP!", 0, -10))
    levelUpLabel:setFont(assets.fonts.it32)
    levelUpLabel:setScript(require 'scripts.leveluplabel')
    levelUpLabel.color1 = Color(Color.White)
    levelUpLabel.color2 = Color(Color.Yellow)
    levelUpLabel:setDrawToGui(true)
    self.levelUpLabel = levelUpLabel

    local flowerhead = Sprite(assets.images.flowerhead, 10, 10)
    self.flowerheadSprite = flowerhead
    self.flowerheadSprite:setOriginX(64)
    flowerhead:setOriginY(64)
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

    self.particles = Particles(assets.particles.growpart, self.position.x + 100, self.position.y + 100)
    self.particles:setEmissionRate(0)
    addObject(self.particles)

    local levelparticles = Particles(assets.particles.levelstars, self.position.x + 100, self.position.y + 100)
    addObject(levelparticles)
    levelparticles:setEmissionRate(0)
    self.levelParticles = levelparticles

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


    self.levelSound = SourcePlayer(assets.sounds.twinkle2)

    self.count = 1
    self.tempCps = 0
    self.prevTempcps = 0

    self.characterEventManager = nil
end

function BigFlower:ready()
    self.characterEventManager = getFirstObjectFromGroup("charactereventmanager")

    self.clickStreakNum = 0
    self.clickStreakResetTimer = 0
end

function BigFlower:update(dt)

    self.prevTempcps = self.tempCps

    self.clickStreakResetTimer = self.clickStreakResetTimer - dt
    if self.clickStreakResetTimer < 0 then 
        self.clickStreakNum = 0
    end

    if not self.characterEventManager.isInEvent then
        flux.to(self.flowerheadSprite.scale, 0.1, {x = 1, y = 1})
        if input:pressed('clickLeft') then
            self.count = self.count + self.clickPower

            self.clickStreakNum = self.clickStreakNum + 1


            self.flowerheadSprite.scale.x = 1.2
            self.flowerheadSprite.scale.y = 1.2
            self.clickStreakResetTimer = 0.5

            self.clickXp = self.clickXp + self.clickPower * 0.1

            if self.clickStreakNum > 30 then
        
            end
        end

        local emissionRate = self.tempCps - 100
        if emissionRate < 0 then
            emissionRate = 0
        end

        self.clickXp = self.clickXp + (self.tempCps * 0.05) * dt

        if self.clickXp >= self.clickXpNextLevel then
            self:levelUp()
        end

        self.xpLabel:setText(math.floor(self.clickXp))
        self.nextXpLabel:setText(math.floor(self.clickXpNextLevel))

        local clickPowerFormated = tostring(self.clickPower):sub(1, 4)

        self.levelLabel:setText(clickPowerFormated.."("..self.clickLevel..")")
        self.cpsLabel:setText(self.tempCps)

        self.particles:getsystem():setEmissionRate(emissionRate)



        self.tempCps = 0

        self.countText:setText(math.floor(self.count))
    else
        self.countText:setText("")
    end
end

function BigFlower:levelUp()
    self.clickXp = 0
    self.clickLevel = self.clickLevel + 1
    self.clickXpNextLevel = 100 * (1.4^self.clickLevel)
    self.clickPower = 1 + self.clickPower + self.clickPower * 0.1
    self.levelParticles.position.x = worldMouseX
    self.levelParticles.position.y = worldMouseY
    self.levelParticles:emit(8)
    self.levelSound:play()
    
    self.levelUpLabel.superTimer = 3
    self.levelUpLabel.position.x = screenMouseX
    self.levelUpLabel.position.y = screenMouseY

end

--Class GameCamera
local GameCamera = class({
    name = "GameCamera",
    extends = Camera
})

function GameCamera:new(x, y)
    self:super(x, y)
    self.camTargetX = self.position.x or 0
    self.camTargetY = self.position.y or 0
    self.targetArea = 1 --menu will be the downwards one
end

function GameCamera:update(dt)
    --self.position.y = self.camTargetY
    self.targetArea = self.cameraman.state

    if self.targetArea == self.cameraman.states.main then
        self.camTargetY = 0
        self.camTargetX = 0
    elseif self.targetArea == self.cameraman.states.flowermenu then
        self.camTargetY = 200
        self.camTargetX = 0
    elseif self.targetArea == self.cameraman.states.characterevent then
        self.camTargetX = 640
        self.camTargetY = 0
    end

    flux.to(self.position, 0.2, {x = self.camTargetX})
    flux.to(self.position, 0.2, {y = self.camTargetY})
end

--Class DialougeBox
local DialougeBox = class({
    name = "DialougeBox",
    extends = Entity
})

local function sayHi()
    print("I LOVE YOU MISTER")
end

function DialougeBox:new(x, y)

    self.testString = "This will be fun, I really hope so"


    self.targetY = 0

    self.active = false

    self.functionsTable = {
        sayHi
    }

    self:super(x, y)
    self.textStrings = {}
    self._textLetters = {}
    self.textStringIndex = 1

    self.charactersShowing = 1
    self.previouscharactersShowing = self.charactersShowing
    self:addSignal("TextSkip")
    self:addSignal("TextboxEnd")
    self:addSignal("TextboxStart")


    self.truetextShown = ""

    self.textWriteDelay = 0.1
    self.textSoundDelay = 0.2

    self.cameraman = nil

    self.boxSprite = nil
    self.border = addObject(ColorShape(RectShape(640, 120), self.position.x + 0, self.position.y + 250, Color(0.3, 0.3, 0.3), 1))
    self.border.offX, self.border.offY = self.border.position.x, self.border.position.y
    self.box = addObject(ColorShape(RectShape(460, 100), self.position.x + 80, self.position.y + 250, Color(Color.Black), 1))
    self.box.offX, self.box.offY = self.box.position.x, self.box.position.y
    self.nameTag = addObject(Label("Bunny:", self.position.x + 90, self.position.y + 250))
    self.nameTag.offX, self.nameTag.offY = self.nameTag.position.x, self.nameTag.position.y
    self.nameTag:setFont(assets.fonts.sl32)
    self.text = addObject(Label("This will be fun, I really hope so.", self.position.x + 90, self.position.y + 250 + 32))
    self.text.offX, self.text.offY = self.text.position.x, self.text.position.y
    self.text:setWrapLimit(450)
    self.text:setFont(assets.fonts.sl32)
    self.talkSound1 = SourcePlayer(assets.sounds.penscratch, 0.5, false)


    self._textSkip = false
    self._parsedFunctions = {}
    self._currentIndexedRealString = nil
    self._letterFont = assets.fonts.sl32
    self._fontWidth = 16
    self._fontHeight = 32
    self._letterX = 0
    self._letterY = 0
    self._letterIndex = 1
end

function DialougeBox:_performFunction(arg)
    arg = tonumber(arg)
    local fn = self.functionsTable[arg or 1]
    fn()
end

function DialougeBox:_parseString(string)
    local realstring = ""
    local parsingCommand = false
    local parsingArg = false
    local commandString = ""
    local functionString = ""
    local argString = ""
    local subtractedPos = 0

    local command = {fn = nil, arg = nil, pos = nil}
    for i=1, string:len() do
        local letter = string:sub(i, i)
        
        --Begin command memory mode
        if letter == "[" then
            parsingArg = false
            parsingCommand = true
            command.pos = i - subtractedPos - 1
        end

        --end command memory mode
        if letter == ']' then
            parsingCommand = false
            parsingArg = false
            command.fn = functionString
            command.arg = argString
            
            table.insert(self._parsedFunctions, command)

            --reset command string
            functionString = ""
            argString = ""
        end

        if parsingCommand then

            if (letter ~= "[" and letter ~= "]" and letter ~= ":") and parsingArg == false then
                functionString = functionString..letter
            end

            if (letter ~= "[" and letter ~= "]" and letter ~= ":") and parsingArg == true then
                argString = argString..letter
            end

            subtractedPos = subtractedPos + 1

            if letter == ":" then
                parsingArg = true
            end
        else
            if letter ~= "]" then
                realstring = realstring..letter
            end
        end
    end

    return realstring
end

function DialougeBox:spawnLetter(x, y, index)
    local string = self._currentIndexedRealString
    if string == nil and self.textStrings[self.textStringIndex] ~= nil then
        string = self:_parseString(self.textStrings[self.textStringIndex])
        print(string)
        self._currentIndexedRealString = string
    end


    local letter = string:sub(index, index)
    local doNotAddLetter = false


    for i, v in ipairs(self._parsedFunctions) do
        if index == v.pos then
            self:_performFunction(v.arg)
        end
    end

    if doNotAddLetter == false then
        self.textWriteDelay = 0.02

        if letter ~= "" then
            local label = Label(letter, x, y+10)
            self:getSignal("TextSkip"):connect(label.queueDestroy, label)
            self:getSignal("TextSkip"):connect(label.setAlpha, label)
            label.lettersTable = self._textLetters
            table.insert(self._textLetters, label)
            label.targetPositionY = y
            label.targetPositionX = x
            label.offX, label.offY = x, y
            label:setScript(require 'scripts.letterSlideUp')
            label:setText(letter)
            label:setFont(self.text:getFont())
            addObject(label)
        end

        local fontoffy = self._letterFont:getHeight(letter)
        local fontoffx = self._letterFont:getWidth(letter)

        if letter == "\n" then
            self._letterX = 0
            self._letterY = self._letterY + fontoffy
        end

        if letter == "." then
            self.textWriteDelay = 0.1
        end

        if letter ~= '.' and letter ~= '/n' and letter ~= '' then
            if self.textSoundDelay <= 0 then
                if true then
                    local sound = love.audio.newSource('sounds/penscratch.mp3', 'static')
                    sound:setVolume(0.3)
                    sound:setPitch(0.4 + love.math.random(100)/100)
                    sound:play()


                    --self.textSoundDelay = 0.1
                    --self.talkSound1:setPitch()
                    --self.talkSound1:play()
                end
            end
        end

        self._letterX = self._letterX + fontoffx
        self._letterIndex = self._letterIndex + 1
    end
end

function DialougeBox:ready()
    if self.cameraman == nil then
        self.cameraman = getFirstObjectFromGroup("cameraman")
    end
    --self.cameraman.state = self.cameraman.states.characterevent
end

function DialougeBox:update(dt)

    flux.to(self.position, 0.2, {y = self.targetY})

    if self.active == true then
        self.previousCharactersShowing = self.charactersShowing

        if self.textStrings[self.textStringIndex] ~= nil then
            self.textWriteDelay = self.textWriteDelay - dt
            self.textSoundDelay = self.textSoundDelay - dt

            if self._textSkip ~= true then
                if self.textWriteDelay <= 0 and math.abs(self.targetY - self.position.y) < 0.2  then

                    self.charactersShowing = self.charactersShowing + 1
                    self:spawnLetter(self.text.position.x + (self._letterX), self.text.position.y + self._letterY, self._letterIndex)
                end
            else
                if true then
                    while #self._textLetters < self._currentIndexedRealString:len() do

                        self.charactersShowing = self.charactersShowing + 1
                        self:spawnLetter(self.text.position.x + (self._letterX), self.text.position.y + self._letterY, self._letterIndex)

                        if self.charactersShowing >= self._currentIndexedRealString:len() then
                            self._textSkip = false
                            print("BROKE")
                            break;
                        end
                    end
                end
            end
        end

        if self.textStrings[self.textStringIndex] == nil then
            self:endTextbox()
        end

            --Controls
        if input:pressed("clickLeft") then
            if self.textStrings[self.textStringIndex + 1] ~= nil and self._currentIndexedRealString ~= nil then
                if #self._textLetters >= self._currentIndexedRealString:len() then
                    self:advanceText()
                end
            else
                if self._currentIndexedRealString then
                   if #self._textLetters >= self._currentIndexedRealString:len() then
                        self:endTextbox() 
                    end
                end
            end


            if self._currentIndexedRealString and self.charactersShowing > 2 then
                if #self._textLetters < self._currentIndexedRealString:len() then
                    self._textSkip = true
                    print("IS SKIPPING TEXT NOW")
                end
            end
        end
    end

    self:updateParts()
    --self.text:setText(self.truetextShown)
    self.text:setVisibleCharacterLimit(math.floor(0))
end

function DialougeBox:endTextbox()
    print("SOMETHING AWESOME")
    self:_cleanlettertable()
    self:getSignal("TextboxEnd"):emit()
    self.targetY = 360
    self.active = false
end

function DialougeBox:setNameTag(text)
    self.nameTag:setText(tostring(text))
end

function DialougeBox:startTextBox(table)
    self:reset()
    self:getSignal("TextboxStart"):emit()
    self.targetY = 0

    if table then
        for i=1, #table do
            self.textStrings[i] = tostring(table[i])
        end
    end
    self.active = true
end

function DialougeBox:updateParts()
    self.border.position.x, self.border.position.y = self.position.x + self.border.offX, self.position.y + self.border.offY
    self.box.position.x, self.box.position.y = self.position.x + self.box.offX, self.position.y + self.box.offY
    self.nameTag.position.x, self.nameTag.position.y = self.position.x + self.nameTag.offX, self.position.y + self.nameTag.offY
    self.text.position.x, self.text.position.y = self.position.x + self.text.offX, self.position.y + self.text.offY

    for i=1, #self._textLetters do
        local letter = self._textLetters[i]
        if letter ~= nil then
            --letter.position.x, letter.position.y = self.position.x + letter.offX, self.position.y + letter.offY
        end
    end
end

function DialougeBox:skipTextToEnd()
    self.truetextShown = self.textStrings[self.textStringIndex]
    self.charactersShowing = 1
    self._letterX = 0
    self._letterY = 0
    self._letterIndex = 0
    self:getSignal("TextSkip"):emit(0)
end

function DialougeBox:advanceText()
    if self.textStrings[self.textStringIndex + 1] ~= nil then
        self._currentIndexedRealString = self.textStrings[self.textStringIndex + 1] --reset
        self:_parseString(self._currentIndexedRealString)
        self.charactersShowing = 1
        self.textStringIndex = self.textStringIndex + 1
        self._letterX = 0
        self._letterY = 0
        self._letterIndex = 0
        self.truetextShown = ""
        self._textSkip = false
    end

    self:_cleanlettertable()
end

function DialougeBox:_cleanlettertable()
    for i = 1, #self._textLetters do
        local letter = self._textLetters[i]
        letter:queueDestroy()
    end
        table.clear(self._textLetters)
end

function DialougeBox:setIndexedText(string, index)
    local i = index or 1
    self.textStrings[i] = tostring(string)
end

function DialougeBox:reset()
    table.clear(self.textStrings)
    self._currentIndexedRealString = nil --reset
    self.charactersShowing = 1
    self.textStringIndex = 1
    self._letterX = 0
    self._letterY = 0
    self._letterIndex = 0
    self.truetextShown = ""
    self._textSkip = false
end

--Class CharacterPortrait
local CharacterPortrait = class({
    name = "CharacterPortrait",
    extends = Entity
})

function CharacterPortrait:new()
    self:super(0, 0)
end 

--Class CharacterEvent
local CharacterEventManager = class({
    name = "CharacterEventManager",
    extends = Object
})

function CharacterEventManager:new()
    self:super()
    self:addSignal("NewEvent")
    addObjectToGroup("charactereventmanager", self)
    self.cameraman = nil
    self.bigflower = nil
    self.characters = {}
    self.dialougebox = addObject(DialougeBox(320, 0)) --Spawn a dialouge box on the right side of the screen
    self.dialougebox:getSignal("TextboxStart")
    self.dialougebox:getSignal("TextboxEnd"):connect(self.textboxend, self)
    self.dialougebox.eventmanager = self

    self.textbox = self.dialougebox
    self.isInEvent = false

    self.characterEventFlags = {
        goal1 = false,
        goal2 = false,
        goal3 = false
    }
end

function CharacterEventManager:ready()
    if self.cameraman == nil then
        self.cameraman = getFirstObjectFromGroup("cameraman")
    end
    if self.bigflower == nil then
        self.bigflower = getFirstObjectFromGroup("bigflower")
    end
end

function CharacterEventManager:update(dt)
    local count = self.bigflower.count

    if count >= 10 and self.characterEventFlags.goal1 == false then
        self.isInEvent = true
        self.cameraman.state = 3
        self.characterEventFlags.goal1 = true
        self.textbox:startTextBox(
            {
                "Hello how are you doing?",
                "I hope its a fine and lovely \nevening.",
                "...We gotta keep growing the \ngarden.",
                "Make it big and strong before \nnightfall.",
                "Why is that you ask?",
                "Hehe Uh... Ill tell you later.",
                "Just keep going for a while."
            }
        )
    end

    if count >= 20 and self.characterEventFlags.goal2 == false then
        self.isInEvent = true
        self.cameraman.state = 3
        self.characterEventFlags.goal2 = true
        self.textbox:startTextBox(
            {
                    "Hey you seem to be doing well",
                    "Don't forget to click any worms\n you see",
                    "You probably already knew that..."
            }
        )
    end

    if count >= 30 and self.characterEventFlags.goal3 == false then
        self.isInEvent = true
        self.cameraman.state = 3
        self.characterEventFlags.goal3 = true
        self.textbox:startTextBox(
            {
                "Hey...",
                "It's going to come soon.",
                "You know that right?",
                "The 'thing' at night or...",
                "The 'things' that come out at night.",
                "Just be on the lookout ok?"
            }
        )
    end
end

function CharacterEventManager:textboxend()
    if self.cameraman then
        self.cameraman.state = 1
    end
    self.isInEvent = false
    print("Ended")
end

--Events need to have .texts, .characters, and a .functions table
function CharacterEventManager:newEvent(event)
    self.characters = event.characters
    self.texts = event.texts
    self.functions = event.functions
end

--Class MusicPlayer
local MusicPlayer = class({
    name = "MusicPlayer",
    extends = Object
})

function MusicPlayer:new()
    self.currentSong = nil
end

--Make sure item is a SourcePlayer
function MusicPlayer:play(item)
    if self.currentSong then
        if self.currentSong:isPlaying() then
            self.currentSong:stop()
        end
    end

    self.currentSong = item

    self.currentSong:play()
end

function MusicPlayer:setLooping(bool)
    self.currentSong:setLooping(bool)
end

local CameraStateManager = class({
    name = "CameraStateManager",
    extends = Object
})

function CameraStateManager:new()
    addObjectToGroup("cameraman", self)
    self.states = {
        main = 1,
        flowermenu = 2,
        characterevent = 3,
    }
    self.state = self.states.main
end

local WeirdWorm = class({
    name = "WeirdWorm",
    extends = Entity
})

function WeirdWorm:new(x, y)
    self:super(x, y)
    self.width = 64
    self.height = 64

    self.bigflower = nil
    self.sprite = Sprite(assets.images.weirdWorm, x, y)
    addObject(self.sprite)
    self.countToGive = 0

    self.clickSound = SourcePlayer(assets.sounds.twinkle)
end

function WeirdWorm:destroy()
    self.tableSlot.worm = nil

    self.sprite:queueDestroy()
    self.clickSound:queueDestroy()
end

function WeirdWorm:ready()
    self.bigflower = getFirstObjectFromGroup("bigflower")
end

function WeirdWorm:update(dt)
    if PointAABB(worldMouseX, worldMouseY, self.position.x, self.position.y, self.width, self.height) then
        if input:pressed("clickLeft") then
            self:queueDestroy()
            self.bigflower.count = self.bigflower.count + (self.bigflower.prevTempcps) * 60
            self.bigflower.clickXp = self.bigflower.clickXp + (self.bigflower.prevTempcps) * 20
            self.clickSound:play()
        end
    end
end

local Scene = class({
    name = "Scene",
    extends = Object
})

function Scene:new()

end

function Scene:enter()

end

function Scene:update()

end

function Scene:leave()

end

function Scene:draw()

end
--------------------------------------------------------

local Game = Object()
Game.worms = {}
Game.WeirdWorm = WeirdWorm
Game.worms[1] = {x = 50, y = 200, worm = nil}
Game.worms[2] = {x = 150, y = 240, worm = nil}
Game.worms[3] = {x = 340, y = 210, worm = nil}
Game.worms[4] = {x = 420, y = 260, worm = nil}
Game.worms[5] = {x = 500, y = 200, worm = nil}
Game:setScript(require 'scripts.game')

table.insert(entities, Game)

local gamebg = ColorShape(RectShape(6000, 6000), 0, 0, Color(0.2, 0.1, 0.8))
addObject(gamebg)

local grassbg = addObject(Sprite(assets.images.grassbg))

--GAME

local charactereventmanager = CharacterEventManager()
addObject(charactereventmanager)


local bigFlower = BigFlower(200, 150)
bigFlower.position.x = 200
bigFlower.position.y = 150
addObject(bigFlower)

local countHintText1 = Label("<-- get this to 100000", 60, 0)
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
local cameramanager = CameraStateManager()
local camera = GameCamera(0, 0)
camera.cameraman = cameramanager
addObject(camera)
setCamera(camera)

local musicplayer = MusicPlayer()
local musday = SourcePlayer(assets.music.daytheme, 1, true)
musicplayer:play(musday)
--addObject(musicplayer)



local buildingShop = Entity(0, 360)
buildingShop.cameraman = cameramanager
buildingShop.toggleMenu = function(self)
    if self.isShowingMenu == true then
        self.isShowingMenu = false
        self.cameraman.state = self.cameraman.states.main
    elseif self.isShowingMenu == false then
        self.isShowingMenu = true
        self.cameraman.state = self.cameraman.states.flowermenu
    end
end

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
buildingShop.isShowingMenu = false
buildingShop.menuButton:getSignal("Hovered"):connect(buildingShop.toggleMenu, buildingShop)

--local bunny = addObject(Sprite(assets.images.pinkbunny, 0, 0))





--GAME UPDATE LOOPS
function love.update(dt)
    --preresqs
    flux.update(dt)
    input:update()
    updateScale()

    --table.sort(entities, sortByCreatedAt)

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

    --Destroy Objects at the end of update
    for i, v in ipairs(_destroyQueue) do
        v:_destroyObject()
    end
    table.clear(_destroyQueue)
end

function love.draw()
    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear()

    --Camera
    love.graphics.push()
    --love.graphics.setProjection(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1)
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

    --Draw gui canvas
    love.graphics.draw(uiCanvas, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, 0, scale, scale, gameCanvas:getWidth() / 2, gameCanvas:getHeight() / 2)

    --
end
