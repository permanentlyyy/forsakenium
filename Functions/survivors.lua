local Survivors = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local TRICK_READY_FILL = Color3.fromRGB(241, 85, 255)
local COLOR_TOLERANCE = 0.02

local State = {
    AutoTrick = false
}

local Connections = {}
local LastAttempt = 0

local function colorsMatch(a, b)
    return math.abs(a.R - b.R) < COLOR_TOLERANCE
        and math.abs(a.G - b.G) < COLOR_TOLERANCE
        and math.abs(a.B - b.B) < COLOR_TOLERANCE
end

local function collectHighlights(highlights)
    local assets = ReplicatedStorage:FindFirstChild("Assets")
    local survivors = assets and assets:FindFirstChild("Survivors")
    local veeronica = survivors and survivors:FindFirstChild("Veeronica")
    local behavior = veeronica and veeronica:FindFirstChild("Behavior")

    if behavior then
        local highlight = behavior:FindFirstChildOfClass("Highlight")
        if highlight then
            table.insert(highlights, highlight)
        end
    end

    local character = LocalPlayer.Character
    if character then
        for _, descendant in ipairs(character:GetDescendants()) do
            if descendant:IsA("Highlight") then
                table.insert(highlights, descendant)
            end
        end
    end
end

local function isTrickReady()
    local highlights = {}
    collectHighlights(highlights)

    for _, highlight in ipairs(highlights) do
        if colorsMatch(highlight.FillColor, TRICK_READY_FILL) then
            return true
        end
    end

    return false
end

local function fireTrickInput()
    local ok = pcall(function()
        ContextActionService:CallFunction("TrickInput", Enum.UserInputState.Begin)
    end)
    if not ok then
        return
    end

    task.delay(0.12, function()
        pcall(function()
            ContextActionService:CallFunction("TrickInput", Enum.UserInputState.End)
        end)
    end)
end

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

            if os.clock() - LastAttempt < 0.5 then
                return
            end

            if isTrickReady() then
                LastAttempt = os.clock()
                fireTrickInput()
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
