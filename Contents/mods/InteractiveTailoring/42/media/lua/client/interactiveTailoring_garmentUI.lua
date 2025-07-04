require "ISUI/ISInventoryPaneContextMenu.lua"
require "interactiveTailoring_ui.lua"

--local original = ISInventoryPaneContextMenu.onInspectClothingUI
function ISInventoryPaneContextMenu.onInspectClothingUI(player, clothing)
    --original(player, clothing)
    if luautils.haveToBeTransfered(player, clothing) then
        local action = ISInventoryTransferAction:new(player, clothing, clothing:getContainer(), player:getInventory())
        action:setOnComplete(interactiveTailoringUI.open, player, clothing)
        ISTimedActionQueue.add(action)
    else
        interactiveTailoringUI.open(player, clothing)
    end
end