local script = {}
function script.update(self, dt)
    flux.to(self.position, 0.2, {y = self.targetPositionY})

    local pos = self.position
    if math.abs(pos.y - self.targetPositionY) <= 0.1 then
        --table.insert(self.lettersTable, self)
        --self.update = nil
    end
end


return script