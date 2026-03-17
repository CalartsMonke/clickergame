local fn = function(self, dt)
    local flower = self.flower
    self.timer = self.timer - dt

    if self.timer <= 0 then
        self.targetx = self.targetx * -1
        self.timer = 1
        flux.to(self.position, 3, {x = self.originPos.x + self.targetx}):ease("sineinout")
    end

    if self.state == 1 then
        self.alpha = 0
        if flower.count >= 30 then
            self.state = 2
        end
    end

    if self.state == 2 then
        self.alpha = self.alpha + 0.3 * dt
        self.disappeartimer = self.disappeartimer + dt

        if self.disappeartimer >= 10 then
            self.state = 3
            self.alpha = 1
        end
    end

    if self.state == 3 then
        self.alpha = self.alpha - 0.3 * dt
    end




end

return fn