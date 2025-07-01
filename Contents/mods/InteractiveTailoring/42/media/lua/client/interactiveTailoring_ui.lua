require "ISUI/ISGarmentUI.lua"
require "ISUI/ISCollapsableWindow.lua"

interactiveTailoringUI = ISCollapsableWindow:derive("interactiveTailoringUI")
interactiveTailoringUI.font = getTextManager():getFontHeight(UIFont.NewMedium)

function interactiveTailoringUI:update()
    ISCollapsableWindow.update(self)
end


function interactiveTailoringUI:initialise()
    ISCollapsableWindow.initialise(self)
end


function interactiveTailoringUI:render()
    ISCollapsableWindow.render(self)
end


function interactiveTailoringUI:close()
    self:removeFromUIManager()
end


function interactiveTailoringUI.open(player, clothing)
    local ui = interactiveTailoringUI:new(player, clothing)
    ui:initialise()
    ui:addToUIManager()
    return ui
end


function interactiveTailoringUI:new(player, clothing)

    local w, h = 460, 300
    local x, y = (getCore():getScreenWidth()-w)/2, (getCore():getScreenHeight()-h)/2
    local o = ISCollapsableWindow.new(self, 200, 200, w, h)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.clothing = clothing

    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}

    print("ITUI:  p:",player, "  c:",clothing)

    return o
end