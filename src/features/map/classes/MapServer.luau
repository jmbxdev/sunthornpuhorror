local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapInfo = require(ReplicatedStorage.Source.Features.Map.Modules.MapInfo)
local MapModelType = require(ReplicatedStorage.Source.Features.Map.Types.MapModelType)

local MapServer = {}
MapServer.__index = MapServer

type MapModel = MapModelType.MapModel
type MapInfo = MapInfo.MapInfo

export type MapServer = typeof(setmetatable({} :: {
    model :MapModel,
}, MapServer))

function MapServer.new(MapName :string) :MapServer
    local mapinfo = MapInfo.get(MapName) ::MapInfo
    
    local model = mapinfo.model:Clone()
    model.Parent = workspace

    local self = setmetatable({
        model = model,
    }, MapServer)

    return self
end

return MapServer