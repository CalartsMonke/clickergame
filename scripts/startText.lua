
local func = function(self, dt)
    if self.globalPosition.y > 20 then
        self.position.y = self.position.y - dt * 20        
    end

    
    print(self.position.y)
    print(self.globalPosition.y)
    self.timer = self.timer - dt
    if self.timer <= 0 then
        self.alpha = self.alpha - dt        
    end

    print("AWESOME")
end


return func