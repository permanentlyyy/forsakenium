local Player = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local Event = ReplicatedStorage.Modules.Network.Network.UnreliableRemoteEvent

local RETURN_RADIUS = 100
local STILL_TICKS = 3
local TICK_RATE = 0.1

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

local hitbox, stillTicks, lastPos = nil, 0, nil
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

local function grabHitbox(char)
    task.spawn(function()
        hitbox = char:WaitForChild("QueryHitbox", 10)
    end)
end

if LocalPlayer.Character then
    grabHitbox(LocalPlayer.Character)
end

table.insert(State.Connections, LocalPlayer.CharacterAdded:Connect(function(char)
    hitbox, stillTicks, lastPos = nil, 0, nil
    grabHitbox(char)
    task.delay(0.1, applyFootstepsMuted, char)
end))

task.spawn(function()
    while Running do
        task.wait(TICK_RATE)
        if State.Enabled then
            local ok = pcall(function()
                local char = LocalPlayer.Character
                if not char then
                    return
                end
                if not hitbox or not hitbox.Parent then
                    hitbox = char:FindFirstChild("QueryHitbox")
                end
                local hrp = char.PrimaryPart
                if not (hitbox and hrp) then
                    return
                end
                if (hitbox.Position - hrp.Position).Magnitude <= RETURN_RADIUS then
                    local still = hrp.AssemblyLinearVelocity.Magnitude < 1
                        and lastPos ~= nil
                        and (hrp.Position - lastPos).Magnitude < 0.1
                    lastPos = hrp.Position
                    stillTicks = still and (stillTicks + 1) or 0
                    if stillTicks >= STILL_TICKS then
                        Event:FireServer(1, { parkBuffer })
                        stillTicks, lastPos = 0, nil
                    end
                else
                    stillTicks, lastPos = 0, nil
                end
            end)
            if not ok then
                hitbox = nil
            end
        end
    end
end)

function Player:SetGodMode(enabled)
    if State.Enabled == enabled then
        return
    end
    State.Enabled = enabled
    stillTicks, lastPos = 0, nil

    if enabled then
        local char = LocalPlayer.Character
        local hrp = char and char.PrimaryPart
        if hrp and hrp.AssemblyLinearVelocity.Magnitude < 1 then
            Event:FireServer(1, { parkBuffer })
        end
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

table.insert(State.Connections, RunService.Heartbeat:Connect(function()
    if StaminaThreshold > 0 and Sprinting.IsSprinting and (Sprinting.Stamina or 0) <= StaminaThreshold then
        stopSprint()
    end

    if AlwaysSprintState.Enabled and not Sprinting.IsSprinting then
        local floor = StaminaThreshold > 0 and StaminaThreshold or (Sprinting.MinStamina or 0)
        if (Sprinting.Stamina or 0) > floor + 10 then
            startSprint()
        end
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

function Player:Unload()
    Running = false
    State.Enabled = false
    FootstepsState.Enabled = false
    stopInvisibility()
    applyFootstepsMuted(LocalPlayer.Character)
    for _, conn in ipairs(State.Connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    table.clear(State.Connections)
end

return Player
