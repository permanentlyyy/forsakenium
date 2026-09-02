local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local roleFolder = workspace:WaitForChild("Players")
local Survivors = roleFolder:WaitForChild("Survivors")
local Killers = roleFolder:WaitForChild("Killers")
local Spectating = roleFolder:WaitForChild("Spectating")

local RoundWatcher = {
	State = "Unknown",
	InRound = false,
	IsSurvivor = false,
	IsKiller = false,
	Alive = false,
}

RoundWatcher.StateChanged = Instance.new("BindableEvent")
RoundWatcher.SurvivorRoundStarted = Instance.new("BindableEvent")

local function isAlive()
	local char = LocalPlayer.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function computeState()
	local char = LocalPlayer.Character
	local inSurvivors = char ~= nil and char:IsDescendantOf(Survivors)
	local inKillers = char ~= nil and char:IsDescendantOf(Killers)
	local roundActive = Survivors:GetChildren()[1] ~= nil or Killers:GetChildren()[1] ~= nil

	if inSurvivors then
		return "Survivor", roundActive, true, false
	elseif inKillers then
		return "Killer", roundActive, false, true
	elseif roundActive then
		return "Spectating", roundActive, false, false
	end
	return "Lobby", false, false, false
end

local function update()
	local state, roundActive, isSurvivor, isKiller = computeState()
	local changed = state ~= RoundWatcher.State

	RoundWatcher.State = state
	RoundWatcher.InRound = roundActive
	RoundWatcher.IsSurvivor = isSurvivor
	RoundWatcher.IsKiller = isKiller
	RoundWatcher.Alive = isAlive()

	if changed then
		RoundWatcher.StateChanged:Fire(state)
		if state == "Survivor" then
			RoundWatcher.SurvivorRoundStarted:Fire()
		end
	end
end

for _, folder in ipairs({ Survivors, Killers, Spectating }) do
	folder.ChildAdded:Connect(update)
	folder.ChildRemoved:Connect(update)
end

LocalPlayer.CharacterAdded:Connect(function(char)
	local humanoid = char:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.Died:Connect(update)
	end
	update()
end)

RoundWatcher.StateChanged.Event:Connect(function(state)
	print("[RoundWatcher] state:", state, "| inRound:", RoundWatcher.InRound, "| survivor:", RoundWatcher.IsSurvivor)
end)

RoundWatcher.SurvivorRoundStarted.Event:Connect(function()
	warn("========================================")
	warn("[RoundWatcher] YOU ARE IN A ROUND AS A SURVIVOR!")
	warn("========================================")
end)

update()

task.spawn(function()
	while true do
		update()
		task.wait(0.25)
	end
end)

_G.RoundWatcher = RoundWatcher

return RoundWatcher
