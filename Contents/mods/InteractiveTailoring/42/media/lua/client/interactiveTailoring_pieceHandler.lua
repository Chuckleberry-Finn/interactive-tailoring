local pieceHandler = {}

pieceHandler.pieceTypes = {
    long = { id = "long",
        xy = { { 0, 0 }, { 1, 0 }, { 2, 0 }, { 3, 0 } },
    },

    square = { id = "square",
        xy = { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } },
    },

    tee = { id = "tee",
        xy = { { 0, 0 }, { 1, 0 }, { 2, 0 }, { 1, 1 } },
    },

    ess = { id = "ess",
        xy = { { 1, 0 }, { 2, 0 }, { 0, 1 }, { 1, 1 } },
    },

    zee = { id = "zee",
        xy = { { 0, 0 }, { 1, 0 }, { 1, 1 }, { 2, 1 } },
    },

    jay = { id = "jay",
        xy = { { 0, 0 }, { 0, 1 }, { 1, 1 }, { 2, 1 } },
    },

    ell = { id = "ell",
        xy = { { 2, 0 }, { 0, 1 }, { 1, 1 }, { 2, 1 } },
    },
}

pieceHandler.pieceTypes.index = false
pieceHandler.pieceTextures = {}

function pieceHandler.buildPieceTypeIndex()
    if pieceHandler.pieceTypes.index then return end
    pieceHandler.pieceTypes.index = {}

    for id,_ in pairs(pieceHandler.pieceTypes) do
        table.insert(pieceHandler.pieceTextures, getTexture("media/textures/"..id.."_piece.png"))
        table.insert(pieceHandler.pieceTypes.index, id)
    end
end


function pieceHandler.clonePiece(piece)
    local out = copyTable(piece)
    return out
end


function pieceHandler.rotate(piece)
    local rotated = {}
    for i, cell in ipairs(piece.xy) do
        local x, y = cell[1], cell[2]
        table.insert(rotated, {y, -x})
    end
    piece.xy = rotated
end


function pieceHandler.pickRandomType()
    pieceHandler.buildPieceTypeIndex()
    local rand = ZombRand(#pieceHandler.pieceTypes.index)+1
    local id = pieceHandler.pieceTypes.index[rand]
    local piece = pieceHandler.pieceTypes[id]
    return pieceHandler.clonePiece(piece)
end


return pieceHandler