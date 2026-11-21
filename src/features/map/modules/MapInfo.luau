local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MapModelType = require(ReplicatedStorage.Source.Features.Map.Types.MapModelType)

type MapModel = MapModelType.MapModel

export type MapInfo = {
    model : MapModel
}


local Maps = {
    Baseplate = {
        model = ServerStorage.Assets.Maps.Baseplate
    }
}

local MapInfo = {}

function MapInfo.get(MapName :string)
    assert(Maps[MapName],"MapInfo not found")
    return Maps[MapName]
end

return MapInfo