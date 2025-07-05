local orig = ISRepairClothing.complete

function ISRepairClothing:complete()
    local result = orig(self)
    if result then
        if self.patchMatchesPart then
            addXp(self.character, Perks.Tailoring, self.patchMatchesPart)
        end
    end
    return result
end