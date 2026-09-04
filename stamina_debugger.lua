if _G.__StaminaDebuggerCleanup then
    pcall(_G.__StaminaDebuggerCleanup)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")
local sprinting = require(game:GetService("ReplicatedStorage").Systems.Character.Game.Sprinting)

local connections = {}
local dead = false

local screen = Instance.new("ScreenGui")
screen.Name = "StaminaDebuggerUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.DisplayOrder = 10001
screen.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "DebuggerPanel"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0.5, 44)
panel.Size = UDim2.new(0, 220, 0, 86)
panel.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
panel.BackgroundTransparency = 0.35
panel.BorderSizePixel = 0
panel.Parent = screen

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = panel

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 2)
layout.Parent = panel

local function makeLabel(name, color)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = UDim2.new(1, -12, 0, 24)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = color
    label.TextStrokeColor3 = Color3.fromRGB(20, 24, 32)
    label.TextStrokeTransparency = 0.4
    label.TextSize = 16
    label.Parent = panel
    return label
end

local realLabel = makeLabel("Real", Color3.fromRGB(140, 200, 255))
local secondaryLabel = makeLabel("Secondary", Color3.fromRGB(255, 220, 130))
local diffLabel = makeLabel("Diff", Color3.fromRGB(170, 255, 170))

local function getSecondary()
    local ui = gui:FindFirstChild("SecondaryStaminaUI")
    local label = ui and ui:FindFirstChild("SecondaryStaminaNumber")
    if not label then
        return nil
    end
    return tonumber(tostring(label.Text):match("^(%-?%d+)"))
end

table.insert(connections, RunService.Heartbeat:Connect(function()
    if dead then
        return
    end

    local real = sprinting.Stamina
    local secondary = getSecondary()

    realLabel.Text = "Real: " .. (real and string.format("%.2f", real) or "N/A")
    secondaryLabel.Text = "Secondary: " .. (secondary and tostring(secondary) or "N/A")

    if real and secondary then
        local diff = secondary - real
        diffLabel.Text = "Diff: " .. string.format("%+.2f", diff)
        diffLabel.TextColor3 = math.abs(diff) < 0.5
            and Color3.fromRGB(170, 255, 170)
            or Color3.fromRGB(255, 105, 105)
    else
        diffLabel.Text = "Diff: N/A"
    end
end))

_G.__StaminaDebuggerCleanup = function()
    dead = true

    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end

    screen:Destroy()
    _G.__StaminaDebuggerCleanup = nil
end
