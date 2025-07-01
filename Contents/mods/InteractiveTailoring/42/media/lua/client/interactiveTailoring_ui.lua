require "ISUI/ISGarmentUI.lua"
require "ISUI/ISPanel.lua"

interactiveTailoringUI = ISPanel:derive("interactiveTailoringUI")
interactiveTailoringUI.font = getTextManager():getFontHeight(UIFont.NewMedium)

function interactiveTailoringUI:update()
    ISPanel.update(self)
    if not self.clothing or not self.clothing:isInPlayerInventory() then self:close() end
end


function interactiveTailoringUI:initialise()
    ISPanel.initialise(self)
    self:create()
end


function interactiveTailoringUI:render()
    ISPanel.render(self)
end


function interactiveTailoringUI:close()
    interactiveTailoringUI.windows[self.playerNum] = nil
    self:removeFromUIManager()
    if JoypadState.players[self.playerNum+1] then setJoypadFocus(self.playerNum, self.prevFocus) end
end


function interactiveTailoringUI:create()

end


function interactiveTailoringUI:new(player, clothing)

    local w, h = 460, 300
    local x, y = (getPlayerScreenWidth(0)-w)/2, (getPlayerScreenHeight(0)-h)/2
    local o = ISPanel.new(self, x, y, w, h)

    o.player = player
    o.clothing = clothing

    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}

    return o
end