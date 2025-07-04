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

pieceHandler.pieceTypesIndex = false


function pieceHandler.buildPieceTypeIndex()
    if pieceHandler.pieceTypesIndex then return end
    pieceHandler.pieceTypesIndex = {}

    for id,_ in pairs(pieceHandler.pieceTypes) do
        table.insert(pieceHandler.pieceTypesIndex, id)
    end
end


function pieceHandler.clonePiece(piece)
    local out = copyTable(piece)
    return out
end


function pieceHandler.pickRandomID()
    pieceHandler.buildPieceTypeIndex()
    local rand = ZombRand(#pieceHandler.pieceTypesIndex)+1
    local id = pieceHandler.pieceTypesIndex[rand]
    return id
end


function pieceHandler.pickRandomType()
    local id = pieceHandler.pickRandomID()
    local piece = pieceHandler.pieceTypes[id]
    local newPiece = pieceHandler.clonePiece(piece)
    return newPiece
end


return pieceHandler