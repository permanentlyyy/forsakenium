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
    GridOverride = false,
    GridSize = 7,
    PathEnabled = false,
    PathTransparency = 0.5,
}

local lastGame = nil

local originalStartGame = getgenv().__ForsakenGenStartOriginal
if not originalStartGame then
    originalStartGame = FlowGameManager.startGame
    getgenv().__ForsakenGenStartOriginal = originalStartGame
end

FlowGameManager.startGame = function(self, size, ...)
    if State.GridOverride then
        size = State.GridSize
    end
    return originalStartGame(self, size, ...)
end

local PATH_BIND = "ForsakeniumPathHighlighter"
local pathConnections = {}
local watchedState = nil

local function disconnectPathWatch()
    for _, connection in ipairs(pathConnections) do
        connection:Disconnect()
    end
    table.clear(pathConnections)
    watchedState = nil
end

local function applyCell(button, color)
    if button.Parent then
        button.BackgroundColor3 = color
        button.BackgroundTransparency = State.PathTransparency
    end
end

local function watchPuzzle(state)
    if state == watchedState or not state or not state.gridFrame then
        return
    end

    for _, connection in ipairs(pathConnections) do
        connection:Disconnect()
    end
    table.clear(pathConnections)
    watchedState = state

    for colorIndex, path in ipairs(state.Solution or {}) do
        local color = state.colors[colorIndex]
        if color then
            for _, position in ipairs(path) do
                local cell = state.gridFrame:FindFirstChild(position.row .. "-" .. position.col)
                local button = cell and cell:FindFirstChild("Button")
                if button then
                    applyCell(button, color)
                    table.insert(pathConnections, button:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
                        applyCell(button, color)
                    end))
                    table.insert(pathConnections, button:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
                        applyCell(button, color)
                    end))
                end
            end
        end
    end
end

pcall(function()
    RunService:UnbindFromRenderStep(PATH_BIND)
end)

RunService:BindToRenderStep(PATH_BIND, Enum.RenderPriority.Last.Value, function()
    if not State.PathEnabled then
        return
    end

    local state = FlowGameManager.activeGame
    if state ~= watchedState then
        watchPuzzle(state)
    end

    if state and state.gridFrame and state.gridFrame.Parent then
        for colorIndex, path in ipairs(state.Solution or {}) do
            local color = state.colors[colorIndex]
            if color then
                for _, position in ipairs(path) do
                    local cell = state.gridFrame:FindFirstChild(position.row .. "-" .. position.col)
                    local button = cell and cell:FindFirstChild("Button")
                    if button then
                        applyCell(button, color)
                    end
                end
            end
        end
    end
end)

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

function Generators:SetGridSizeOverride(enabled)
    State.GridOverride = enabled
end

function Generators:SetGridSize(value)
    State.GridSize = value
end

function Generators:SetShowPuzzlePath(enabled)
    State.PathEnabled = enabled
    if not enabled then
        disconnectPathWatch()
        local state = FlowGameManager.activeGame
        if state and state.gridFrame then
            pcall(function()
                state:updateGui()
            end)
        end
    end
end

function Generators:SetPuzzlePathTransparency(value)
    State.PathTransparency = value / 100
end

function Generators:Unload()
    running = false
    State.Enabled = false
    State.GridOverride = false
    State.PathEnabled = false
    FlowGameManager.startGame = getgenv().__ForsakenGenStartOriginal
    pcall(function()
        RunService:UnbindFromRenderStep(PATH_BIND)
    end)
    disconnectPathWatch()

    for _, conn in ipairs(connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    table.clear(connections)
end

return Generators
