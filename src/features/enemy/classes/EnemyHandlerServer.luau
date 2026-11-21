local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EnemyInfo = require(ReplicatedStorage.Source.Features.Enemy.Modules.EnemyInfo)
local EnemyType = require(ReplicatedStorage.Source.Features.Enemy.Types.EnemyType)

local EnemyHandlerServer = {}
EnemyHandlerServer.__index = EnemyHandlerServer

type EnemyInfo = EnemyInfo.EnemyInfo
type Enemy = EnemyType.Enemy

export type EnemyHandlerServer = typeof(setmetatable({} :: {
    spawnpart :Part,
    id :number,
    enemies : {[string] : Enemy},
    runconnection : RBXScriptConnection?
}, EnemyHandlerServer))

function EnemyHandlerServer.new(SpawnPart :Part,Enemies : {string}) :EnemyHandlerServer
    local self = setmetatable({
        spawnpart = SpawnPart,
        currentid = 0,
        enemies = {},
        runconnection = nil
    }, EnemyHandlerServer)

    for _,EnemyName in pairs(Enemies) do
        self:spawn(EnemyName)
    end

    self:start()

    return self
end

function EnemyHandlerServer.start(self :EnemyHandlerServer)
    if self.runconnection then return end

    self.runconnection = RunService.Heartbeat:Connect(function(dt: number)
        for _,enemy in pairs(self.enemies) do
            enemy:update()
        end
    end)
end

function EnemyHandlerServer.stop(self :EnemyHandlerServer)
    if not self.runconnection then return end

    self.runconnection:Disconnect()
    self.runconnection = nil
end

function EnemyHandlerServer.add(self :EnemyHandlerServer,Enemy :Enemy)
    self.currentid += 1

    local id = tostring(self.currentid)
    Enemy.id = id

    Enemy.model:SetAttribute("id",id)

    self.enemies[id] = Enemy
end

function EnemyHandlerServer.spawn(self :EnemyHandlerServer,EnemyName :string)
    local enemyinfo = EnemyInfo.get(EnemyName) ::EnemyInfo
    local enemy = enemyinfo:factory() ::Enemy

    enemy.model:PivotTo(self.spawnpart.CFrame)
    enemy.model.Parent = workspace

    self:add(enemy)
end

return EnemyHandlerServer