require "ISUI/ISCollapsableWindow.lua"
require "ISUI/ISGarmentUI.lua"

local pieceHandler = require "interactiveTailoring_pieceHandler.lua"

interactiveTailoringUI = ISCollapsableWindow:derive("interactiveTailoringUI")
interactiveTailoringUI.fontHgt = getTextManager():getFontHeight(UIFont.NewMedium)
interactiveTailoringUI.fontSmallHgt = getTextManager():getFontHeight(UIFont.NewSmall)
interactiveTailoringUI.fabricTexture = getTexture("media/textures/fabric.png")
interactiveTailoringUI.holeTexture = getTexture("media/textures/hole.png")

interactiveTailoringUI.threadFont = UIFont.NewLarge
interactiveTailoringUI.threadFontHeight = getTextManager():getFontHeight(interactiveTailoringUI.threadFont)

interactiveTailoringUI.failThread = getScriptManager():getItem("Thread"):getNormalTexture()
interactiveTailoringUI.failNeedle = getScriptManager():getItem("Needle"):getNormalTexture()
interactiveTailoringUI.failScissors = getScriptManager():getItem("Scissors"):getNormalTexture()
interactiveTailoringUI.failColor = {a=0.5,r=1,g=0.1,b=0.1}

interactiveTailoringUI.ghs = "<GHC>"
interactiveTailoringUI.bhs = "<BHC>"

interactiveTailoringUI.patchColor = {
    { r = 0.855, g = 0.843, b = 0.749 },--cotton
    { r = 0.396, g = 0.522, b = 0.639 },--denim
    { r = 0.584, g = 0.369, b = 0.204 },--leather
}

function interactiveTailoringUI:update()
    ISCollapsableWindow.update(self)
    if not self.clothing or not self.clothing:isInPlayerInventory() then self:close() end
end


function interactiveTailoringUI:onBodyPartListRightMouseUp(x, y)
    local row = self:rowAt(x, y)
    if row < 1 or row > #self.items then return end
    self.parent:doContextMenu(self.items[row].item, getMouseX(), getMouseY())
end


function interactiveTailoringUI:getPaddablePartsNumber(clothing, parts)
    local count = 0

    for i=1, #parts do
        local part = parts[i]
        local hole = clothing:getVisual():getHole(part) > 0
        local patch = clothing:getPatchType(part)
        if(hole == false and patch == nil) then
            count = count + 1
        end
    end

    return count
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
    local tooltip = ISInventoryPaneContextMenu.addToolTip()
    if self.clothing:canFullyRestore(self.player, part, fabric) then
        tooltip.description = getText("IGUI_perks_Tailoring") .. " :" .. self.player:getPerkLevel(Perks.Tailoring) .. " <LINE>" .. self.ghs .. getText("Tooltip_FullyRestore")
    else
        tooltip.description = getText("IGUI_perks_Tailoring") .. " :" .. self.player:getPerkLevel(Perks.Tailoring) .. " <LINE>" .. self.ghs .. getText("Tooltip_ScratchDefense")  .. " +" .. Clothing.getScratchDefenseFromItem(self.player, fabric) .. " <LINE> " .. getText("Tooltip_BiteDefense") .. " +" .. Clothing.getBiteDefenseFromItem(self.player, fabric)
    end
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
    local fabric1 = self.player:getInventory():getItemFromType("RippedSheets", true, true)
    local fabric2 = self.player:getInventory():getItemFromType("DenimStrips", true, true)
    local fabric3 = self.player:getInventory():getItemFromType("LeatherStrips", true, true)

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

    if self.parent.clothing:getBloodlevelForPart(part) > 0 then
        y = y + self.parent.fontSmallHgt
        self:drawText(getText("IGUI_garment_Blood") .. round(self.parent.clothing:getBloodlevelForPart(part) * 100, 0) .. "%", 10, y, br,bg,bb, 1, UIFont.Small)
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

    local tbh = self:titleBarHeight()
    local headerHeight = self.gridScale*3
    local gridX = (self.padding*2)+2
    local gridY = (self.padding*3)+headerHeight+tbh+self.padding+2+self.fontSmallHgt
    local gridW = (self.gridW*self.gridScale)-(self.padding*2)-4
    local gridH = (self.gridH*self.gridScale)-(self.padding*3)-self.fontSmallHgt-4

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


function interactiveTailoringUI:prerender()
    ISCollapsableWindow.prerender(self)

    self.coveredParts:setVisible(false)

    local tbh = self:titleBarHeight()
    local headerHeight = self.gridScale*3

    ---fabric
    local gridX = self.padding
    local gridY = (self.padding*2)+headerHeight+tbh
    local gridW = (self.gridW*self.gridScale)
    local gridH = (self.gridH*self.gridScale)

    for _x=0, self.gridW-1 do
        for _y=0, self.gridH-1 do
            self:drawTextureScaled(self.fabricTexture,
                    self.padding + (self.gridScale*_x), gridY + (_y*self.gridScale),
                    self.gridScale, self.gridScale,
                    self.clothing:getA(), self.clothing:getR(), self.clothing:getG(), self.clothing:getB())
        end
    end

    ---holes
    local cHoles = self.clothing:getHolesNumber()+self.clothing:getPatchesNumber()
    if cHoles > 0 then

        local itModData = self.clothing:getModData().interactiveTailoring
        local mdHoles = itModData and itModData.holes
        if mdHoles then
            for part,xs in pairs(mdHoles) do
                for _x,ys in pairs(xs) do
                    for _y,_ in pairs(ys) do
                        if mdHoles[part][_x][_y] then

                            local patch = self.clothing:getPatchType(part)
                            local patchType = patch and patch:getFabricType()
                            if patch then
                                local color = self.patchColor[patchType]
                                self:drawTextureScaled(self.fabricTexture,
                                        self.padding + (self.gridScale*(_x-1)), gridY + ((_y-1)*self.gridScale),
                                        self.gridScale, self.gridScale, 1, color.r, color.g, color.b)
                            else
                                self:drawTextureScaled(self.holeTexture,
                                        self.padding + (self.gridScale*(_x-1))-2, gridY + ((_y-1)*self.gridScale)-2,
                                        self.gridScale+4, self.gridScale+4, 1, 1, 1, 1)
                            end
                        end
                    end
                end
            end
        end
    end

    self:drawRectBorder(gridX-2, gridY-2, gridW+4, gridH+4, self.toggleClothingInfo and 0.8 or 0.4, 1, 1, 1)


    ---sidebar
    local sidebarX = (self.padding*2)+(self.gridW*self.gridScale)
    for _x=0, 3-1 do
        for _y=0, self.gridH-1 do

            self:drawRect(
                    sidebarX + (self.gridScale*_x)+1, gridY + (_y*self.gridScale)+1,
                    self.gridScale-2, self.gridScale-2,
                    0.3, 0.3, 0.3, 0.3)
        end
    end
    self:drawRectBorder(sidebarX-2, gridY-2, (3*self.gridScale)+4, self.gridH*self.gridScale+4, 0.9, 0.5, 0.5, 0.5)


    ---header
    self:drawRectBorder(self.padding, self.padding+tbh, self:getWidth()-(self.padding*2), headerHeight, 0.9, 0.5, 0.5, 0.5)

    ---clothing
    local clothingX = self.padding+((self.gridW/2)*self.gridScale)-(self.clothingUI.iW/2)
    local clothingY = self.padding+tbh+(self.clothingUI.iH/2)

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

    local bar_hgt = 8
    local fnt_hgt = self.fontSmallHgt
    local barY = (self.padding*1.5)+tbh
    local barW = 120

    self:drawText(getText("IGUI_invpanel_Condition"), self.padding*2, barY, 1, 1, 1, 0.9, UIFont.Small)
    self:drawBar(self.padding*2, barY+fnt_hgt, barW, bar_hgt, self.clothing:getCondition() / self.clothing:getConditionMax(), true)

    barY = barY+bar_hgt+fnt_hgt+(self.padding/2.5)

    self:drawText(getText("IGUI_garment_GlbBlood"), self.padding*2, barY, 1, 1, 1, 0.9, UIFont.Small)
    self:drawBar(self.padding*2, barY+fnt_hgt, barW, bar_hgt, self.clothing:getBloodlevel() / 100, false)

    barY = barY+bar_hgt+fnt_hgt+(self.padding/2.5)

    self:drawText(getText("IGUI_garment_GlbDirt"), self.padding*2, barY, 1, 1, 1, 0.9, UIFont.Small)
    self:drawBar(self.padding*2, barY+fnt_hgt, barW, bar_hgt, self.clothing:getDirtyness() / 100, false)

    self:drawTools(sidebarX,clothingY)

    ---draw tools or clothing info
    local x,y = self:getMouseX(), self:getMouseY()
    local clothingZone = self.mouseOverZones.clothing
    if self.toggleClothingInfo or (x >= clothingZone.x and x <= clothingZone.x+clothingZone.w and y >= clothingZone.y and y <= clothingZone.y+clothingZone.h) then

        self:drawTextureScaled(self.pinButtonTexture,
                clothingZone.x + ((clothingZone.w-(tbh-2))/2) , clothingZone.y + ((clothingZone.h-(tbh-2))/2), tbh-2, tbh-2,
                self.toggleClothingInfo and 0.9 or 0.6, 1, 1, 1)

        self:drawClothingInfo(gridX, gridY, gridW, gridH)
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
    for x = 1, self.gridW do
        grid[x] = {}
        for y = 1, self.gridH do
            grid[x][y] = false
        end
    end

    local visual = c:getVisual()
    local coveredParts = c:getCoveredParts()

    for i = 0, coveredParts:size() - 1 do
        local part = coveredParts:get(i)
        local hole = visual:getHole(part) + visual:getBasicPatch(part) + visual:getDenimPatch(part) + visual:getLeatherPatch(part)

        if hole > 0 then
            local piece = mdHoles[part] or pieceHandler.pickRandomType()

            local maxX, maxY = 0, 0
            for _, pt in ipairs(piece) do
                if pt[1] and pt[2] then
                    maxX = math.max(maxX, pt[1])
                    maxY = math.max(maxY, pt[2])
                end
            end

            local validPlacement = false
            local attempts = 20

            while attempts > 0 and not validPlacement do
                attempts = attempts - 1
                local ox = ZombRand(self.gridW - maxX) + 1
                local oy = ZombRand(self.gridH - maxY) + 1

                local overlaps = false
                for _, pt in ipairs(piece) do
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
                    for _, pt in ipairs(piece) do
                        if pt[1] and pt[2] then
                            local x = ox + pt[1]
                            local y = oy + pt[2]
                            grid[x][y] = true

                            mdHoles[part] = mdHoles[part] or {}
                            mdHoles[part][x] = mdHoles[part][x] or {}
                            mdHoles[part][x][y] = true
                        end
                    end
                end
            end
        end
    end
end


local setBodyPartActionForPlayer_Orig = ISGarmentUI.setBodyPartActionForPlayer
function ISGarmentUI.setBodyPartActionForPlayer(playerObj, bodyPart, action, jobType, args)
    setBodyPartActionForPlayer_Orig(playerObj, bodyPart, action, jobType, args)
    if not playerObj or playerObj:isDead() then return end
    if not playerObj:isLocalPlayer() then return end
    local garmentUI = interactiveTailoringUI.instance
    if not garmentUI then return end
    if args then
        args.jobType = jobType
        args.delta = action:getJobDelta()
    end
    garmentUI:setBodyPartAction(bodyPart, args)
end

local setOtherActionForPlayer_Orig = ISGarmentUI.setOtherActionForPlayer
function ISGarmentUI.setOtherActionForPlayer(playerObj, bodyPart, action)
    setOtherActionForPlayer_Orig(playerObj, bodyPart, action)
    if not playerObj or playerObj:isDead() then return end
    if not playerObj:isLocalPlayer() then return end
    local garmentUI = interactiveTailoringUI.instance
    if not garmentUI then return end
    garmentUI:setBodyPartForAction(action, bodyPart)
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


function interactiveTailoringUI:onMouseUp(x, y)
    ISCollapsableWindow.onMouseUp(self)
    if not self:getIsVisible() then return end

    local clothingZone = self.mouseOverZones.clothing
    if x >= clothingZone.x and x <= clothingZone.x+clothingZone.w and y >= clothingZone.y and y <= clothingZone.y+clothingZone.h then
        getSoundManager():playUISound(self.sounds.activate)
        self.toggleClothingInfo = not self.toggleClothingInfo
    end
end


---@param clothing InventoryItem|Clothing
function interactiveTailoringUI:new(player, clothing)

    local gridW, gridH, gridScale = 10, 11, 32--px
    local padding = 10

    local screenW, screenH = getCore():getScreenWidth(), getCore():getScreenHeight()

    local w = ((padding*3) + (gridW+3)*gridScale)
    local h = ((padding*3) + (gridH+3)*gridScale) + ISCollapsableWindow.TitleBarHeight()

    local x, y = (screenW-w)/2, (screenH-h)/2
    local o = ISCollapsableWindow.new(self, x, y, w, h)
    setmetatable(o, self)
    self.__index = self

    o.gridW = gridW
    o.gridH = gridH
    o.gridScale = gridScale
    o.padding = padding

    o.mouseOverZones = {}
    o.toggleClothingInfo = false

    o.player = player
    o.clothing = clothing
    o.title = clothing:getDisplayName()

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
    o.clothingUI.iW = o.clothingUI.icon:getWidthOrig()
    o.clothingUI.iH = o.clothingUI.icon:getHeightOrig()

    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}

    return o
end