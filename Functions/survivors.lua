local Survivors = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Actors = require(game.ReplicatedStorage.Modules.Gameplay.Actors)

local LocalPlayer = Players.LocalPlayer

local State = {
    AutoTrick = false
}

local Connections = {}
local LastAttempt = 0

function Survivors:SetAutoTrick(enabled)
    if enabled == State.AutoTrick then
        return
    end
    State.AutoTrick = enabled

    if enabled then
        Connections.AutoTrick = RunService.Heartbeat:Connect(function()
            if not State.AutoTrick then
                return
            end

            local actor = Actors.CurrentActors[LocalPlayer]
            local skating = actor
                and actor.ActorName == "Veeronica"
                and actor.State
                and actor.State.isSkating
            local highlight = actor and actor.Instances and actor.Instances.Sk8Highlight
            local ready = highlight and highlight.Adornee ~= nil

            if skating and ready then
                local now = os.clock()
                local cooldown = (actor.Config and actor.Config.Sk8TrickCooldown) or 1
                if now - LastAttempt >= math.max(cooldown, 0.2) then
                    LastAttempt = now
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    task.delay(0.03, function()
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                    end)
                end
            end
        end)
    elseif Connections.AutoTrick then
        Connections.AutoTrick:Disconnect()
        Connections.AutoTrick = nil
    end
end

function Survivors:Unload()
    for _, connection in pairs(Connections) do
        connection:Disconnect()
    end
    table.clear(Connections)
    State.AutoTrick = false
end

return Survivors
