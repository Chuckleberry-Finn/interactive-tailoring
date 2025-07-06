require "ISUI/ISCollapsableWindow.lua"
require "ISUI/ISGarmentUI.lua"

local pieceHandler = require "interactiveTailoring_pieceHandler.lua"
local generatedColors = require "interactiveTailoring_generatedItemColor.lua"

interactiveTailoringUI = ISCollapsableWindow:derive("interactiveTailoringUI")
interactiveTailoringUI.fontHgt = getTextManager():getFontHeight(UIFont.NewMedium)
interactiveTailoringUI.fontSmallHgt = getTextManager():getFontHeight(UIFont.NewSmall)
interactiveTailoringUI.fabricTexture = getTexture("media/textures/fabric.png")
interactiveTailoringUI.holeTexture = getTexture("media/textures/hole.png")

interactiveTailoringUI.brokenItemIcon = getTexture("media/ui/icon_broken.png")

interactiveTailoringUI.threadFont = UIFont.NewLarge
interactiveTailoringUI.threadFontHeight = getTextManager():getFontHeight(interactiveTailoringUI.threadFont)

interactiveTailoringUI.failThread = getScriptManager():getItem("Thread"):getNormalTexture()
interactiveTailoringUI.failNeedle = getScriptManager():getItem("Needle"):getNormalTexture()
interactiveTailoringUI.failScissors = getScriptManager():getItem("Scissors"):getNormalTexture()
interactiveTailoringUI.failColor = {a=0.5,r=1,g=0.1,b=0.1}

--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=
--TODO: Go over all the cannibalized parts from GarmentUI and refactor/optimize--
--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=

interactiveTailoringUI.ghs = "<GHC>"
interactiveTailoringUI.bhs = "<BHC>"


--TODO: One system looks for numbers the other for strings, doublecheck if this can't be merged
interactiveTailoringUI.patchColorIndex = {["Cotton"]=1,["Denim"]=2,["Leather"]=3}
interactiveTailoringUI.patchColor = {
    { r = 0.855, g = 0.843, b = 0.749 },--cotton
    { r = 0.396, g = 0.522, b = 0.639 },--denim
    { r = 0.584, g = 0.369, b = 0.204 },--leather
}


function interactiveTailoringUI:repairClothing(part, fabric)
    if not fabric or not self.clothing or not self.thread or not self.needle then return end

    local things = {fabric, self.thread, self.needle, self.clothing}

    for _,thing in pairs(things) do
        if luautils.haveToBeTransfered(self.player, thing) then
            ISTimedActionQueue.add(ISInventoryTransferAction:new(self.player, thing, thing:getContainer(), self.player:getInventory()))
            ISGarmentUI.setBodyPartForLastAction(self.player, part)
        end
    end

    local action = ISRepairClothing:new(self.player, self.clothing, part, fabric, self.thread, self.needle)
    local xp = self:patchMatchesPart(fabric, part) and 12 or 6
    action.patchMatchesPart = xp
    ISTimedActionQueue.add(action)
end


function interactiveTailoringUI:update()
    ISCollapsableWindow.update(self)
    if not self.clothing or not self.clothing:isInPlayerInventory() then self:close() end
end


--TODO: Might be possible to refactor and merge show/hide better
function interactiveTailoringUI:showTooltip(toolTip)
    if self.toolTip and (self.toolTip ~= toolTip) then self:hideToolTip() end
    if not self.toolTip and toolTip then
        self.toolTip = toolTip
        self.toolTip:setVisible(true)
        self.toolTip:addToUIManager()
        self.toolTip.followMouse = not self.joyfocus
    end
end


function interactiveTailoringUI:hideToolTip()
    if self.toolTip ~= nil then
        self.toolTip:removeFromUIManager()
        self.toolTip:setVisible(false)
        self.toolTip = nil
    end
end


function interactiveTailoringUI:onBodyPartListRightMouseUp(x, y)
    local row = self:rowAt(x, y)
    if row < 1 or row > #self.items then return end
    self.parent:doContextMenu(self.items[row].item, getMouseX(), getMouseY())
end


--TODO: Couldn't this be achievable by taking coveredparts size and subtracting the hole count + the 3 patch counts?
--- Or coveredparts iterated - if patch?
function interactiveTailoringUI:getPaddablePartsNumber(clothing, parts)
    local count = 0
    for i=1, #parts do
        local part = parts[i]
        local hole = clothing:getVisual():getHole(part) > 0
        local patch = clothing:getPatchType(part)
        if(hole == false and patch == nil) then count = count + 1 end
    end
    return count
end


function interactiveTailoringUI:patchMatchesPart(fabric, part)
    local partID = tostring(part)
    local md = self.clothing:getModData()
    local mdHole = md.interactiveTailoring and md.interactiveTailoring.holes and md.interactiveTailoring.holes[partID]
    local holeID = mdHole and mdHole.id and mdHole.rot and mdHole.id .. "_" .. mdHole.rot

    local fabricMD = fabric and fabric:getModData()
    local fPiece = fabricMD.interactiveTailoring and fabricMD.interactiveTailoring.piece
    local piece = fPiece and fPiece.id and fPiece.rot and fPiece.id .. "_" .. fPiece.rot

    if not piece or not holeID then return end

    return (piece == holeID)
end


function interactiveTailoringUI:patchTooltip(fabric, part, name, tooltip)
    tooltip = tooltip or ISInventoryPaneContextMenu.addToolTip()

    tooltip.description = ""

    if name and part then
        local partName = part:getDisplayName()
        tooltip.description = tooltip.description .. partName .. " <LINE>"
    end

    if fabric and part then

        tooltip.description = tooltip.description .. getText("IGUI_perks_Tailoring") .. ": " .. self.player:getPerkLevel(Perks.Tailoring) .. " <LINE>"

        if self.clothing:canFullyRestore(self.player, part, fabric) then
            tooltip.description = tooltip.description .. self.ghs .. getText("Tooltip_FullyRestore") .. " <LINE>"
        else
            tooltip.description = tooltip.description .. self.ghs .. getText("Tooltip_ScratchDefense")  .. " +" .. Clothing.getScratchDefenseFromItem(self.player, fabric) .. " <LINE> " .. getText("Tooltip_BiteDefense") .. " +" .. Clothing.getBiteDefenseFromItem(self.player, fabric) .. " <LINE>"
        end

        local patchMatchesPart = self:patchMatchesPart(fabric, part)
        if patchMatchesPart then
            tooltip.description = tooltip.description .. "<GREEN>" .. getText("IGUI_MatchedPiece")
        else
            tooltip.description = tooltip.description .. "<RED>" .. getText("IGUI_MismatchedPiece")
        end

    else

        if self.clothing:getVisual():getHole(part) > 0 then
            tooltip.description = tooltip.description .. " <RED>".. getText("IGUI_garment_Hole") .. " <LINE>"
        end

        local bloodLevelForPart = self.clothing:getBloodlevelForPart(part)
        if bloodLevelForPart > 0 then
            tooltip.description = tooltip.description .. " <RED>".. getText("IGUI_garment_Blood") .. round(bloodLevelForPart * 100, 0) .. "%" .. " <LINE>"
        end

        local patch = self.clothing:getPatchType(part)
        if patch then
            tooltip.description = tooltip.description .. " <GREEN>".. getText("IGUI_TypeOfPatch", patch:getFabricTypeName()) .. " <LINE>"
        end
    end

    return tooltip
end


function interactiveTailoringUI:doPatch(fabric, thread, needle, part, context, submenu)
    if not self.clothing:getFabricType() then
        return
    end

    local hole = self.clothing:getVisual():getHole(part) > 0
    local patch = self.clothing:getPatchType(part)

    local text
    local allText

    if hole then
        text = getText("ContextMenu_PatchHole")
        allText = getText("ContextMenu_PatchAllHoles") .. fabric:getDisplayName()
    elseif not patch then
        text = getText("ContextMenu_AddPadding")
        allText = getText("ContextMenu_AddPaddingAll") .. fabric:getDisplayName()
    else
        error "patch ~= nil"
    end

    if not submenu then -- after the 2nd iteration we have a submenu, we simply add our different fabric to it
        local option = context:addOption(text)
        submenu = context:getNew(context)
        context:addSubMenu(option, submenu)
    end

    local option = submenu:addOption(fabric:getDisplayName(), self.player, ISInventoryPaneContextMenu.repairClothing, self.clothing, part, fabric, thread, needle)
    local tooltip = self:patchTooltip(fabric, part)
    option.toolTip = tooltip

    -- Patch/Add pad all
    local allOption
    local allTooltip = ISInventoryPaneContextMenu.addToolTip()

    if(self.player:getInventory():getItemCount(fabric:getType(), true) > 1) then
        if hole and (self.clothing:getHolesNumber() > 1) then
            allOption = submenu:addOption(allText, self.player, ISInventoryPaneContextMenu.repairAllClothing, self.clothing, self.parts, fabric, thread, needle, true)
            allTooltip.description = getText("Tooltip_PatchAllHoles") .. fabric:getDisplayName()
            allOption.toolTip = allTooltip
        elseif not hole and not patch and (self:getPaddablePartsNumber(self.clothing, self.parts) > 1) then
            allOption = submenu:addOption(allText, self.player, ISInventoryPaneContextMenu.repairAllClothing, self.clothing, self.parts, fabric, thread, needle, false)
            allTooltip.description = getText("Tooltip_AddPaddingToAll") .. fabric:getDisplayName()
            allOption.toolTip = allTooltip
        end
    end

    return submenu
end


function interactiveTailoringUI:doContextMenu(part, x, y)
    local context = ISContextMenu.get(self.player:getPlayerNum(), x, y)

    -- you need thread and needle
    local thread = self.thread
    local needle = self.needle

    local fabric1 = (self.rippedSheets:size() > 0) and self.rippedSheets:get(0)
    local fabric2 = (self.denimStrips:size() > 0) and self.denimStrips:get(0)
    local fabric3 = (self.leatherStrips:size() > 0) and self.leatherStrips:get(0)

    -- Require a needle to remove a patch.  Maybe scissors or a knife instead?
    local patch = self.clothing:getPatchType(part)
    if patch then
        -- Remove specific patch
        local removeOption = context:addOption(getText("ContextMenu_RemovePatch"), self.player, ISInventoryPaneContextMenu.removePatch, self.clothing, part, needle)
        local tooltip = ISInventoryPaneContextMenu.addToolTip()
        removeOption.toolTip = tooltip

        -- Remove all patches
        local patchesCount = self.clothing:getPatchesNumber()
        local removeAllOption
        local removeAllTooltip
        if (patchesCount > 1) then
            removeAllOption = context:addOption(getText("ContextMenu_RemoveAllPatches"), self.player, ISInventoryPaneContextMenu.removeAllPatches, self.clothing, self.parts, needle)
            removeAllTooltip = ISInventoryPaneContextMenu.addToolTip()
            removeAllOption.toolTip = removeAllTooltip
        end

        if needle then
            tooltip.description = getText("Tooltip_GetPatchBack", ISRemovePatch.chanceToGetPatchBack(self.player)) .. " <LINE>" .. self.bhs .. getText("Tooltip_ScratchDefense")  .. " -" .. patch:getScratchDefense() .. " <LINE> " .. getText("Tooltip_BiteDefense") .. " -" .. patch:getBiteDefense()
            if(removeAllTooltip ~= nil) then
                removeAllTooltip.description = getText("Tooltip_GetPatchesBack", ISRemovePatch.chanceToGetPatchBack(self.player)) .. " <LINE>" .. self.bhs .. getText("Tooltip_ScratchDefense")  .. " -" .. (patch:getScratchDefense() * patchesCount) .. " <LINE> " .. getText("Tooltip_BiteDefense") .. " -" .. (patch:getBiteDefense() * patchesCount)
            end
        else
            tooltip.description = getText("ContextMenu_CantRemovePatch")
            removeOption.notAvailable = true
            if(removeAllTooltip ~= nil) then
                removeAllTooltip.description = getText("ContextMenu_CantRemovePatch")
                removeAllOption.notAvailable = true
            end
        end
        return context
    end

    -- Cannot patch without thread, needle and fabric
    if not thread or not needle or (not fabric1 and not fabric2 and not fabric3) then
        local patchOption = context:addOption(getText("ContextMenu_Patch"))
        patchOption.notAvailable = true
        local tooltip = ISInventoryPaneContextMenu.addToolTip()
        tooltip.description = getText("ContextMenu_CantRepair")
        patchOption.toolTip = tooltip
        return context
    end

    local submenu
    local allSubmenu
    if fabric1 then
        submenu = self:doPatch(fabric1, thread, needle, part, context, submenu)
    end
    if fabric2 then
        submenu = self:doPatch(fabric2, thread, needle, part, context, submenu)
    end
    if fabric3 then
        submenu = self:doPatch(fabric3, thread, needle, part, context, submenu)
    end

    return context
end


function interactiveTailoringUI:doDrawItem(y, item, alt)
    local part = item.item

    if item.itemindex == self.mouseoverselected then
        self:drawRect(0, y, self:getWidth(), item.height, 0.1, 1.0, 1.0, 1.0)
    end

    self:drawText(part:getDisplayName(), 0, y, 1, 1, 1, 1, UIFont.Small)
    self:drawText(self.parent.clothing:getDefForPart(part, true, false) .. "%", self.parent.biteColumn - self.x, y, 1, 1, 1, 1, UIFont.Small)
    self:drawText(self.parent.clothing:getDefForPart(part, false, false) .. "%", self.parent.scratchColumn - self.x, y, 1, 1, 1, 1, UIFont.Small)
    self:drawText(self.parent.clothing:getDefForPart(part, false, true) .. "%", self.parent.bulletColumn - self.x, y, 1, 1, 1, 1, UIFont.Small)

    local br,bg,bb = getCore():getBadHighlitedColor():getR(), getCore():getBadHighlitedColor():getG(), getCore():getBadHighlitedColor():getB()
    local gr,gg,gb = getCore():getGoodHighlitedColor():getR(), getCore():getGoodHighlitedColor():getG(), getCore():getGoodHighlitedColor():getB()

    if self.parent.clothing:getVisual():getHole(part) > 0 then
        y = y + self.parent.fontSmallHgt
        self:drawText(getText("IGUI_garment_Hole"), 10, y, br,bg,bb, 1, UIFont.Small)
    end

    local bloodLevelForPart = self.parent.clothing:getBloodlevelForPart(part)
    if bloodLevelForPart > 0 then
        y = y + self.parent.fontSmallHgt
        self:drawText(getText("IGUI_garment_Blood") .. round(bloodLevelForPart * 100, 0) .. "%", 10, y, br,bg,bb, 1, UIFont.Small)
    end

    local patch = self.parent.clothing:getPatchType(part)
    if patch then
        y = y + self.parent.fontSmallHgt
        self:drawText("- " .. getText("IGUI_TypeOfPatch", patch:getFabricTypeName()), 10, y, gr,gg,gb, 1, UIFont.Small)
    end

    local x = 10
    local fgBar = {r=0.5, g=0.5, b=0.5, a=0.5}
    local UI = self.parent
    local bodyPartAction = UI.bodyPartAction and UI.bodyPartAction[part] or nil
    if bodyPartAction then
        y = y + self.parent.fontSmallHgt
        self:drawProgressBar(x, y, self.width - 10 - x, self.parent.fontSmallHgt, bodyPartAction.delta, fgBar)
        self:drawText(bodyPartAction.jobType, x + 4, y, 0.8, 0.8, 0.8, 1, UIFont.Small)
    else
        local actionQueue = ISTimedActionQueue.getTimedActionQueue(UI.player)
        if actionQueue and actionQueue.queue and UI.actionToBodyPart and (UI.actionToBodyPart[actionQueue.queue[1]] == part) then
            y = y + self.parent.fontSmallHgt
            self:drawProgressBar(x, y, self.width - 10 - x, self.parent.fontSmallHgt, actionQueue.queue[1]:getJobDelta(), fgBar)
            self:drawText(actionQueue.queue[1].jobType or "???", x + 4, y, 0.8, 0.8, 0.8, 1, UIFont.Small) -- jobType is a hack for CraftingUI and ISHealthPanel also
        end
    end

    return y + self.parent.fontSmallHgt + self.parent.padding
end


function interactiveTailoringUI:initialise()
    ISCollapsableWindow.initialise(self)

    self:setResizable(false)

    local gridX = self.gridX + self.padding + 2
    local gridY = self.gridY + (self.padding*2) + self.fontSmallHgt + 2
    local gridW = self.gridW - (self.padding*2) - 4
    local gridH = self.gridH - (self.padding*3) - self.fontSmallHgt - 4

    self.coveredParts = ISScrollingListBox:new(gridX, gridY, gridW, gridH)
    self.coveredParts:initialise()
    self.coveredParts:instantiate()
    self.coveredParts.itemheight = 128
    self.coveredParts.drawBorder = false
    self.coveredParts.backgroundColor.a = 0
    self.coveredParts.doDrawItem = interactiveTailoringUI.doDrawItem
    self.coveredParts.onRightMouseUp = interactiveTailoringUI.onBodyPartListRightMouseUp
    self:addChild(self.coveredParts)

    self:calcColumnWidths(gridX+self.padding)

    for i=0, self.clothing:getCoveredParts():size() - 1 do
        local part = self.clothing:getCoveredParts():get(i)
        if part then
            table.insert(self.parts, part)
            self.coveredParts:addItem("part", part)
        end
    end
end


function interactiveTailoringUI:onMouseWheel(del)

    local x, y = self:getMouseX(), self:getMouseY()
    if x >= self.mouseOverZones.sidebar.x and x <= self.mouseOverZones.sidebar.x+self.mouseOverZones.sidebar.w
            and y >= self.mouseOverZones.sidebar.y and y <= self.mouseOverZones.sidebar.y+self.mouseOverZones.sidebar.h then
        self.sidebarScroll = self.sidebarScroll+(del*3)
    end

    if self.draggingMaterial then
        --{ strip=strip, id=piece.id, rot=piece.rot, color=color }
        local fabricMD = self.draggingMaterial.strip and self.draggingMaterial.strip:getModData()
        local fPiece = fabricMD.interactiveTailoring and fabricMD.interactiveTailoring.piece

        if fPiece then
            local angles = pieceHandler.pieceAngles[fPiece.id]
            if angles then
                local currentRot = fPiece.rot
                local currentIndex = 1

                for i = 1, #angles do
                    if angles[i] == currentRot then
                        currentIndex = i
                        break
                    end
                end

                local step = del > 0 and 1 or -1
                local nextIndex = currentIndex + step
                if nextIndex < 1 then nextIndex = #angles elseif nextIndex > #angles then nextIndex = 1 end
                fPiece.rot = angles[nextIndex]
                self.hoverOverMaterial.rot = angles[nextIndex]
            end
        end
    end

    return true
end


function interactiveTailoringUI:createChildren()
    ISCollapsableWindow.createChildren(self)
    self.collapseButton:setVisible(false)
    self.isCollapsed = false
end


function interactiveTailoringUI:drawTools(x,y)
    ---thread
    local threadX = x+(self.gridScale*0.66)
    self:fetchItem("thread", "Thread", "Thread")
    if self.thread then
        self:drawRectBorder(threadX-2, y-2, self.clothingUI.iW+4, self.clothingUI.iH+4, 0.7, 0.5, 0.5, 0.5)
        self:drawBar(threadX, y, self.clothingUI.iW, self.clothingUI.iH, self.thread:getCurrentUsesFloat(), true, true)
        self:drawItemIcon(self.thread, threadX, y, 1, self.clothingUI.iW, self.clothingUI.iH)
    else
        self:drawRectBorder(threadX-2, y-2, self.clothingUI.iW+4, self.clothingUI.iH+4,
                self.failColor.a*0.66, self.failColor.r, self.failColor.g, self.failColor.b)
        self:drawTexture(self.failThread, threadX, y, self.failColor.a, self.failColor.r, self.failColor.g, self.failColor.b)
    end

    ---needle
    local needleX = threadX-(self.padding*2)-self.gridScale
    self:fetchItem("needle", "Needle", "SewingNeedle")
    if self.needle then
        self:drawRectBorder(needleX-2, y-2, self.clothingUI.iW+4, self.clothingUI.iH+4, 0.7, 0.5, 0.5, 0.5)
        self:drawItemIcon(self.needle, needleX, y, 1, self.clothingUI.iW, self.clothingUI.iH)
    else
        self:drawRectBorder(needleX-2, y-2, self.clothingUI.iW+4, self.clothingUI.iH+4,
                self.failColor.a*0.66, self.failColor.r, self.failColor.g, self.failColor.b)
        self:drawTexture(self.failNeedle, needleX, y, self.failColor.a, self.failColor.r, self.failColor.g, self.failColor.b)
    end

    ---scissors
    local scissorsX = needleX-(self.padding*2)-self.gridScale

    self:fetchItem("scissors", "Scissors", "Scissors")
    if self.scissors then
        self:drawRectBorder(scissorsX-2, y-2, self.clothingUI.iW+4, self.clothingUI.iH+4, 0.7, 0.5, 0.5, 0.5)
        self:drawItemIcon(self.scissors, scissorsX, y, 1, self.clothingUI.iW, self.clothingUI.iH)
    else
        self:drawRectBorder(scissorsX-2, y-2, self.clothingUI.iW+4, self.clothingUI.iH+4,
                self.failColor.a*0.66, self.failColor.r, self.failColor.g, self.failColor.b)
        self:drawTexture(self.failScissors, scissorsX, y, self.failColor.a, self.failColor.r, self.failColor.g, self.failColor.b)
    end
end


function interactiveTailoringUI:calcColumnWidths(x)
    local partColumnWidth = 0
    for i=1,BloodBodyPartType.MAX:index() do
        local part = BloodBodyPartType.FromIndex(i-1)
        local width = getTextManager():MeasureStringX(UIFont.Small, part:getDisplayName())
        partColumnWidth = math.max(partColumnWidth, width)
    end
    local partSize = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_garment_BodyPart"))
    local biteSize = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_health_Bite"))
    local scratchSize = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_health_Scratch"))
    local bulletSize = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_health_Bullet"))
    partColumnWidth = math.max(partColumnWidth, partSize)
    self.biteColumn = x + partColumnWidth + 10
    self.scratchColumn = math.max(self.biteColumn + 10 + biteSize)
    self.bulletColumn = math.max(self.scratchColumn + 10 + scratchSize)

    local scrollbarWidth = 17
    local listRight = self.bulletColumn + bulletSize + scrollbarWidth
    --local progressWidth = self.progressWidthTotal + 20 * 2
    --self:setWidth(math.max(listRight, progressWidth))
end


function interactiveTailoringUI:drawClothingInfo(x,y,w,h)
    self:drawRect(x, y, w, h, 0.9, 0.1, 0.1, 0.1)

    local columnX = x + self.padding
    local columnY = y + self.padding

    self.coveredParts:setVisible(true)

    self:drawText(getText("IGUI_garment_BodyPart"), columnX, columnY, 1, 1, 1, 1, UIFont.Small)
    self:drawText(getText("IGUI_health_Scratch"), self.scratchColumn, columnY, 1, 1, 1, 1, UIFont.Small)
    self:drawText(getText("IGUI_health_Bite"), self.biteColumn, columnY, 1, 1, 1, 1, UIFont.Small)
    self:drawText(getText("IGUI_health_Bullet"), self.bulletColumn, columnY, 1, 1, 1, 1, UIFont.Small)
end


function interactiveTailoringUI:drawActionProgress(x,y,w,h)

    local actionQueue = ISTimedActionQueue.getTimedActionQueue(self.player)
    local part = actionQueue.queue[1] and actionQueue.queue[1].part

    local fgBar = {r=0.3, g=0.3, b=0.3, a=0.5}
    local bodyPartAction = self.bodyPartAction and self.bodyPartAction[part] or nil
    if bodyPartAction then
        self:drawProgressBar(x, y, w, self.fontSmallHgt, bodyPartAction.delta, fgBar)
        self:drawText(bodyPartAction.jobType, x + 4, y, 0.8, 0.8, 0.8, 1, UIFont.Small)
    else
        if actionQueue and actionQueue.queue and self.actionToBodyPart and (self.actionToBodyPart[actionQueue.queue[1]] == part) then
            self:drawProgressBar(x, y, w, self.fontSmallHgt, actionQueue.queue[1]:getJobDelta(), fgBar)
            self:drawText(actionQueue.queue[1].jobType or "???", x + 4, y, 0.8, 0.8, 0.8, 1, UIFont.Small)
            -- jobType is a hack for CraftingUI and ISHealthPanel also
        end
    end
end


function interactiveTailoringUI:mouseOverInfo(dx, dy)
    if not self.mouseOverZones.gridArea then return end
    if dx < self.mouseOverZones.gridArea.x or dx > self.mouseOverZones.gridArea.x2
            or dy < self.mouseOverZones.gridArea.y or dy > self.mouseOverZones.gridArea.y2 then return end

    self:drawRectBorder(self.gridX-2, self.gridY-2, self.gridW+4, self.gridH+4, 0.8, 1, 1, 1)
    if self.toggleClothingInfo then return end

    if getPlayerContextMenu(self.player:getPlayerNum()):getIsVisible() then return end

    local itModData = self.clothing:getModData().interactiveTailoring
    local mdHoles = itModData and itModData.holes
    if mdHoles then
        self.hoverOverPart = nil
        for part,hole in pairs(mdHoles) do
            local xy = hole.xy
            for _,xys in pairs(xy) do
                local _x, _y = xys[1], xys[2]
                if _x and _y then

                    local x1, y1 = self.padding + (self.gridScale*(_x-1)), self.gridY + ((_y-1)*self.gridScale)
                    local x2, y2 = x1+self.gridScale, y1+self.gridScale
                    if dx >= x1 and dx <= x2 and dy > y1 and dy <= y2 then
                        local _part = BloodBodyPartType.FromString(part)

                        self.hoverOverPart = _part
                        local strip = self.draggingMaterial and self.draggingMaterial.strip
                        if not self.toolTip then
                            local toolTip = self:patchTooltip(strip, _part, true, self.toolTip)
                            self:showTooltip(toolTip)
                        else
                            self:patchTooltip(strip, _part, true, self.toolTip)
                        end
                        local tooltipOffset = self.draggingMaterial and (self.gridScale*2) or 0-self.gridScale
                        if self.toolTip then
                            self.toolTip:setDesiredPosition( self.x+dx+tooltipOffset, self.y+dy-self.toolTip.height-self.padding )
                        end
                        break
                    end
                end
            end
        end
    end
end


function interactiveTailoringUI:DrawTextureAngleScaled(tex, centerX, centerY, angleDeg, scale, r, g, b, a)
    if not tex or not self.javaObject or not self:isVisible() then return end


    local w, h = tex:getWidth(), tex:getHeight()
    scale = scale or 1
    w = w * scale
    h = h * scale

    local cx, cy = w / 2, h / 2
    local angleRad = math.rad(180 + (angleDeg or 0))

    local cosA = math.cos(angleRad)
    local sinA = math.sin(angleRad)

    local dx = cosA * cx
    local dy = sinA * cx
    local dx2 = cosA * cy
    local dy2 = sinA * cy

    local absX = self:getAbsoluteX() + centerX
    local absY = self:getAbsoluteY() + centerY

    local x0 = dx - dy2 + absX
    local y0 = dx2 + dy + absY
    local x1 = -dx - dy2 + absX
    local y1 = dx2 - dy + absY
    local x2 = -dx + dy2 + absX
    local y2 = -dx2 - dy + absY
    local x3 = dx + dy2 + absX
    local y3 = -dx2 + dy + absY

    r, g, b, a = r or 1, g or 1, b or 1, a or 1
    SpriteRenderer.instance:render(tex, x0, y0, x1, y1, x2, y2, x3, y3, r, g, b, a, r, g, b, a, r, g, b, a, r, g, b, a, nil)
end


function interactiveTailoringUI:render()
    ISCollapsableWindow.render(self)
    self:mouseOverInfo(self:getMouseX(), self:getMouseY())
    if (not self.hoverOverPart) then self:hideToolTip() end

    if self.draggingMaterial then
        self:DrawTextureAngleScaled(getTexture("media/textures/"..self.draggingMaterial.id.."_piece.png"),
                getMouseX()-self.x, getMouseY()-self.y, self.draggingMaterial.rot,
                4, self.draggingMaterial.color.r, self.draggingMaterial.color.g, self.draggingMaterial.color.b, 1)
    end
end


function interactiveTailoringUI:prerender()
    ISCollapsableWindow.prerender(self)

    self.coveredParts:setVisible(false)

    local mouseX,mouseY = self:getMouseX(), self:getMouseY()

    if not self.mouseOverZones.gridArea then
        self.mouseOverZones.gridArea = { x=self.gridX, y=self.gridY, x2=self.gridX+self.gridW, y2=self.gridY+self.gridH }
    end

    ---fabric
    for _x=0, self.gridSizeW-1 do
        for _y=0, self.gridSizeH-1 do
            self:drawTextureScaled(self.fabricTexture,
                    self.padding + (self.gridScale*_x), self.gridY + (_y*self.gridScale),
                    self.gridScale, self.gridScale,
                    self.clothingColor.a, self.clothingColor.r, self.clothingColor.g, self.clothingColor.b)
        end
    end

    ---holes
    local cHoles = self.clothing:getHolesNumber()+self.clothing:getPatchesNumber()
    if cHoles > 0 then

        local itModData = self.clothing:getModData().interactiveTailoring
        local mdHoles = itModData and itModData.holes
        if mdHoles then
            for part,hole in pairs(mdHoles) do
                local _part = BloodBodyPartType.FromString(part)
                local xy = hole.xy
                for _,xys in pairs(xy) do
                    local _x, _y = xys[1], xys[2]
                    if _x and _y then

                        local patch = self.clothing:getPatchType(_part)
                        local patchType = patch and patch:getFabricType()
                        if patch then
                            local color = self.patchColor[patchType]
                            self:drawTextureScaled(self.fabricTexture,
                                    self.padding + (self.gridScale*(_x-1)), self.gridY + ((_y-1)*self.gridScale),
                                    self.gridScale, self.gridScale, 1, color.r, color.g, color.b)
                        else
                            self:drawTextureScaled(self.holeTexture,
                                    self.padding + (self.gridScale*(_x-1))-2, self.gridY + ((_y-1)*self.gridScale)-2,
                                    self.gridScale+4, self.gridScale+4, 1, 1, 1, 1)
                        end
                    end
                end
            end
        end
    end

    self:drawRectBorder(self.gridX-2, self.gridY-2, self.gridW+4, self.gridH+4, self.toggleClothingInfo and 0.8 or 0.4, 1, 1, 1)

    ---sidebar
    self:fetchMaterials()

    if not self.mouseOverZones.sidebar then
        self.mouseOverZones.sidebar = { x=(self.padding*2)+(self.gridSizeW*self.gridScale)-2, y=self.gridY-2, w=(3*self.gridScale)+4, h=self.gridSizeH*self.gridScale+4 }
    end

    local width = 3
    local height = self.gridSizeH
    local max = (width * height)-1

    local rs = self.rippedSheets:size()
    local ds = self.denimStrips:size()
    local ls = self.leatherStrips:size()

    local total = rs + ds + ls
    local stripScrolls = math.max(0, total - max-1)
    self.sidebarScroll = math.max(0,math.min(stripScrolls, self.sidebarScroll))
    
    for i = 0, max do
        local _x = i % width
        local _y = math.floor(i / width)

        local index = i + self.sidebarScroll
        local piece, strip
        if index < rs then
            piece, strip = self:getMaterialAtIndex(index, self.rippedSheets)
        elseif index < rs + ds then
            piece, strip = self:getMaterialAtIndex(index - rs, self.denimStrips)
        elseif index < rs + ds + ls then
            piece, strip = self:getMaterialAtIndex(index - rs - ds, self.leatherStrips)
        end

        if piece and strip then

            local matX = self.mouseOverZones.sidebar.x + (self.gridScale*_x) + 2
            local matY = self.gridY + (_y*self.gridScale)
            local color = self.patchColor[self.patchColorIndex[strip:getFabricType()]]

            local contextOpen = getPlayerContextMenu(self.player:getPlayerNum()):getIsVisible()
            local draggingThis = (self.draggingMaterial and strip==self.draggingMaterial.strip)
            local mouseover = (mouseX > matX and mouseX < (matX+self.gridScale) and mouseY > matY and mouseY < (matY+self.gridScale))

            if (not contextOpen) and (draggingThis or mouseover) then
                if not self.draggingMaterial then
                    self.hoverOverMaterial = { strip=strip, id=piece.id, rot=piece.rot, color=color }
                end
                self:drawRect(matX+1, matY+1, self.gridScale-2, self.gridScale-2, 0.3,1,1,1)
            else
                self:drawRect(matX+1, matY+1, self.gridScale-2, self.gridScale-2, 0.1, 1, 1, 1)
            end

            self:DrawTextureAngleScaled(getTexture("media/textures/"..piece.id.."_piece.png"), matX+16, matY+16, piece.rot, 1, color.r, color.g, color.b, 1)
        end
    end

    self:drawRectBorder(self.mouseOverZones.sidebar.x, self.mouseOverZones.sidebar.y,
            self.mouseOverZones.sidebar.w, self.mouseOverZones.sidebar.h, 0.9, 0.5, 0.5, 0.5)


    ---header
    self:drawRectBorder(self.padding-2, self.padding+self.tbh+1, self:getWidth()-(self.padding*2)+4, self.headerHeight, 0.9, 0.5, 0.5, 0.5)

    ---clothing
    local clothingX = self.padding + (((self.gridSizeW/2)+0.5)*self.gridScale) - (self.clothingUI.iW/2)
    local clothingY = self.padding + (self.tbh*1.6) + (self.clothingUI.iH/2)

    if not self.mouseOverZones.clothing then
        self.mouseOverZones.clothing = { x=clothingX-2, y=clothingY-2, w=self.clothingUI.iW+4, h=self.clothingUI.iH+4 }
    end

    if not self.clothing:getFabricType() then
        self:drawText(getText("IGUI_garment_CantRepair"),
                clothingX, clothingY+self.padding+self.clothingUI.iH,
                self.failColor.r, self.failColor.g, self.failColor.b, self.failColor.a*2, UIFont.Small)
        self:drawRectBorder(
                self.mouseOverZones.clothing.x, self.mouseOverZones.clothing.y,
                self.mouseOverZones.clothing.w, self.mouseOverZones.clothing.h,
                self.failColor.a*1.5, self.failColor.r, self.failColor.g, self.failColor.b)
    else
        self:drawRectBorder(
                self.mouseOverZones.clothing.x, self.mouseOverZones.clothing.y,
                self.mouseOverZones.clothing.w, self.mouseOverZones.clothing.h,
                self.toggleClothingInfo and 0.8 or 0.3, 1, 1, 1)
    end

    self:drawItemIcon(self.clothing, clothingX, clothingY, 1, self.clothingUI.iW, self.clothingUI.iH)

    if self.clothing:isBroken() then
        self:drawTexture(self.brokenItemIcon, clothingX+self.clothingUI.iW-12, clothingY+self.clothingUI.iH-14, 1, 1, 1, 1)
    end

    local bar_hgt = 8
    local fnt_hgt = self.fontSmallHgt
    local barY = (self.padding*1.5)+self.tbh
    local barW = 120

    local cndFraction = self.clothing:getCondition()/self.clothing:getConditionMax()
    self:drawText(getText("IGUI_invpanel_Condition"), self.padding*2, barY, 1, cndFraction==0 and 0 or 1, cndFraction==0 and 0 or 1, 0.9, UIFont.Small)
    self:drawBar(self.padding*2, barY+fnt_hgt, barW, bar_hgt, cndFraction, true)

    barY = barY+bar_hgt+fnt_hgt+(self.padding/2.5)

    self:drawText(getText("IGUI_garment_GlbBlood"), self.padding*2, barY, 1, 1, 1, 0.9, UIFont.Small)
    self:drawBar(self.padding*2, barY+fnt_hgt, barW, bar_hgt, self.clothing:getBloodlevel() / 100, false)

    barY = barY+bar_hgt+fnt_hgt+(self.padding/2.5)

    self:drawText(getText("IGUI_garment_GlbDirt"), self.padding*2, barY, 1, 1, 1, 0.9, UIFont.Small)
    self:drawBar(self.padding*2, barY+fnt_hgt, barW, bar_hgt, self.clothing:getDirtyness() / 100, false)

    self:drawTools(self.mouseOverZones.sidebar.x,clothingY)

    ---draw tools or clothing info
    local clothingZone = self.mouseOverZones.clothing
    if self.toggleClothingInfo or (mouseX >= clothingZone.x and mouseX <= clothingZone.x+clothingZone.w
            and mouseY >= clothingZone.y and mouseY <= clothingZone.y+clothingZone.h) then

        self:drawTextureScaled(self.pinButtonTexture,
                clothingZone.x + ((clothingZone.w-(self.tbh-2))/2) , clothingZone.y + ((clothingZone.h-(self.tbh-2))/2), self.tbh-2, self.tbh-2,
                self.toggleClothingInfo and 0.9 or 0.6, 1, 1, 1)

        self:drawClothingInfo(self.gridX, self.gridY, self.gridW, self.gridH)
    else
        self:drawActionProgress(self.gridX, self.gridY, self.gridW, self.gridH)
    end
end


function interactiveTailoringUI:drawBar(x, y, width, height, percent, highGood, vert)
    local color = ColorInfo.new(0, 0, 0, 1)
    if highGood then
        getCore():getBadHighlitedColor():interp(getCore():getGoodHighlitedColor(), percent, color)
    else
        getCore():getGoodHighlitedColor():interp(getCore():getBadHighlitedColor(), percent, color)
    end
    local tempColor = {r=color:getR(), g=color:getG(), b=color:getB(), a=0.8}
    self:drawProgressBar(x, y, width, height, percent, tempColor, vert)
end


function interactiveTailoringUI:drawProgressBar(x, y, w, h, f, fg, vert)
    if f < 0.0 then f = 0.0 end
    if f > 1.0 then f = 1.0 end
    local done = math.floor((vert and h or w) * f)
    if f > 0 then done = math.max(done, 1) end
    self:drawRect(x, y + (vert and h-done or 0), (vert and w or done), (vert and done or h), fg.a, fg.r, fg.g, fg.b)
    local bg = {r=0.15, g=0.15, b=0.15, a=1.0}
    self:drawRect(x + (vert and 0 or done), y, w - (vert and 0 or done), h - (vert and done or 0), bg.a, bg.r, bg.g, bg.b)
end


function interactiveTailoringUI:close()
    interactiveTailoringUI.instance = nil
    self:removeFromUIManager()
end


function interactiveTailoringUI.open(player, clothing)
    if interactiveTailoringUI.instance then interactiveTailoringUI.instance:close() end
    local ui = interactiveTailoringUI:new(player, clothing)
    ui:initialise()
    ui:addToUIManager()
    interactiveTailoringUI.instance = ui
    return ui
end


function interactiveTailoringUI:fetchItem(forThis, type,tag)
    if self[forThis] and self[forThis]:isInPlayerInventory() then return end
    if (not type and not tag) then self[forThis] = false return end
    self[forThis] = self.player:getInventory():getItemFromType(type, true, true) or self.player:getInventory():getFirstTagRecurse(tag) or false
end


function interactiveTailoringUI:getMaterialAtIndex(index, array)
    if index > array:size()-1 then return end
    local material = array:get(index)
    local piece = material and material:getModData().interactiveTailoring.piece
    return piece, material
end


function interactiveTailoringUI:applyDataToMaterials(array)
    for i = 0, array:size() - 1 do
        local fabric = array:get(i)
        local fabricMD = fabric and fabric:getModData()

        if not fabricMD.interactiveTailoring then
            local piece = pieceHandler.pickRandomType()
            fabricMD.interactiveTailoring = {}
            fabricMD.interactiveTailoring.piece = {id=piece.id, rot=piece.rot}
        end
    end
end


function interactiveTailoringUI:fetchMaterials()
    ---@type ItemContainer
    local inv = self.player:getInventory()
    local contentWeight = inv:getContentsWeight()
    if self.inventoryCheck == contentWeight then return end
    self.inventoryCheck = contentWeight

    self.rippedSheets = inv:getItemsFromType("RippedSheets")
    self:applyDataToMaterials(self.rippedSheets)

    self.denimStrips = inv:getItemsFromType("DenimStrips")
    self:applyDataToMaterials(self.denimStrips)

    self.leatherStrips = inv:getItemsFromType("LeatherStrips")
    self:applyDataToMaterials(self.leatherStrips)
end


---also generates interactive-holes for the items
function interactiveTailoringUI:getHoles()
    if not self.clothing then return end
    ---@type Clothing|InventoryItem
    local c = self.clothing
    local cHoles = c:getHolesNumber()+c:getPatchesNumber()
    if cHoles == 0 then return 0 end

    self.holes = cHoles

    local md = c:getModData()

    md.interactiveTailoring = md.interactiveTailoring or {}
    md.interactiveTailoring.holes = md.interactiveTailoring.holes or {}
    local mdHoles = md.interactiveTailoring.holes

    local grid = {}
    for x = 1, self.gridSizeW do
        grid[x] = {}
        for y = 1, self.gridSizeH do
            grid[x][y] = false
        end
    end

    local visual = c:getVisual()
    local coveredParts = c:getCoveredParts()

    for i = 0, coveredParts:size() - 1 do
        local part = coveredParts:get(i)
        local hole = visual:getHole(part) + visual:getBasicPatch(part) + visual:getDenimPatch(part) + visual:getLeatherPatch(part)

        local partID = tostring(part)

        if hole > 0 and (not mdHoles[partID]) then

            local piece = pieceHandler.pickRandomType()

            local maxX, maxY = 0, 0
            for _, pt in ipairs(piece.xy) do
                if pt[1] and pt[2] then
                    maxX = math.max(maxX, pt[1])
                    maxY = math.max(maxY, pt[2])
                end
            end

            local validPlacement = false
            local attempts = 20

            mdHoles[partID] = mdHoles[partID] or {}
            mdHoles[partID].id = piece.id
            mdHoles[partID].rot = piece.rot
            mdHoles[partID].xy = mdHoles[partID].xy or {}
            
            while attempts > 0 and not validPlacement do
                attempts = attempts - 1
                local ox = ZombRand(self.gridSizeW - maxX) + 1
                local oy = ZombRand(self.gridSizeH - maxY) + 1

                local overlaps = false
                for _, pt in ipairs(piece.xy) do
                    if pt[1] and pt[2] then
                        local x = ox + pt[1]
                        local y = oy + pt[2]
                        if grid[x][y] then
                            overlaps = true
                            break
                        end
                    end
                end

                if not overlaps then
                    validPlacement = true
                    for _, pt in ipairs(piece.xy) do
                        if pt[1] and pt[2] then
                            local x = ox + pt[1]
                            local y = oy + pt[2]
                            grid[x] = grid[x] or {}
                            grid[x][y] = true

                            table.insert(mdHoles[partID].xy, {x, y})
                        end
                    end
                end
            end
        end
    end
end


local setBodyPartActionForPlayer_Orig = ISGarmentUI.setBodyPartActionForPlayer
function ISGarmentUI.setBodyPartActionForPlayer(playerObj, bodyPart, action, jobType, args)

    if not playerObj or playerObj:isDead() then return end
    if not playerObj:isLocalPlayer() then return end
    local ui = interactiveTailoringUI.instance
    if ui then
        if args then
            args.jobType = jobType
            args.delta = action:getJobDelta()
        end
        ui:setBodyPartAction(bodyPart, args)
    end
    setBodyPartActionForPlayer_Orig(playerObj, bodyPart, action, jobType, args)
end


local setOtherActionForPlayer_Orig = ISGarmentUI.setOtherActionForPlayer
function ISGarmentUI.setOtherActionForPlayer(playerObj, bodyPart, action)
    if not playerObj or playerObj:isDead() then return end
    if not playerObj:isLocalPlayer() then return end
    local ui = interactiveTailoringUI.instance
    if ui then ui:setBodyPartForAction(action, bodyPart) end
    setOtherActionForPlayer_Orig(playerObj, bodyPart, action)
end


function interactiveTailoringUI:setBodyPartAction(bodyPart, args)
    self.bodyPartAction = self.bodyPartAction or {}
    self.bodyPartAction[bodyPart] = args
end


function interactiveTailoringUI.setBodyPartForLastAction(playerObj, bodyPart)
    if not playerObj or playerObj:isDead() then return end
    if not playerObj:isLocalPlayer() then return end
    local actionQueue = ISTimedActionQueue.getTimedActionQueue(playerObj)
    if not actionQueue or not actionQueue.queue or (#actionQueue.queue == 0) then return end
    ISGarmentUI.setOtherActionForPlayer(playerObj, bodyPart, actionQueue.queue[#actionQueue.queue])
end


function interactiveTailoringUI:setBodyPartForAction(action, bodyPart)
    self.actionToBodyPart = self.actionToBodyPart or {}
    self.actionToBodyPart[action] = bodyPart
end


function interactiveTailoringUI:onMouseDown(x, y)
    if x >= self.mouseOverZones.gridArea.x and x <= self.mouseOverZones.gridArea.x2
            and y >= self.mouseOverZones.gridArea.y and y <= self.mouseOverZones.gridArea.y2 then
        return
    end

    if x >= self.mouseOverZones.sidebar.x and x <= self.mouseOverZones.sidebar.x+self.mouseOverZones.sidebar.w
            and y >= self.mouseOverZones.sidebar.y and y <= self.mouseOverZones.sidebar.y+self.mouseOverZones.sidebar.h then

        if (not self.toggleClothingInfo) and self.hoverOverMaterial then self.draggingMaterial = self.hoverOverMaterial end

        return
    end

    ISCollapsableWindow.onMouseDown(self, x, y)
end


function interactiveTailoringUI:onRightMouseUp(x, y)
    ISCollapsableWindow.onRightMouseUp(self)
    if self.hoverOverPart and (not self.draggingMaterial) then
        self:doContextMenu(self.hoverOverPart, getMouseX(), getMouseY())
    end
    if self.draggingMaterial then self:hideToolTip() end
    self.hoverOverPart = nil
    self.draggingMaterial = nil
end


function interactiveTailoringUI:onMouseUp(x, y)
    ISCollapsableWindow.onMouseUp(self, x, y)
    if not self:getIsVisible() then return end

    local clothingZone = self.mouseOverZones.clothing
    if x >= clothingZone.x and x <= clothingZone.x+clothingZone.w and y >= clothingZone.y and y <= clothingZone.y+clothingZone.h then
        getSoundManager():playUISound(self.sounds.activate)
        self.toggleClothingInfo = not self.toggleClothingInfo
    end

    local part = self.hoverOverPart
    local strip = self.draggingMaterial and self.draggingMaterial.strip

    self.hoverOverPart = nil
    self.draggingMaterial = nil

    if part and strip and (not self.clothing:getPatchType(part)) then
        self:repairClothing(part, strip)
    end
end


function interactiveTailoringUI:onMouseUpOutside(x, y)
    ISCollapsableWindow.onMouseUpOutside(self, x, y)
    self.hoverOverPart = nil
    self.draggingMaterial = nil
end


---@param clothing InventoryItem|Clothing
function interactiveTailoringUI:new(player, clothing)

    local gridSizeW, gridSizeH, gridScale = 10, 11, 32--px
    local padding = 10

    local screenW, screenH = getCore():getScreenWidth(), getCore():getScreenHeight()

    local w = ((padding*3) + (gridSizeW+3)*gridScale)
    local h = ((padding*3) + (gridSizeH+3)*gridScale) + ISCollapsableWindow.TitleBarHeight()

    local x, y = (screenW-w)/2, (screenH-h)/2
    local o = ISCollapsableWindow.new(self, x, y, w, h)
    setmetatable(o, self)
    self.__index = self

    o.gridSizeW = gridSizeW
    o.gridSizeH = gridSizeH
    o.gridScale = gridScale
    o.padding = padding

    o.tbh = o:titleBarHeight()
    o.headerHeight = o.gridScale*3
    o.gridX = o.padding
    o.gridY = (o.padding*2)+o.headerHeight+o.tbh
    o.gridW = (o.gridSizeW*o.gridScale)
    o.gridH = (o.gridSizeH*o.gridScale)

    o.sidebarScroll = 0

    o.mouseOverZones = {}
    o.toggleClothingInfo = false

    o.player = player
    ---@type Clothing|InventoryItem
    o.clothing = clothing
    o.title = clothing:getDisplayName()

    o.inventoryCheck = 0

    o:fetchItem("thread", "Thread", "Thread")
    o:fetchItem("needle", "Needle", "SewingNeedle")
    o:fetchItem("scissors", "Scissors", "Scissors")

    o.holes = 0
    o:getHoles()
    o.parts = {}

    o.sounds = {}
    o.sounds.activate = "UIActivateButton"

    o.clothingUI = {}
    o.clothingUI.icon = clothing:getTex()



    o.clothingColor = {
        a=o.clothing:getA(),
        r=o.clothing:getR(),
        g=o.clothing:getG(),
        b=o.clothing:getB(),
    }

    local clothingItem = o.clothing:getClothingItem()
    if not clothingItem:getAllowRandomTint() then

        local input = o.clothing:getIcon():getName()
        ---For some reason getName returns the entire path of the icons for some items - Like `...common\ProjectZomboid\media\textures\Item_Shirt_CamoTree.png`
        local iconName = input:match("([^\\/]+)%.png$") or input
        local generatedColor = generatedColors[iconName] or {r=0.7,g=0.7,b=0.7}

        print("generatedColor: ", iconName, "   r="..generatedColor.r..",g="..generatedColor.g..",b="..generatedColor.b)

        o.clothingColor = {a=1,r=generatedColor.r,g=generatedColor.g,b=generatedColor.b}
    end

    o.clothingUI.iW = o.clothingUI.icon:getWidthOrig()
    o.clothingUI.iH = o.clothingUI.icon:getHeightOrig()

    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}

    return o
end