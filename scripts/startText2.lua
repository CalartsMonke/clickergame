
local func = function(self, dt)
    if self.globalPosition.y > 20 then
        self.position.y = self.position.y - dt * 20       
        self.alpha = 0
    end


    
    print(self.position.y)
    print(self.globalPosition.y)
    self.timer = self.timer - dt
    self.timer2 = self.timer2 - dt
    if self.timer <= 0 and self.timer2 > 0 then
        self.alpha = self.alpha + dt
        if self.alpha > 1 then
            self.alpha = 1
        end
    end

    if self.timer2 <= 0 then
        self.alpha = self.alpha - dt
    end

    print("AWESOME")
end


return func