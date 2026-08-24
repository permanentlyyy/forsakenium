local Player = {}

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local BASE_FOV = 70
local FOV_TAG = "FOVSetting"

local State = {
    FOV = nil,
    NoclipCam = false
}

local Connections = {}

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

table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(character)
    local multipliers = character:WaitForChild("FOVMultipliers", 10)
    if multipliers and State.FOV then
        applyFOV(State.FOV)
    end
end))

function Player:SetMaxZoom(value)
    LocalPlayer.CameraMaxZoomDistance = value
end

function Player:SetFOV(value)
    State.FOV = value
    applyFOV(value)
end

function Player:SetCameraNoclip(enabled)
    if enabled == State.NoclipCam then
        return false
    end
    State.NoclipCam = enabled

    local sc = (debug and debug.setconstant) or setconstant
    local gc = (debug and debug.getconstants) or getconstants

    if not sc or not gc or not getgc then
        return false
    end

    local pop = LocalPlayer.PlayerScripts.PlayerModule.CameraModule.ZoomController.Popper
    for _, v in getgc() do
        if type(v) == "function" then
            local ok, env = pcall(getfenv, v)
            if ok and rawget(env, "script") == pop then
                for i, v1 in pairs(gc(v)) do
                    if tonumber(v1) == 0.25 then
                        sc(v, i, 0)
                    elseif tonumber(v1) == 0 then
                        sc(v, i, 0.25)
                    end
                end
            end
        end
    end

    return true
end

function Player:Unload()
    for _, connection in ipairs(Connections) do
        connection:Disconnect()
    end
    table.clear(Connections)
end

return Player
