local script = {}

function script.ready(self)
    self.timer = 0.05
    self.superTimer = 3
    self.colorSwitch = false
end

function script.update(self, dt)

    self.timer = self.timer - dt
    self.superTimer = self.superTimer - dt

    if self.timer <= 0 then
        self.timer = 0.1
        self.colorSwitch = not self.colorSwitch

        if self.colorSwitch == true then
            self:setColor(self.color1)
        else
            self:setColor(self.color2)
        end
    end

    self:setAlpha(self.superTimer)

    if self.superTimer > 0 then
        self.position.y = self.position.y - 30 * dt
    end
    
end

return script