local context = require "interactiveTailoring_context.lua"
if context then Events.OnFillInventoryObjectContextMenu.Add(context.postContextMenu) end