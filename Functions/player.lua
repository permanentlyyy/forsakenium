local Player = {}

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local BASE_FOV = 70
local FOV_TAG = "FOVSetting"

local State = {
    FOV = nil
}

local function applyFOV(fov)
    local character = LocalPlayer.Character
    if not character then
        return
    end

    local multipliers = character:FindFirstChild("FOVMultipliers")
    if not multipliers then
        return
    end

    local tag = multipliers:FindFirstChild(FOV_TAG)

    if fov then
        if not tag then
            tag = Instance.new("NumberValue")
            tag.Name = FOV_TAG
            tag.Parent = multipliers
        end
        tag.Value = fov / BASE_FOV
    elseif tag then
        tag.Value = 1
    end
end

LocalPlayer.CharacterAdded:Connect(function(character)
    local multipliers = character:WaitForChild("FOVMultipliers", 10)
    if multipliers and State.FOV then
        applyFOV(State.FOV)
    end
end)

function Player:SetMaxZoom(value)
    LocalPlayer.CameraMaxZoomDistance = value
end

function Player:SetFOV(value)
    State.FOV = value
    applyFOV(value)
end

function Player:SetCameraNoclip(enabled)
    LocalPlayer.DevCameraOcclusionMode = enabled
        and Enum.DevCameraOcclusionMode.Invisible
        or Enum.DevCameraOcclusionMode.Zoom
end

return Player
