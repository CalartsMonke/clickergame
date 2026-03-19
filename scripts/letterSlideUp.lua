local fn = function(self, dt)
    flux.to(self.position, 0.2, {y = self.targetPositionY})
    print("RUNNING")
end

return fn