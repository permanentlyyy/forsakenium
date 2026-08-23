local Player = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

local Connections = {}
local State = {
    WalkSpeed = 16,
    JumpPower = 50
}

local function getHumanoid()
    local character = LocalPlayer.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

LocalPlayer.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.WalkSpeed = State.WalkSpeed
    humanoid.UseJumpPower = true
    humanoid.JumpPower = State.JumpPower
end)

function Player:SetMaxZoom(value)
    LocalPlayer.CameraMaxZoomDistance = value
end

function Player:SetWalkSpeed(value)
    State.WalkSpeed = value
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.WalkSpeed = value
    end
end

function Player:SetJumpPower(value)
    State.JumpPower = value
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = value
    end
end

function Player:SetInfiniteJump(enabled)
    if enabled then
        Connections.InfiniteJump = UserInputService.JumpRequest:Connect(function()
            local humanoid = getHumanoid()
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    elseif Connections.InfiniteJump then
        Connections.InfiniteJump:Disconnect()
        Connections.InfiniteJump = nil
    end
end

function Player:SetNoclip(enabled)
    if enabled then
        Connections.Noclip = RunService.Stepped:Connect(function()
            local character = LocalPlayer.Character
            if not character then
                return
            end
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    elseif Connections.Noclip then
        Connections.Noclip:Disconnect()
        Connections.Noclip = nil
    end
end

function Player:SetAntiAFK(enabled)
    if enabled then
        Connections.AntiAFK = LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    elseif Connections.AntiAFK then
        Connections.AntiAFK:Disconnect()
        Connections.AntiAFK = nil
    end
end

function Player:ResetCharacter()
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.Health = 0
    end
end

return Player
