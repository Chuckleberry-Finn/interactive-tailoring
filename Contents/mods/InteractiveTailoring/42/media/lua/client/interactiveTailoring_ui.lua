require "ISUI/ISCollapsableWindow.lua"
---ISGarmentUI

local pieceHandler = require "interactiveTailoring_pieceHandler.lua"

interactiveTailoringUI = ISCollapsableWindow:derive("interactiveTailoringUI")
interactiveTailoringUI.fontHgt = getTextManager():getFontHeight(UIFont.NewMedium)
interactiveTailoringUI.fontSmallHgt = getTextManager():getFontHeight(UIFont.NewSmall)
interactiveTailoringUI.fabricTexture = getTexture("media/textures/fabric.png")
interactiveTailoringUI.holeTexture = getTexture("media/textures/hole.png")

interactiveTailoringUI.patchColor = {
    { r = 0.855, g = 0.843, b = 0.749 },--cotton
    { r = 0.396, g = 0.522, b = 0.639 },--denim
    { r = 0.584, g = 0.369, b = 0.204 },--leather
}

function interactiveTailoringUI:update()
    ISCollapsableWindow.update(self)
    if not self.clothing or not self.clothing:isInPlayerInventory() then self:close() end
end


function interactiveTailoringUI:initialise()
    ISCollapsableWindow.initialise(self)
    self:setResizable(false)
end


function interactiveTailoringUI:onMouseWheel(del)
    return true
end


function interactiveTailoringUI:createChildren()
    ISCollapsableWindow.createChildren(self)
    self.collapseButton:setVisible(false)
    self.isCollapsed = false
end


function interactiveTailoringUI:render()
    ISCollapsableWindow.render(self)

    local tbh = self:titleBarHeight()
    local headerHeight = self.gridScale*3

    ---fabric
    local gridY = (self.padding*2)+headerHeight+tbh
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

        if self.holes ~= cHoles then
            --TODO: FETCH NEW HOLES
        end

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

    self:drawRectBorder(self.padding-2, gridY-2, (self.gridW*self.gridScale)+4, (self.gridH*self.gridScale)+4, 0.9, 0.5, 0.5, 0.5)

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
    self:drawRectBorder(clothingX-2, clothingY-2, self.clothingUI.iW+4, self.clothingUI.iH+4, 0.7, 0.5, 0.5, 0.5)
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


    ---thread
    local threadX = sidebarX+(self.gridScale*0.66)
    self:fetchItem("thread", "Thread", "Thread")
    if self.thread then
        self:drawRectBorder(threadX-2, clothingY-2, self.clothingUI.iW+4, self.clothingUI.iH+4, 0.7, 0.5, 0.5, 0.5)
        self:drawBar(threadX, clothingY, self.clothingUI.iW, self.clothingUI.iH, self.thread:getCurrentUsesFloat(), true, true)
        self:drawItemIcon(self.thread, threadX, clothingY, 1, self.clothingUI.iW, self.clothingUI.iH)
    else
        self:drawRectBorder(threadX-2, clothingY-2, self.clothingUI.iW+4, self.clothingUI.iH+4,
                self.failColor.a*0.66, self.failColor.r, self.failColor.g, self.failColor.b)
        self:drawTexture(self.failThread, threadX, clothingY, self.failColor.a, self.failColor.r, self.failColor.g, self.failColor.b)
    end

    ---needle
    local needleX = threadX-(self.padding*2)-self.gridScale
    self:fetchItem("needle", "Needle", "SewingNeedle")
    if self.needle then
        self:drawRectBorder(needleX-2, clothingY-2, self.clothingUI.iW+4, self.clothingUI.iH+4, 0.7, 0.5, 0.5, 0.5)
        self:drawItemIcon(self.needle, needleX, clothingY, 1, self.clothingUI.iW, self.clothingUI.iH)
    else
        self:drawRectBorder(needleX-2, clothingY-2, self.clothingUI.iW+4, self.clothingUI.iH+4,
                self.failColor.a*0.66, self.failColor.r, self.failColor.g, self.failColor.b)
        self:drawTexture(self.failNeedle, needleX, clothingY, self.failColor.a, self.failColor.r, self.failColor.g, self.failColor.b)
    end

    ---scissors
    local scissorsX = needleX-(self.padding*2)-self.gridScale

    self:fetchItem("scissors", "Scissors", "Scissors")
    if self.scissors then
        self:drawRectBorder(scissorsX-2, clothingY-2, self.clothingUI.iW+4, self.clothingUI.iH+4, 0.7, 0.5, 0.5, 0.5)
        self:drawItemIcon(self.scissors, scissorsX, clothingY, 1, self.clothingUI.iW, self.clothingUI.iH)
    else
        self:drawRectBorder(scissorsX-2, clothingY-2, self.clothingUI.iW+4, self.clothingUI.iH+4,
                self.failColor.a*0.66, self.failColor.r, self.failColor.g, self.failColor.b)
        self:drawTexture(self.failScissors, scissorsX, clothingY, self.failColor.a, self.failColor.r, self.failColor.g, self.failColor.b)
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
    local cHoles = c:getHolesNumber()
    if cHoles == 0 then return 0 end

    self.holes = cHoles

    local md = c:getModData()
    if md.interactiveTailoring and md.interactiveTailoring.holes then return md.interactiveTailoring.holes end

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
        local hole = visual:getHole(part)

        if hole > 0 then
            local piece = pieceHandler.pickRandomType()

            local maxX, maxY = 0, 0
            for _, pt in ipairs(piece) do
                maxX = math.max(maxX, pt[1])
                maxY = math.max(maxY, pt[2])
            end

            local validPlacement = false
            local attempts = 20

            while attempts > 0 and not validPlacement do
                attempts = attempts - 1
                local ox = ZombRand(self.gridW - maxX) + 1
                local oy = ZombRand(self.gridH - maxY) + 1

                local overlaps = false
                for _, pt in ipairs(piece) do
                    local x = ox + pt[1]
                    local y = oy + pt[2]
                    if grid[x][y] then
                        overlaps = true
                        break
                    end
                end

                if not overlaps then
                    validPlacement = true
                    for _, pt in ipairs(piece) do
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


interactiveTailoringUI.failThread = getScriptManager():getItem("Thread"):getNormalTexture()
interactiveTailoringUI.failNeedle = getScriptManager():getItem("Needle"):getNormalTexture()
interactiveTailoringUI.failScissors = getScriptManager():getItem("Scissors"):getNormalTexture()
interactiveTailoringUI.failColor = {a=0.4,r=1,g=0.2,b=0.2}

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

    o.player = player
    o.clothing = clothing
    o.title = clothing:getDisplayName()

    o:fetchItem("thread", "Thread", "Thread")
    o:fetchItem("needle", "Needle", "SewingNeedle")
    o:fetchItem("scissors", "Scissors", "Scissors")

    o.threadFont = UIFont.NewLarge
    o.threadFontHeight = getTextManager():getFontHeight(o.threadFont)

    o.holes = 0
    o:getHoles()

    --[[ ---debug
    for _x=1, o.gridW do
        o.holes[_x] = {}
        for _y=1, o.gridH do
            o.holes[_x][_y] = (ZombRand(100) <= 2)
        end
    end
    --]]

    o.clothingUI = {}
    o.clothingUI.icon = clothing:getTex()
    o.clothingUI.iW = o.clothingUI.icon:getWidthOrig()
    o.clothingUI.iH = o.clothingUI.icon:getHeightOrig()

    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    --print("ITUI:  p:",player, "  c:",clothing)

    return o
end