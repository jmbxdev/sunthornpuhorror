local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EnemyHandlerServer = require(ServerScriptService.Source.Features.Enemy.Classes.EnemyHandlerServer)
local MapServer = require(ServerScriptService.Source.Features.Map.Classes.MapServer)

local ChapterInfo = require(ReplicatedStorage.Source.Features.Chapter.Modules.ChapterInfo)

local ChapterServiceServer = {}

function ChapterServiceServer.init(self: ChapterServiceServer, ChapterName: string)
	local chapterinfo = ChapterInfo.get(ChapterName) :: ChapterInfo
    self.map = MapServer.new(chapterinfo.map) ::MapServer
    self.enemyhandler = EnemyHandlerServer.new(self.map.model.EnemySpawn, chapterinfo.enemies) ::EnemyHandlerServer
end

type EnemyHandlerServer = EnemyHandlerServer.EnemyHandlerServer
type MapServer = MapServer.MapServer

type ChapterInfo = ChapterInfo.ChapterInfo
type ChapterServiceServer = typeof(ChapterServiceServer)

return ChapterServiceServer
