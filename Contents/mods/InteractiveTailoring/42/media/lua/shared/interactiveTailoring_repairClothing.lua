require "TimedActions/ISRepairClothing.lua"
local origRepairClothingComplete = ISRepairClothing.complete
function ISRepairClothing:complete()
    local result = origRepairClothingComplete(self)
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

local origRepairClothingUpdate = ISRepairClothing.update
function ISRepairClothing:update()
    origRepairClothingUpdate(self)
    local hole = self.clothing:getVisual():getHole(self.part) > 0 ---To fix bug in vanilla code: hole is not compared to 0/1.
    local jobType = hole and getText("ContextMenu_PatchHole") or getText("ContextMenu_AddPadding")
    ISGarmentUI.setBodyPartActionForPlayer(self.character, self.part, self, jobType, { })
end

local origRepairClothingStart = ISRepairClothing.start
function ISRepairClothing:start()
    origRepairClothingStart(self)
    self:setOverrideHandModels(self.needle, self.clothing)
end


require "TimedActions/ISRemovePatch.lua"
local origRemovePatchUpdate = ISRemovePatch.update
function ISRemovePatch:update()
    origRemovePatchUpdate(self)
    local hole = self.clothing:getVisual():getHole(self.part) > 0 ---There isn't even a distinction made in vanilla for this.
    local jobType = hole and getText("ContextMenu_PatchHole") or getText("ContextMenu_AddPadding")
    ISGarmentUI.setBodyPartActionForPlayer(self.character, self.part, self, jobType, { })
end


local origRemovePatchStart = ISRemovePatch.start
function ISRemovePatch:start()
    origRemovePatchStart(self)
    self:setOverrideHandModels(self.needle, self.clothing)
end

--self:setOverrideHandModels(secondItem, self.item)