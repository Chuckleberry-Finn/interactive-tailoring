require "ISUI/ISCollapsableWindow.lua"
---ISGarmentUI

interactiveTailoringUI = ISCollapsableWindow:derive("interactiveTailoringUI")
interactiveTailoringUI.font = getTextManager():getFontHeight(UIFont.NewMedium)

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

    ---fabric
    local gridY = ((self.padding+self.gridScale)*2)+tbh
    for _x=0, self.gridW-1 do
        for _y=0, self.gridH-1 do
            self:drawTextureScaled(self.fabricTexture,
                    self.padding + (self.gridScale*_x), gridY + (_y*self.gridScale),
                    self.gridScale, self.gridScale,
                    self.clothing:getA(), self.clothing:getR(), self.clothing:getG(), self.clothing:getB())
        end
    end

    ---holes
    for _x=1, #self.holes do
        for _y=1, #self.holes[_x] do
            if self.holes[_x][_y] then
                self:drawTextureScaled(getTexture("media/textures/hole.png"),
                        self.padding + (self.gridScale*(_x-1))-2, gridY + ((_y-1)*self.gridScale)-2,
                        self.gridScale+4, self.gridScale+4,
                        self.clothing:getA(), self.clothing:getR(), self.clothing:getG(), self.clothing:getB())
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
    self:drawRectBorder(self.padding, self.padding+tbh, self:getWidth()-(self.padding*2), self.gridScale*2, 0.9, 0.5, 0.5, 0.5)

    ---clothing
    local clothingX = self.padding+((self.gridW/2)*self.gridScale)-(self.clothingUI.iW/2)
    local clothingY = self.padding+tbh+(self.clothingUI.iH/2)
    self:drawRectBorder(clothingX-2, clothingY-2, self.clothingUI.iW+4, self.clothingUI.iH+4, 0.7, 0.5, 0.5, 0.5)
    self:drawItemIcon(self.clothing, clothingX, clothingY, 1, self.clothingUI.iW, self.clothingUI.iH)

    ---thread
    local threadX = sidebarX+(self.gridScale*0.66)
    self:fetchItem("thread", "Thread", "Thread")
    if self.thread then
        self:drawRectBorder(threadX-2, clothingY-2, self.clothingUI.iW+4, self.clothingUI.iH+4, 0.7, 0.5, 0.5, 0.5)
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
        self:drawRectBorder(scissorsX-2, clothingY-2, self.clothingUI.iW+4, self.clothingUI.iH+4, self.activeItemA,
                self.failColor.a*0.66, self.failColor.r, self.failColor.g, self.failColor.b)
        self:drawTexture(self.failScissors, scissorsX, clothingY, self.failColor.a, self.failColor.r, self.failColor.g, self.failColor.b)
    end
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
    if not type and not tag then self[forThis] = false return end
    self[forThis] = self.player:getInventory():getItemFromType(type, true, true) or self.player:getInventory():getFirstTagRecurse(tag) or false
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
    local h = ((padding*3) + (gridH+2)*gridScale) + ISCollapsableWindow.TitleBarHeight()

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

    o:fetchItem("thread", "Thread", "Thread")
    o:fetchItem("needle", "Needle", "SewingNeedle")
    o:fetchItem("scissors", "Scissors", "Scissors")

    o.threadFont = UIFont.NewLarge
    o.threadFontHeight = getTextManager():getFontHeight(o.threadFont)

    o.holes = {}
    for _x=1, o.gridW do
        o.holes[_x] = {}
        for _y=1, o.gridH do
            o.holes[_x][_y] = (ZombRand(100) <= 2)
        end
    end

    o.clothingUI = {}
    o.clothingUI.icon = clothing:getTex()
    o.clothingUI.iW = o.clothingUI.icon:getWidthOrig()
    o.clothingUI.iH = o.clothingUI.icon:getHeightOrig()

    o.fabricTexture = getTexture("media/textures/fabric.png")

    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}

    print("ITUI:  p:",player, "  c:",clothing)

    return o
end