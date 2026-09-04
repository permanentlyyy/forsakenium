local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FlowGameManager = require(ReplicatedStorage.Modules.Minigames.FlowGameManager)

local running = true
local connections = {}

local State = {
    Enabled = false,
    Speed = 4.5,
    Random = false,
    RandomMax = 10,
    RandomMin = 1.5,
}

local lastGame = nil

table.insert(connections, RunService.Heartbeat:Connect(function()
    if not State.Enabled then
        return
    end

    local activeGame = FlowGameManager.activeGame
    if activeGame and activeGame ~= lastGame and not activeGame.gameEnded then
        lastGame = activeGame

        local delay = State.Speed
        if State.Random then
            local min = math.min(State.RandomMin, State.RandomMax)
            local max = math.max(State.RandomMin, State.RandomMax)
            delay = min + (max - min) * math.random()
        end

        task.delay(delay, function()
            if running and State.Enabled and FlowGameManager.activeGame == activeGame and not activeGame.gameEnded then
                pcall(function()
                    activeGame:EndGame(true)
                end)
            end
        end)
    end
end))

local Generators = {}

function Generators:SetAutoSolve(enabled)
    State.Enabled = enabled
end

function Generators:SetSolveSpeed(value)
    State.Speed = value
end

function Generators:SetRandomSolveSpeed(enabled)
    State.Random = enabled
end

function Generators:SetRandomSolveMax(value)
    State.RandomMax = value
end

function Generators:SetRandomSolveMin(value)
    State.RandomMin = value
end

function Generators:Unload()
    running = false
    State.Enabled = false

    for _, conn in ipairs(connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    table.clear(connections)
end

return Generators
