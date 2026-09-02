local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

-- CONFIG
local ALLOWED_NAMES = {
	{ "SystemRemotes", Disable3drendering = true, FpsCap = 15 },
	{ "Melkercool31", Disable3drendering = true, FpsCap = 5 },
	{ "MelkerGalaxy", Disable3drendering = true, FpsCap = 5 },
	{ "Blast_OffSimulator1", Disable3drendering = true, FpsCap = 5 },
	{ "RedBronzeFarm_Island", Disable3drendering = true, FpsCap = 5 },
	{ "wickeddoomknight99", Disable3drendering = true, FpsCap = 5 },
	{ "Tornado_Islands", Disable3drendering = true, FpsCap = 5 },
	{ "mojo21", Disable3drendering = true, FpsCap = 5 },
	{ "bejehehfh", Disable3drendering = true, FpsCap = 15 },
}

local CHECK_INTERVAL = 3
local AUTO_RESET_PLAYER = "bejehehfh"
local AUTO_RESET_DELAY = 65

pcall(function()
	settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end)

local localPlayer = Players.LocalPlayer or Players:WaitForChild("LocalPlayer", 30)
if not localPlayer then
	return
end

localPlayer.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new(0, 0))
end)

local function applySettings(cfg)
	if not cfg then
		return
	end
	if cfg.Disable3drendering then
		pcall(function()
			RunService:Set3dRenderingEnabled(false)
		end)
	end
	local cap = cfg.FpsCap
	if cap == true then
		cap = 5
	end
	if type(cap) == "number" and cap > 0 then
		if setfpscap then
			pcall(setfpscap, cap)
		end
	end
end

local lookup = {}
for _, entry in ipairs(ALLOWED_NAMES) do
	if type(entry) == "string" then
		lookup[string.lower(entry)] = false
	else
		lookup[string.lower(entry[1])] = entry
	end
end

local conn = nil
local kicked = false

local function kickIfStranger(player)
	if kicked then
		return
	end
	if lookup[string.lower(player.Name)] ~= nil then
		return
	end
	kicked = true
	if conn then
		conn:Disconnect()
		conn = nil
	end
	localPlayer:Kick("Non-whitelisted player in server: " .. player.Name)
end

local function getSurvivors()
	local pf = workspace:FindFirstChild("Players")
	return pf and pf:FindFirstChild("Survivors")
end

conn = Players.PlayerAdded:Connect(kickIfStranger)

for _, player in ipairs(Players:GetPlayers()) do
	kickIfStranger(player)
	if kicked then
		break
	end
end

if not kicked then
	applySettings(lookup[string.lower(localPlayer.Name)])

	task.spawn(function()
		while not kicked do
			for _, player in ipairs(Players:GetPlayers()) do
				kickIfStranger(player)
				if kicked then
					break
				end
			end
			if not kicked then
				task.wait(CHECK_INTERVAL)
			end
		end
	end)

	if string.lower(localPlayer.Name) == string.lower(AUTO_RESET_PLAYER) then
		task.spawn(function()
			local lastResetChar = nil
			while not kicked do
				local survivors = getSurvivors()
				local char = localPlayer.Character
				if survivors and char and char ~= lastResetChar and char:IsDescendantOf(survivors) then
					task.wait(AUTO_RESET_DELAY)
					if kicked then
						break
					end
					local c = localPlayer.Character
					if c and c:IsDescendantOf(survivors) then
						local h = c:FindFirstChildOfClass("Humanoid")
						if h and h.Health > 0 then
							h.Health = 0
							lastResetChar = c
						end
					end
				else
					task.wait(0.5)
				end
			end
		end)
	end
end