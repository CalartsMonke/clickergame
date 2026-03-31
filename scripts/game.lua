local script = {}

function script.ready(self)
    self.timer = 30
    self.cpsFlag1 = true
end

function script.update(self, dt)
    if input:pressed('toggleWindowMode') then
        if love.window.getFullscreen() == false then
            love.window.setFullscreen(true, 'desktop')
        else
            love.window.setFullscreen(false)
        end
    end

    self.timer = self.timer - dt

    if self.timer <= 0 then
        self.timer = 20 + love.math.random(40)
        self:spawnWorm()
    end

end

function script.spawnWorm(self)
    local i = math.floor(love.math.random(1, #self.worms + 1))

    if i > #self.worms then
        i = #self.worms
    end
    print(i)
    while self.worms[i].worm ~= nil do
        i = math.floor(love.math.random(1, #self.worms + 1))

        if i > #self.worms then
            i = #self.worms
        end
        local breakLoop = true
        for d=1, #self.worms do
            if self.worms[d].worm == nil then
                i = d
                breakLoop = false
            end
        end

        if breakLoop == true then
            break
        end


    end



        local worm = self.addObject(self.WeirdWorm(self.worms[i].x, self.worms[i].y))
        worm.tableSlot = self.worms[i]
        self.worms[i].worm = worm
end


return script