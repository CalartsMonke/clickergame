local func = function(self, dt)
    local flower = self.flower
    if flower.count > 20 and self.alpha <= 1 then
        self.alpha = self.alpha + 0.5 * dt
    end
end

return func