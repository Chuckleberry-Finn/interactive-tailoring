local pieceHandler = {}

pieceHandler.pieceTypes = {
    long = {{0, 0}, {1, 0}, {2, 0}, {3, 0}},
    square = {{0, 0}, {1, 0}, {0, 1}, {1, 1}},
    tee = {{0, 0}, {1, 0}, {2, 0}, {1, 1}},
    ess = {{1, 0}, {2, 0}, {0, 1}, {1, 1}},
    zee = {{0, 0}, {1, 0}, {1, 1}, {2, 1}},
    jay = {{0, 0}, {0, 1}, {1, 1}, {2, 1}},
    ell = {{2, 0}, {0, 1}, {1, 1}, {2, 1}},
}

pieceHandler.pieceTypes.index = false


function pieceHandler.buildPieceTypeIndex()
    if pieceHandler.pieceTypes.index then return end
    pieceHandler.pieceTypes.index = {}
    for id,_ in pairs(pieceHandler.pieceTypes) do
        table.insert(pieceHandler.pieceTypes.index, id)
    end
end


function pieceHandler.clonePiece(piece)
    local out = copyTable(piece)
    return out
end


function pieceHandler.rotate(piece)
    local rotated = {}
    for i, cell in ipairs(piece) do
        local x, y = cell[1], cell[2]
        table.insert(rotated, {y, -x})
    end
    return rotated
end


function pieceHandler.pickRandomType()
    pieceHandler.buildPieceTypeIndex()
    local rand = ZombRand(#pieceHandler.pieceTypes.index)+1
    local id = pieceHandler.pieceTypes.index[rand]
    local piece = pieceHandler.pieceTypes[id]
    return pieceHandler.clonePiece(piece)
end


return pieceHandler