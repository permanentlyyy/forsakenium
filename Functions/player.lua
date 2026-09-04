local Player = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local Event = ReplicatedStorage.Modules.Network.Network.UnreliableRemoteEvent
local Network = require(ReplicatedStorage.Modules.Network.Network)

local PARK_BYTES = { 10, 75, 0, 0, 0, 123, 34, 109, 34, 58, 110, 117, 108, 108, 44, 34, 116, 34, 58, 34, 98, 117, 102, 102, 101, 114, 34, 44, 34, 98, 97, 115, 101, 54, 52, 34, 58, 34, 65, 65, 65, 65, 65, 65, 65, 65, 101, 115, 81, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 80, 68, 89, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 34, 125 }

local env = (typeof(getgenv) == "function" and getgenv()) or _G

local State = env.__ForsakenParkState
if not State then
    State = { Enabled = false, Hooked = false }
    env.__ForsakenParkState = State
end

State.Enabled = false

if State.Connections then
    for _, conn in ipairs(State.Connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
end
State.Connections = {}

local parkBuffer = (function(bytes)
    local b = buffer.create(#bytes)
    for i = 1, #bytes do
        buffer.writeu8(b, i - 1, bytes[i])
    end
    return b
end)(PARK_BYTES)

local function fireParkPacket()
    pcall(function()
        Event:FireServer(1, { parkBuffer })
    end)
end

local function isParkPacket(buf)
    if typeof(buf) ~= "buffer" or buffer.len(buf) ~= #PARK_BYTES then
        return false
    end
    for i = 1, #PARK_BYTES do
        if buffer.readu8(buf, i - 1) ~= PARK_BYTES[i] then
            return false
        end
    end
    return true
end

if not State.Hooked then
    State.Hooked = true
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if State.Enabled and self == Event and (method == "FireServer" or method == "fireServer") then
            local args = { ... }
            if args[1] == 1 and typeof(args[2]) == "table" and isParkPacket(args[2][1]) then
                return oldNamecall(self, ...)
            end
            return
        end
        return oldNamecall(self, ...)
    end)
end

local Running = true

local FootstepsState = {
    Enabled = false
}

local function applyFootstepsMuted(char)
    if not char then
        return
    end
    if FootstepsState.Enabled then
        char:SetAttribute("FootstepsMuted", true)
    else
        char:SetAttribute("FootstepsMuted", nil)
    end
end

function Player:SetGodMode(enabled)
    if State.Enabled == enabled then
        return
    end
    State.Enabled = enabled

    if enabled then
        fireParkPacket()
    end
end

local INVIS_ANIMATION_ID = "rbxassetid://75804462760596"

local InvisState = {
    Desired = false,
    Active = false,
    Track = nil,
    Animation = nil,
    Watchdog = nil
}

local function stopInvisibility()
    if not InvisState.Active then
        return
    end
    InvisState.Active = false

    if InvisState.Track then
        pcall(function()
            InvisState.Track:Stop()
            if InvisState.Track.Destroy then
                InvisState.Track:Destroy()
            end
        end)
        InvisState.Track = nil
    end

    if InvisState.Animation then
        pcall(function()
            InvisState.Animation:Destroy()
        end)
        InvisState.Animation = nil
    end

    if InvisState.Watchdog then
        InvisState.Watchdog:Disconnect()
        InvisState.Watchdog = nil
    end
end

local function setupInvisibility(character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not humanoid then
        warn("[Forsakenium] Invisibility: no humanoid")
        return
    end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    local animation = Instance.new("Animation")
    animation.AnimationId = INVIS_ANIMATION_ID

    local ok, track = pcall(function()
        return animator:LoadAnimation(animation)
    end)
    if not ok or not track then
        warn("[Forsakenium] Invisibility: load failed " .. tostring(track))
        return
    end

    track.Looped = true
    track.Priority = Enum.AnimationPriority.Action4
    track:Play()
    track:AdjustSpeed(0)

    InvisState.Track = track
    InvisState.Animation = animation
    InvisState.Active = true

    InvisState.Watchdog = RunService.Heartbeat:Connect(function()
        if InvisState.Track and not InvisState.Track.IsPlaying then
            InvisState.Track:Play()
            InvisState.Track:AdjustSpeed(0)
        end
    end)
end

local function isInRound()
    local char = LocalPlayer.Character
    local parent = char and char.Parent
    if not parent then
        return false
    end
    local name = parent.Name
    return name == "Survivors" or name == "Killers"
end

function Player:SetInvisibility(enabled)
    InvisState.Desired = enabled

    if not enabled then
        stopInvisibility()
        return
    end

    if isInRound() then
        local char = LocalPlayer.Character
        if char then
            setupInvisibility(char)
        end
    end
end

local Sprinting = require(ReplicatedStorage.Systems.Character.Game.Sprinting)

local InfStaminaState = { Enabled = false }
local LegitViewState = { Enabled = false, Screen = nil, Label = nil }

local virtual = 0
local virtualTimer = 0
local virtualPenalty = false
local virtualExhausted = false
local baseline = 0
local prevCap = nil
local capBaseVirtual = nil

local function virtualMax()
    return Sprinting.StaminaCap or Sprinting.MaxStamina or 100
end

local function virtualMin()
    return Sprinting.MinStamina or 0
end

local originalGrantStamina = env.__ForsakenGrantOriginal
if not originalGrantStamina then
    originalGrantStamina = function(amount)
        Sprinting.Stamina = math.min((Sprinting.Stamina or 0) + amount, Sprinting.MaxStamina)
    end
    env.__ForsakenGrantOriginal = originalGrantStamina
end

local wrappedGrantStamina = function(amount)
    originalGrantStamina(amount)
    virtual = math.min(virtual + amount, virtualMax())
end

pcall(function()
    Network.SetConnection("GrantStamina", "REMOTE_EVENT", wrappedGrantStamina)
end)

local AlwaysSprintState = {
    Enabled = false
}

local StaminaThreshold = 0

local function startSprint()
    if not Sprinting.CanSprint or Sprinting.IsSprinting then
        return
    end
    local floor = StaminaThreshold > 0 and StaminaThreshold or (Sprinting.MinStamina or 0)
    if (Sprinting.Stamina or 0) <= floor then
        return
    end
    Sprinting.IsSprinting = true
    if Sprinting.__sprintedEvent then
        Sprinting.__sprintedEvent:Fire(true)
    end
    pcall(function()
        Sprinting:Toggle(true)
    end)
end

local function stopSprint()
    if not Sprinting.IsSprinting then
        return
    end
    Sprinting.IsSprinting = false
    if Sprinting.__sprintedEvent then
        Sprinting.__sprintedEvent:Fire(false)
    end
    pcall(function()
        Sprinting:Toggle(false)
    end)
end

function Player:SetAlwaysSprint(enabled)
    if AlwaysSprintState.Enabled == enabled then
        return
    end
    AlwaysSprintState.Enabled = enabled

    if enabled then
        startSprint()
    else
        stopSprint()
    end
end

table.insert(State.Connections, RunService.Heartbeat:Connect(function(dt)
    if StaminaThreshold > 0 and Sprinting.IsSprinting and (Sprinting.Stamina or 0) <= StaminaThreshold then
        stopSprint()
    end

    if AlwaysSprintState.Enabled and not Sprinting.IsSprinting then
        local floor = StaminaThreshold > 0 and StaminaThreshold or (Sprinting.MinStamina or 0)
        if (Sprinting.Stamina or 0) > floor then
            startSprint()
        end
    end

    local maxStamina = virtualMax()
    local minStamina = virtualMin()
    local realStamina = Sprinting.Stamina or maxStamina
    local frozen = Sprinting:IsStaminaFrozen()

    if InfStaminaState.Enabled then
        Sprinting.Stamina = maxStamina
        baseline = maxStamina
    end

    if not LegitViewState.Enabled then
        return
    end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    local realDraining = not frozen
        and char ~= nil
        and char.Parent ~= nil
        and root ~= nil
        and not root.Anchored
        and Sprinting.IsSprinting
        and realStamina > minStamina
        and root.AssemblyLinearVelocity.Magnitude > 0.4
        and Sprinting.CanSprint
        and not Sprinting.StaminaLossDisabled
        and char.Parent.Name ~= "Spectating"

    local expectedReal = baseline + (realDraining and -(Sprinting.StaminaLoss or 10) * dt or 0)
    local external = realStamina - expectedReal

    if math.abs(external) > 0.005 then
        virtual = math.clamp(virtual + external, minStamina, maxStamina)
    end

    local cap = Sprinting.StaminaCap
    if cap ~= prevCap then
        prevCap = cap
        if cap ~= nil then
            capBaseVirtual = virtual + math.max(cap - realStamina, 0)
        else
            capBaseVirtual = nil
        end
    end

    if not InfStaminaState.Enabled then
        virtual = realStamina
        baseline = realStamina
    end

    virtual = math.clamp(virtual, minStamina, maxStamina)

    if frozen then
        if LegitViewState.Label then
            LegitViewState.Label.Text = tostring(math.round(virtual)) .. "/" .. tostring(math.round(maxStamina))
        end
        return
    end

    if not char or not char.Parent then
        return
    end

    local canDrain = root ~= nil
        and not root.Anchored
        and Sprinting.IsSprinting
        and not virtualExhausted
        and virtual > minStamina
        and root.AssemblyLinearVelocity.Magnitude > 0.4
        and Sprinting.CanSprint
        and not Sprinting.StaminaLossDisabled
        and char.Parent.Name ~= "Spectating"

    if canDrain then
        virtualTimer = math.clamp(virtualTimer + dt * 0.05, 0.2, 2)
        virtual = math.clamp(virtual - (Sprinting.StaminaLoss or 10) * dt, minStamina, maxStamina)

        if virtual <= minStamina then
            virtualExhausted = true
            virtualTimer = 2
            virtualPenalty = true
        end
    else
        if not Sprinting.IsSprinting then
            virtualExhausted = false
        end

        local timerFloor = realDraining and 0 or (Sprinting.timeUntilStaminaRecovers or 0)
        virtualTimer = math.max(virtualTimer - dt, timerFloor)

        if virtualTimer <= 0 then
            virtualPenalty = false
        end

        if virtualTimer <= 0
            and not virtualPenalty
            and not realDraining
            and not char:GetAttribute("AbilityStaminaOverride")
            and not char:GetAttribute("StaminaPenaltyActive")
        then
            local regenCeiling = capBaseVirtual or maxStamina
            if regenCeiling > maxStamina then
                regenCeiling = maxStamina
            end
            virtual = math.clamp(virtual + (Sprinting.StaminaGain or 20) * dt, minStamina, regenCeiling)
        end
    end

    if LegitViewState.Label then
        LegitViewState.Label.Text = tostring(math.round(virtual)) .. "/" .. tostring(math.round(maxStamina))
        LegitViewState.Label.TextColor3 = virtual / maxStamina < 0.25
            and Color3.fromRGB(255, 105, 105)
            or Color3.fromRGB(220, 230, 240)
    end
end))

table.insert(State.Connections, LocalPlayer.CharacterAdded:Connect(function(char)
    task.delay(0.1, applyFootstepsMuted, char)

    virtual = virtualMax()
    virtualTimer = 0
    virtualPenalty = false
    virtualExhausted = false

    if State.Enabled then
        task.delay(1, fireParkPacket)
    end
end))

task.spawn(function()
    while Running do
        task.wait(0.25)
        pcall(function()
            local inRound = isInRound()

            if InvisState.Desired and inRound and not InvisState.Active then
                local char = LocalPlayer.Character
                if char then
                    setupInvisibility(char)
                end
            elseif (not InvisState.Desired or not inRound) and InvisState.Active then
                stopInvisibility()
            end
        end)
    end
end)

function Player:SetSilentFootsteps(enabled)
    if FootstepsState.Enabled == enabled then
        return
    end
    FootstepsState.Enabled = enabled
    applyFootstepsMuted(LocalPlayer.Character)
end

function Player:SetStaminaManagement(threshold)
    StaminaThreshold = threshold or 0

    if StaminaThreshold > 0 and Sprinting.IsSprinting and (Sprinting.Stamina or 0) <= StaminaThreshold then
        stopSprint()
    end
end

function Player:SetInfiniteStamina(enabled)
    InfStaminaState.Enabled = enabled
end

function Player:SetShowLegitStaminaView(enabled)
    LegitViewState.Enabled = enabled

    if enabled then
        local gui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
        if not gui then
            return
        end

        local screen = Instance.new("ScreenGui")
        screen.Name = "ForsakeniumSecondaryStamina"
        screen.ResetOnSpawn = false
        screen.IgnoreGuiInset = true
        screen.DisplayOrder = 10000
        screen.Parent = gui

        local number = Instance.new("TextLabel")
        number.Name = "SecondaryStaminaNumber"
        number.AnchorPoint = Vector2.new(0.5, 0.5)
        number.Position = UDim2.fromScale(0.5, 0.5)
        number.Size = UDim2.new(0, 220, 0, 64)
        number.BackgroundTransparency = 1
        number.Font = Enum.Font.GothamBold
        number.TextColor3 = Color3.fromRGB(220, 230, 240)
        number.TextStrokeColor3 = Color3.fromRGB(20, 24, 32)
        number.TextStrokeTransparency = 0.25
        number.TextSize = 28
        number.TextXAlignment = Enum.TextXAlignment.Center
        number.TextYAlignment = Enum.TextYAlignment.Center
        number.Parent = screen

        LegitViewState.Screen = screen
        LegitViewState.Label = number

        virtual = Sprinting.Stamina or virtualMax()
        virtualTimer = Sprinting.timeUntilStaminaRecovers or 0
    else
        if LegitViewState.Screen then
            LegitViewState.Screen:Destroy()
        end
        LegitViewState.Screen = nil
        LegitViewState.Label = nil
    end
end

function Player:Unload()
    Running = false
    State.Enabled = false
    InfStaminaState.Enabled = false
    FootstepsState.Enabled = false
    stopInvisibility()
    applyFootstepsMuted(LocalPlayer.Character)

    if LegitViewState.Screen then
        LegitViewState.Screen:Destroy()
    end
    LegitViewState.Screen = nil
    LegitViewState.Label = nil

    pcall(function()
        Network.SetConnection("GrantStamina", "REMOTE_EVENT", originalGrantStamina)
    end)

    for _, conn in ipairs(State.Connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    table.clear(State.Connections)
end

return Player
