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

local function collectPopperEntries()
    local gc = (debug and debug.getconstants) or getconstants
    if not gc or not getgc then
        return nil
    end

    local pop = LocalPlayer.PlayerScripts.PlayerModule.CameraModule.ZoomController.Popper
    local entries = {}

    for _, v in getgc() do
        if type(v) == "function" then
            local ok, env = pcall(getfenv, v)
            if ok and rawget(env, "script") == pop then
                table.insert(entries, {
                    fn = v,
                    constants = gc(v)
                })
            end
        end
    end

    return entries
end

local function swapPopperConstants()
    local sc = (debug and debug.setconstant) or setconstant
    if not sc then
        return false
    end

    local entries = collectPopperEntries()
    if not entries or #entries == 0 then
        return false
    end

    for _, entry in ipairs(entries) do
        for i, v in pairs(entry.constants) do
            if tonumber(v) == 0.25 then
                sc(entry.fn, i, 0)
            elseif tonumber(v) == 0 then
                sc(entry.fn, i, 0.25)
            end
        end
    end

    return true
end

local function isPopperPatched()
    local entries = collectPopperEntries()
    if not entries or #entries == 0 then
        return false
    end

    local sawOriginal = false
    local sawSwapped = false

    for _, entry in ipairs(entries) do
        for _, v in pairs(entry.constants) do
            if tonumber(v) == 0.25 then
                sawOriginal = true
            elseif tonumber(v) == 0 then
                sawSwapped = true
            end
        end
    end

    return not sawOriginal and sawSwapped
end

function Player:SetMaxZoom(value)
    LocalPlayer.CameraMaxZoomDistance = value
end

function Player:SetFOV(value)
    State.FOV = value
    applyFOV(value)
end

function Player:IsCameraNoclip()
    return State.NoclipCam
end

function Player:SetCameraNoclip(enabled)
    if enabled == State.NoclipCam then
        return false
    end

    if not swapPopperConstants() then
        return false
    end

    State.NoclipCam = enabled
    return true
end

function Player:Unload()
    if State.NoclipCam then
        State.NoclipCam = false
        swapPopperConstants()
    end

    for _, connection in ipairs(Connections) do
        connection:Disconnect()
    end
    table.clear(Connections)
end

State.NoclipCam = isPopperPatched()

return Player
