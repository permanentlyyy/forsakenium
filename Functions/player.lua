local Player = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

local BASE_FOV = 70
local FOV_TAG = "FOVSetting"

local State = {
    FOV = nil,
    NoclipCam = false,
    EqualizedMovement = false,
    NoLandingSlowdown = false,
    Fullbright = false,
    NoFog = false
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

    if State.NoLandingSlowdown then
        character:SetAttribute("NoFallSlow", true)
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

function Player:SetEqualizedMovement(enabled)
    if enabled == State.EqualizedMovement then
        return
    end
    State.EqualizedMovement = enabled

    if enabled then
        Connections.DirectionalPenalty = RunService.RenderStepped:Connect(function()
            local character = LocalPlayer.Character
            local multipliers = character and character:FindFirstChild("SpeedMultipliers")
            local tag = multipliers and multipliers:FindFirstChild("DirectionalMovement")
            if tag then
                tag.Value = 1
            end
        end)
    elseif Connections.DirectionalPenalty then
        Connections.DirectionalPenalty:Disconnect()
        Connections.DirectionalPenalty = nil

        local character = LocalPlayer.Character
        local multipliers = character and character:FindFirstChild("SpeedMultipliers")
        local tag = multipliers and multipliers:FindFirstChild("DirectionalMovement")
        if tag then
            tag.Value = 1
        end
    end
end

function Player:SetNoLandingSlowdown(enabled)
    if enabled == State.NoLandingSlowdown then
        return
    end
    State.NoLandingSlowdown = enabled

    local character = LocalPlayer.Character
    if character then
        character:SetAttribute("NoFallSlow", enabled or nil)
    end
end

function Player:SetFullbright(enabled)
    if enabled == State.Fullbright then
        return
    end
    State.Fullbright = enabled

    if enabled then
        State.SavedAmbient = Lighting.Ambient
        State.SavedOutdoorAmbient = Lighting.OutdoorAmbient
        State.SavedBrightness = Lighting.Brightness

        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
    elseif State.SavedAmbient then
        Lighting.Ambient = State.SavedAmbient
        Lighting.OutdoorAmbient = State.SavedOutdoorAmbient
        Lighting.Brightness = State.SavedBrightness
        State.SavedAmbient = nil
        State.SavedOutdoorAmbient = nil
        State.SavedBrightness = nil
    end
end

function Player:SetNoFog(enabled)
    if enabled == State.NoFog then
        return
    end
    State.NoFog = enabled

    if enabled then
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere then
            State.SavedAtmosphereDensity = atmosphere.Density
            State.SavedAtmosphereHaze = atmosphere.Haze
        end
        State.SavedFogEnd = Lighting.FogEnd
        State.SavedFogStart = Lighting.FogStart

        Connections.NoFogPin = RunService.RenderStepped:Connect(function()
            local current = Lighting:FindFirstChildOfClass("Atmosphere")
            if current then
                current.Density = 0
                current.Haze = 0
            end
            Lighting.FogEnd = 100000
        end)
    else
        if Connections.NoFogPin then
            Connections.NoFogPin:Disconnect()
            Connections.NoFogPin = nil
        end

        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere and State.SavedAtmosphereDensity then
            atmosphere.Density = State.SavedAtmosphereDensity
            atmosphere.Haze = State.SavedAtmosphereHaze
            State.SavedAtmosphereDensity = nil
            State.SavedAtmosphereHaze = nil
        end
        if State.SavedFogEnd then
            Lighting.FogEnd = State.SavedFogEnd
            Lighting.FogStart = State.SavedFogStart
            State.SavedFogEnd = nil
            State.SavedFogStart = nil
        end
    end
end

function Player:Unload()
    if State.NoclipCam then
        State.NoclipCam = false
        swapPopperConstants()
    end

    if State.Fullbright then
        Player:SetFullbright(false)
    end

    if State.NoFog then
        Player:SetNoFog(false)
    end

    for _, connection in pairs(Connections) do
        connection:Disconnect()
    end
    table.clear(Connections)
end

State.NoclipCam = isPopperPatched()

return Player
