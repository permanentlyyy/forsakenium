local Survivors = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Actors = require(game.ReplicatedStorage.Modules.Gameplay.Actors)

local LocalPlayer = Players.LocalPlayer

local State = {
    AutoTrick = false,
    Sk8Control = false,
    WasSkating = false
}

local Connections = {}
local LastAttempt = 0
local PatchedPoints = {}

local function getBehavior()
    local assets = ReplicatedStorage:FindFirstChild("Assets")
    local survivors = assets and assets:FindFirstChild("Survivors")
    local veeronica = survivors and survivors:FindFirstChild("Veeronica")
    return veeronica and veeronica:FindFirstChild("Behavior")
end

local function restorePatches()
    for _, point in ipairs(PatchedPoints) do
        pcall(debug.setconstant, point.fn, point.index, 3)
    end
    table.clear(PatchedPoints)
end

local function applyTurnPatch(channel)
    restorePatches()

    if channel == 3 or not (debug and debug.setconstant and debug.getconstants and getgc) then
        return
    end

    local behavior = getBehavior()
    if not behavior then
        return
    end

    for _, fn in getgc() do
        if type(fn) == "function" then
            local ok, env = pcall(getfenv, fn)
            if ok and rawget(env, "script") == behavior then
                local okC, constants = pcall(debug.getconstants, fn)
                if okC and type(constants) == "table" then
                    local has1, has2, has3 = false, false, false
                    for _, c in ipairs(constants) do
                        if c == 1 then
                            has1 = true
                        elseif c == 2 then
                            has2 = true
                        elseif c == 3 then
                            has3 = true
                        end
                    end

                    if has1 and has2 and has3 then
                        for i, c in ipairs(constants) do
                            if c == 3 then
                                if pcall(debug.setconstant, fn, i, channel) then
                                    table.insert(PatchedPoints, {
                                        fn = fn,
                                        index = i
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end
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

            local actor = Actors.CurrentActors[LocalPlayer]
            local skating = actor
                and actor.ActorName == "Veeronica"
                and actor.State
                and actor.State.isSkating
            local highlight = actor and actor.Instances and actor.Instances.Sk8Highlight
            local ready = highlight and highlight.Adornee ~= nil

            if skating and ready then
                local now = os.clock()
                local cooldown = (actor.Config and actor.Config.Sk8TrickCooldown) or 1
                if now - LastAttempt >= math.max(cooldown, 0.2) then
                    LastAttempt = now
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    task.delay(0.03, function()
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                    end)
                end
            end
        end)
    elseif Connections.AutoTrick then
        Connections.AutoTrick:Disconnect()
        Connections.AutoTrick = nil
    end
end

function Survivors:SetSk8Control(enabled)
    if enabled == State.Sk8Control then
        return
    end
    State.Sk8Control = enabled

    if enabled then
        Connections.Sk8Control = RunService.Heartbeat:Connect(function()
            local actor = Actors.CurrentActors[LocalPlayer]
            local skating = actor
                and actor.ActorName == "Veeronica"
                and actor.State
                and actor.State.isSkating

            if skating and not State.WasSkating then
                local channel = actor.Meta and actor.Meta.CurrentChannel or 1
                task.delay(0.1, function()
                    local current = Actors.CurrentActors[LocalPlayer]
                    if State.Sk8Control
                        and current
                        and current.State
                        and current.State.isSkating then
                        applyTurnPatch(current.Meta.CurrentChannel or channel)
                    end
                end)
            elseif not skating and State.WasSkating then
                restorePatches()
            end

            State.WasSkating = skating
        end)
    else
        if Connections.Sk8Control then
            Connections.Sk8Control:Disconnect()
            Connections.Sk8Control = nil
        end
        restorePatches()
        State.WasSkating = false
    end
end

function Survivors:Unload()
    for _, connection in pairs(Connections) do
        connection:Disconnect()
    end
    table.clear(Connections)
    restorePatches()
    State.AutoTrick = false
    State.Sk8Control = false
end

return Survivors
