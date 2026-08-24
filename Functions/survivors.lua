local Survivors = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local TRICK_READY_FILL = Color3.fromRGB(241, 85, 255)
local COLOR_TOLERANCE = 0.02
local WALL_DISTANCE = 11

local State = {
    AutoTrick = false
}

local Connections = {}
local LastAttempt = 0
local VirtualInputManager = (function()
    local ok, service = pcall(game.GetService, game, "VirtualInputManager")
    return ok and service or nil
end)()

local function colorsMatch(a, b)
    return math.abs(a.R - b.R) < COLOR_TOLERANCE
        and math.abs(a.G - b.G) < COLOR_TOLERANCE
        and math.abs(a.B - b.B) < COLOR_TOLERANCE
end

local function getTrickHighlight()
    local assets = ReplicatedStorage:FindFirstChild("Assets")
    local survivors = assets and assets:FindFirstChild("Survivors")
    local veeronica = survivors and survivors:FindFirstChild("Veeronica")
    local behavior = veeronica and veeronica:FindFirstChild("Behavior")

    if behavior then
        local highlight = behavior:FindFirstChildOfClass("Highlight")
        if highlight then
            return highlight
        end
    end

    local character = LocalPlayer.Character
    if character then
        for _, descendant in ipairs(character:GetDescendants()) do
            if descendant:IsA("Highlight") then
                return descendant
            end
        end
    end

    return nil
end

local function isTrickReady()
    local highlight = getTrickHighlight()
    return highlight ~= nil and colorsMatch(highlight.FillColor, TRICK_READY_FILL)
end

local function wallAhead()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return false
    end

    local velocity = root.AssemblyLinearVelocity
    local horizontal = Vector3.new(velocity.X, 0, velocity.Z)
    local direction = horizontal.Magnitude > 4 and horizontal.Unit or root.CFrame.LookVector

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}

    local result = workspace:Raycast(root.Position, direction * WALL_DISTANCE, params)
    if not result then
        return false
    end

    return math.abs(result.Normal:Dot(Vector3.new(0, 1, 0))) < 0.2
end

local function pressSpace()
    if VirtualInputManager then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, nil)
        task.delay(0.1, function()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, nil)
        end)
        return true
    end

    return pcall(function()
        ContextActionService:CallFunction("TrickInput", Enum.UserInputState.Begin)
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

            if os.clock() - LastAttempt < 0.35 then
                return
            end

            if isTrickReady() and wallAhead() then
                LastAttempt = os.clock()
                pressSpace()
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
