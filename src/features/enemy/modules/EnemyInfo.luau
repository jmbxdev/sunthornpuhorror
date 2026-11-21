local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyRoamChase = require(ReplicatedStorage.Source.Features.Enemy.Factories.EnemyRoamChase)

export type EnemyInfo = {
    model :Model,
    arg :{
        [string] :any
    },
    factory :(EnemyInfo) -> any
}

local Models = {
    Writer = ReplicatedStorage.Assets.Enemies.Writer
}

local Enemies = {
    Writer = {
        model = Models.Writer,
        arg = {
            agentParameters = {
            AgentRadius = 5,
	        AgentHeight = 12,
	        AgentCanJump = false
            },
        },
        factory = EnemyRoamChase
    }
}

local EnemyInfo = {}

function EnemyInfo.get(EnemyName :string) 
    assert(Enemies[EnemyName],"Enemy not found")
    return Enemies[EnemyName]
end

return EnemyInfo