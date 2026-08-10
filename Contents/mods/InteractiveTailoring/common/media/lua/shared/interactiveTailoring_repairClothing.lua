require "TimedActions/ISRepairClothing.lua"

---TODO: figure out why I included this at all, lol
--[[
local origRepairClothingPerform = ISRepairClothing.perform
function ISRepairClothing:perform()

    origRepairClothingPerform(self)

    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end
    self.character:resetModel()
    self.started = false
    ISGarmentUI.setBodyPartActionForPlayer(self.character, self.part, nil, nil, nil)
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
end
--]]

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
end --sendAddXp


--[[
local origRepairClothingUpdate = ISRepairClothing.update
function ISRepairClothing:update()
    origRepairClothingUpdate(self)
    local hole = self.clothing:getVisual():getHole(self.part) > 0 ---To fix bug in vanilla code: hole is not compared to 0/1.
    local jobType = hole and getText("ContextMenu_PatchHole") or getText("ContextMenu_AddPadding")
    ISGarmentUI.setBodyPartActionForPlayer(self.character, self.part, self, jobType, { })
end
--]] ---Vanilla bug fixed! :o


local origRepairClothingStart = ISRepairClothing.start
function ISRepairClothing:start()
    origRepairClothingStart(self)
    self:setOverrideHandModels(self.needle, self.clothing)
end


local origRepairClothingNew = ISRepairClothing.new
function ISRepairClothing:new(character, clothing, part, fabric, thread, needle, patchMatchesPart)
    local action = origRepairClothingNew(self, character, clothing, part, fabric, thread, needle)
    action.patchMatchesPart = patchMatchesPart
    return action
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