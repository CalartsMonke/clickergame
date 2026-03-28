local script = {}

function script.update(self, dt)
    if self.position.y + self.parent.position.y > 20 then
        self.position.y = self.position.y - dt * 20        
    end

    self.timer = self.timer - dt
    if self.timer <= 0 then
        self.alpha = self.alpha - dt        
    end
end


return script