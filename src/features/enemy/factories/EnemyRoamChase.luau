local PathfindingService = game:GetService("PathfindingService")

type EnemyInfo = {
    model :Model,
    arg : {
        agentParameters :{
          AgentRadius :number,
	      AgentHeight :number,
	      AgentCanJump :boolean,
	      AgentCanClimb :boolean,
	      WaypointSpacing : number,
	      Costs : {[string] :number},
        },
    }
}

return function(EnemyInfo : EnemyInfo)
    local model = EnemyInfo.model:Clone()


    local self = {
        id = nil,
        model = model,
        special = {
            humanoid = model:FindFirstChild("Humanoid"),
            path = PathfindingService:CreatePath(EnemyInfo.arg.agentParameters),
        }
    }

    self.update = function(_)
        
    end

    return self
end
