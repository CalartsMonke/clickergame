--[[
module = {
	x=emitterPositionX, y=emitterPositionY,
	[1] = {
		system=particleSystem1,
		kickStartSteps=steps1, kickStartDt=dt1, emitAtStart=count1,
		blendMode=blendMode1, shader=shader1,
		texturePreset=preset1, texturePath=path1,
		shaderPath=path1, shaderFilename=filename1,
		x=emitterOffsetX, y=emitterOffsetY
	},
	[2] = {
		system=particleSystem2,
		...
	},
	...
}
]]
local LG        = love.graphics
local particles = {x=-27.400387770979, y=-6.2755726830306}

local image1 = LG.newImage("img/star.png")
image1:setFilter("nearest", "nearest")

local ps = LG.newParticleSystem(image1, 282)
ps:setColors(1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0.62109375, 1, 1, 1, 0)
ps:setDirection(-1.5707963705063)
ps:setEmissionArea("none", 0, 0, 0, false)
ps:setEmissionRate(81.658485412598)
ps:setEmitterLifetime(-1)
ps:setInsertMode("top")
ps:setLinearAcceleration(0.45932897925377, 0.051036551594734, 0, 0)
ps:setLinearDamping(0, 0)
ps:setOffset(8, 8)
ps:setParticleLifetime(0.2880911231041, 2.0122282505035)
ps:setRadialAcceleration(2.5518276691437, 0.91865795850754)
ps:setRelativeRotation(false)
ps:setRotation(0, 0)
ps:setSizes(1.0026106834412)
ps:setSizeVariation(0)
ps:setSpeed(66.327102661133, 91.641235351562)
ps:setSpin(0, 0)
ps:setSpinVariation(0)
ps:setSpread(6.2831854820251)
ps:setTangentialAcceleration(0, 0)
table.insert(particles, {system=ps, kickStartSteps=0, kickStartDt=0, emitAtStart=109, blendMode="add", shader=nil, texturePath="star.png", texturePreset="", shaderPath="", shaderFilename="", x=0, y=0})

return particles
