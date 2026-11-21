local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ChapterServiceServer = require(ServerScriptService.Source.Features.Chapter.ChapterServiceServer)

local Chapter = "Baseplate"

Players.PlayerAdded:Once(function(player: Player)
    local joinData = player:GetJoinData()
    local teleportData = joinData.TeleportData
    
    if teleportData then
       Chapter = teleportData.Chapter
    end
end)

ChapterServiceServer:init(Chapter)

