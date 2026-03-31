local script = {}

function script.update(self, dt)
    local flower = self.flower
    if flower.count > 20 and self.alpha <= 1 then
        self.alpha = self.alpha + 0.5 * dt
    end
end

return script