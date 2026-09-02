local Player = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local NetworkFolder = ReplicatedStorage.Modules.Network.Network
local TargetEvent = NetworkFolder.UnreliableRemoteEvent
local RoundRemote = NetworkFolder.RemoteEvent

local AllowedBytes = { 10, 75, 0, 0, 0, 123, 34, 109, 34, 58, 110, 117, 108, 108, 44, 34, 116, 34, 58, 34, 98, 117, 102, 102, 101, 114, 34, 44, 34, 98, 97, 115, 101, 54, 52, 34, 58, 34, 65, 65, 65, 65, 65, 65, 65, 65, 101, 115, 81, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 80, 68, 89, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 34, 125 }

local env = (typeof(getgenv) == "function" and getgenv()) or _G

local State = env.__ForsakenPosPinnerState
if not State then
    State = { Enabled = false, Hooked = false }
    env.__ForsakenPosPinnerState = State
end

if State.Connections then
    for _, conn in ipairs(State.Connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
end
State.Connections = {}

local function buildPacket()
    local b = buffer.create(#AllowedBytes)
    for i = 1, #AllowedBytes do
        buffer.writeu8(b, i - 1, AllowedBytes[i])
    end
    return b
end

local PacketBuffer = buildPacket()

local function isBufferValid(buf)
    if typeof(buf) ~= "buffer" then
        return false
    end
    if buffer.len(buf) ~= #AllowedBytes then
        return false
    end
    for i = 1, #AllowedBytes do
        if buffer.readu8(buf, i - 1) ~= AllowedBytes[i] then
            return false
        end
    end
    return true
end

local lastFire = 0
local FREEZE_TIME = 1
local UNFREEZE_TIME = 1

local function stopVelocity()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and char.Parent then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

local function isSurvivorOrKiller()
    local char = LocalPlayer.Character
    local parent = char and char.Parent
    if not parent then
        return false
    end
    local name = parent.Name
    return name == "Survivors" or name == "Killers"
end

local function firePositionPacket(force)
    if not State.Enabled then
        return
    end
    if not isSurvivorOrKiller() then
        return
    end
    local now = os.clock()
    if not force and now - lastFire < 0.5 then
        return
    end
    lastFire = now

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if hrp and char.Parent then
        hrp.Anchored = true
        stopVelocity()
        task.wait(FREEZE_TIME)

        if not State.Enabled then
            if hrp.Parent then
                hrp.Anchored = false
            end
            return
        end

        TargetEvent:FireServer(1, { PacketBuffer })
        task.wait(UNFREEZE_TIME)

        if hrp.Parent then
            hrp.Anchored = false
        end
    end
end

if not State.Hooked then
    State.Hooked = true
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()

        if State.Enabled and (method == "FireServer" or method == "fireServer") and self == TargetEvent then
            local args = { ... }
            local arg1 = args[1]
            local arg2 = args[2]

            if arg1 == 1 and typeof(arg2) == "table" and isBufferValid(arg2[1]) then
                return oldNamecall(self, ...)
            end

            return
        end

        return oldNamecall(self, ...)
    end)
end

table.insert(State.Connections, RoundRemote.OnClientEvent:Connect(function(name, packed)
    if not State.Enabled then
        return
    end
    if name ~= "HandleGamemode" or typeof(packed) ~= "table" then
        return
    end

    local b = packed[1]
    if typeof(b) ~= "buffer" or buffer.len(b) < 9 then
        return
    end
    if buffer.readu8(b, 0) ~= 3 then
        return
    end
    if buffer.readu32(b, 1) ~= 4 then
        return
    end
    if buffer.readstring(b, 5, 4) ~= "Init" then
        return
    end

    task.delay(3, function()
        if State.Enabled then
            firePositionPacket(true)
        end
    end)
end))

table.insert(State.Connections, LocalPlayer.CharacterAdded:Connect(function(char)
    if not State.Enabled then
        return
    end
    char:WaitForChild("HumanoidRootPart", 5)
    local deadline = os.clock() + 5
    while State.Enabled and os.clock() < deadline and not isSurvivorOrKiller() do
        task.wait(0.25)
    end
    firePositionPacket(true)
end))

function Player:SetInvincible(enabled)
    if State.Enabled == enabled then
        return
    end
    State.Enabled = enabled

    if enabled then
        if isSurvivorOrKiller() then
            firePositionPacket(true)
        end
    else
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and char.Parent then
            hrp.Anchored = false
        end
    end
end

function Player:Unload()
    Player:SetInvincible(false)
    for _, conn in ipairs(State.Connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    table.clear(State.Connections)
end

return Player
