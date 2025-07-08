local pieceHandler = {}

pieceHandler.pieceTypes = {
    long_0 = { id = "long", rot=0, xy = { {0,0}, {1,0}, {2,0}, {3,0} }, },
    long_90 = { id = "long", rot=90, xy = { {0,0}, {0,1}, {0,2}, {0,3} } },

    square_0 = { id = "square", rot=0, xy = { {0,0}, {1,0}, {0,1}, {1,1} }, },

    tee_0 = { id = "tee", rot=0, xy = { {0,0}, {1,0}, {2,0}, {1,1} }, },
    tee_90 = { id = "tee", rot=90, xy = { {1,0}, {0,1}, {1,1}, {1,2} } },
    tee_180 = { id = "tee", rot=180, xy = { {1,0}, {0,1}, {1,1}, {2,1} } },
    tee_270 = { id = "tee", rot=270, xy = { {0,0}, {0,1}, {1,1}, {0,2} } },

    ess_0 = { id = "ess", rot=0, xy = { {1,0}, {2,0}, {0,1}, {1,1} } },
    ess_90 = { id = "ess", rot=90, xy = { {0,0}, {0,1}, {1,1}, {1,2} } },

    zee_0 = { id = "zee", rot=0, xy = { {0,0}, {1,0}, {1,1}, {2,1} } },
    zee_90 = { id = "zee", rot=90, xy = { {1,0}, {0,1}, {1,1}, {0,2} } },

    jay_0 = { id = "jay", rot=0, xy = { {0,0}, {0,1}, {1,1}, {2,1} } },
    jay_90 = { id = "jay", rot=90, xy = { {0,0}, {1,0}, {0,1}, {0,2} } },
    jay_180 = { id = "jay", rot=180, xy = { {0,0}, {1,0}, {2,0}, {2,1} } },
    jay_270 = { id = "jay", rot=270, xy = { {1,0}, {1,1}, {1,2}, {0,2} } },

    ell_0 = { id = "ell", rot=0, xy = { {2,0}, {0,1}, {1,1}, {2,1} } },
    ell_90 = { id = "ell", rot=90, xy = { {0,0}, {0,1}, {0,2}, {1,2} } },
    ell_180 = { id = "ell", rot=180, xy = { {0,0}, {1,0}, {2,0}, {0,1} } },
    ell_270 = { id = "ell", rot=270, xy = { {0,0}, {1,0}, {1,1}, {1,2} } },
}

pieceHandler.pieceTypesIndex = false
pieceHandler.pieceAngles = {}

function pieceHandler.buildPieceTypeIndex()
    if pieceHandler.pieceTypesIndex then return end
    pieceHandler.pieceTypesIndex = {}

    for id,data in pairs(pieceHandler.pieceTypes) do

        pieceHandler.pieceAngles[data.id] = pieceHandler.pieceAngles[data.id] or {}
        table.insert(pieceHandler.pieceAngles[data.id], data.rot)

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