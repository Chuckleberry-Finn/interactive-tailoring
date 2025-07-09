local orig = ISRepairClothing.complete

function ISRepairClothing:complete()
    local result = orig(self)
    if result then

        local itModData = self.clothing:getModData().interactiveTailoring
        local mdAreas = itModData and itModData.areas
        local part = self.part and mdAreas and mdAreas[self.part:index()]
        if part then part.sc = {r=self.thread:getR(),g=self.thread:getG(),b=self.thread:getB()} end

        if self.patchMatchesPart then
            addXp(self.character, Perks.Tailoring, self.patchMatchesPart)
        end
    end
    return result
end