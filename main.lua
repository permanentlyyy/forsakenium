--// Unload Previous Instance
if _G.__Forsakenium then
    pcall(_G.__Forsakenium)
end


--// Sources
local Sources = {
    Player = "https://raw.githubusercontent.com/permanentlyyy/forsakenium/main/Functions/player.lua",
    Fluent = "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua",
    SaveManager = "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua",
    InterfaceManager = "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"
}


--// Loader
local function load(url)
    return loadstring(game:HttpGet(url .. "?nocache=" .. tostring(tick())))()
end


--// Libraries
local Player = load(Sources.Player)
local Fluent = load(Sources.Fluent)
local SaveManager = load(Sources.SaveManager)
local InterfaceManager = load(Sources.InterfaceManager)


--// Window
local Window = Fluent:CreateWindow({
    Title = "Forsakenium",
    SubTitle = "",
    TabWidth = 120,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl,
})


--// Tabs
local Tabs = {}

local function addTab(id, title, icon)
    Tabs[id] = Window:AddTab({
        Title = title,
        Icon = icon
    })
end

addTab("Player", "Player", "user")
addTab("Generators", "Generators", "cog")
addTab("Visuals", "Visuals", "eye")
addTab("Survivors", "Survivors", "person-standing")
addTab("Killers", "Killers", "skull")
addTab("Animations", "Animations", "clapperboard")
addTab("Miscellaneous", "Miscellaneous", "cloudy")
addTab("Settings", "Settings", "settings")


--// Player Tab
local StaminaSection = Tabs.Player:AddSection("Stamina")

StaminaSection:AddToggle("InfiniteStamina", {
    Title = "Infinite Stamina",
    Default = false,
    Callback = function(value)
        Player:SetInfiniteStamina(value)
    end
})

StaminaSection:AddToggle("ShowLegitStaminaView", {
    Title = "Show Legit Stamina View",
    Default = false,
    Callback = function(value)
        Player:SetShowLegitStaminaView(value)
    end
})

StaminaSection:AddToggle("AlwaysSprint", {
    Title = "Always Sprint",
    Default = false,
    Callback = function(value)
        Player:SetAlwaysSprint(value)
    end
})

local CharacterSection = Tabs.Player:AddSection("Character")

CharacterSection:AddToggle("GodMode", {
    Title = "God Mode",
    Default = false,
    Callback = function(value)
        Player:SetGodMode(value)
    end
})

CharacterSection:AddToggle("Invisibility", {
    Title = "Invisibility",
    Default = false,
    Callback = function(value)
        Player:SetInvisibility(value)
    end
})

CharacterSection:AddToggle("SilentFootsteps", {
    Title = "Silent Footsteps",
    Default = false,
    Callback = function(value)
        Player:SetSilentFootsteps(value)
    end
})


--// Generators Tab
local AutomationSection = Tabs.Generators:AddSection("Automation")

AutomationSection:AddToggle("AutoSolve", {
    Title = "Auto Solve",
    Default = false
})

AutomationSection:AddToggle("RandomAutoSolveSpeed", {
    Title = "Random Auto Solve Speed",
    Default = false
})

AutomationSection:AddSlider("SolveSpeed", {
    Title = "Solve Speed",
    Default = 4.5,
    Min = 1.5,
    Max = 10,
    Rounding = 1
})

AutomationSection:AddSlider("RandomSolveMax", {
    Title = "Random Solve Max",
    Default = 10,
    Min = 1,
    Max = 10,
    Rounding = 1
})

AutomationSection:AddSlider("RandomSolveMin", {
    Title = "Random Solve Min",
    Default = 1.5,
    Min = 1,
    Max = 10,
    Rounding = 1
})

local GridSection = Tabs.Generators:AddSection("Grid")

GridSection:AddToggle("GridSize", {
    Title = "Grid Size",
    Default = false
})

GridSection:AddSlider("Size", {
    Title = "Size",
    Default = 7,
    Min = 2,
    Max = 30,
    Rounding = 0
})

local PuzzleSection = Tabs.Generators:AddSection("Puzzle")

PuzzleSection:AddToggle("ShowCorrectPuzzlePath", {
    Title = "Show Correct Puzzle Path",
    Default = false
})

PuzzleSection:AddSlider("PuzzlePathTransparency", {
    Title = "Transparency",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0
})


--// Survivors Tab
local SurvivorSections = {}

for _, name in ipairs({
    "Elliot", "Noob", "Jane Doe", "007n7",
    "Guest 1337", "Dusekkar", "Veeronica", "Chance"
}) do
    SurvivorSections[name] = Tabs.Survivors:AddSection(name)
end


--// Killers Tab
local KillerSections = {}

for _, name in ipairs({
    "c00lkidd", "Slasher", "John Doe", "Noli", "1х1х1х1",
    "Guest 666", "Nosferatu", "Azure"
}) do
    KillerSections[name] = Tabs.Killers:AddSection(name)
end


--// Animations Tab
local AnimationChangerSection = Tabs.Animations:AddSection("Animation Changer")

AnimationChangerSection:AddDropdown("SelectKillerAnimations", {
    Title = "Killer",
    Values = { "c00lkidd", "Slasher", "John Doe", "Noli", "1х1х1х1", "Guest 666", "Nosferatu", "Azure" },
    Multi = false,
    Default = "c00lkidd"
})

AnimationChangerSection:AddToggle("EnableKillerAnimations", {
    Title = "Enable Killer Animations",
    Default = false
})

local AnimationsMiscSection = Tabs.Animations:AddSection("Miscellaneous")

AnimationsMiscSection:AddToggle("EmoteAsKiller", {
    Title = "Emote as Killer",
    Default = false
})


--// Miscellaneous Tab
local MiscLightingSection = Tabs.Miscellaneous:AddSection("Lighting")

MiscLightingSection:AddToggle("Fullbright", {
    Title = "Fullbright",
    Default = false
})

MiscLightingSection:AddToggle("NoFog", {
    Title = "No Fog",
    Default = false
})

local MiscCameraSection = Tabs.Miscellaneous:AddSection("Camera")

MiscCameraSection:AddToggle("InfiniteZoom", {
    Title = "Infinite Zoom",
    Default = false
})

MiscCameraSection:AddToggle("CameraNoclip", {
    Title = "Camera Noclip",
    Default = false
})

local DeviceSection = Tabs.Miscellaneous:AddSection("Device Spoofer")

DeviceSection:AddDropdown("ChooseDevice", {
    Title = "Choose Device",
    Values = { "PC", "Mobile", "Console", "Unknown" },
    Multi = false,
    Default = "PC"
})

local PrivacySection = Tabs.Miscellaneous:AddSection("Privacy")

PrivacySection:AddToggle("ShowHiddenStats", {
    Title = "Show Hidden Stats",
    Default = false
})

PrivacySection:AddToggle("HideName", {
    Title = "Hide Name",
    Default = false
})

local MiscFOVSection = Tabs.Miscellaneous:AddSection("Field of View")

MiscFOVSection:AddSlider("CustomFOV", {
    Title = "Custom FOV",
    Default = 80,
    Min = 70,
    Max = 120,
    Rounding = 0
})


--// Visuals Tab
local KillerSection = Tabs.Visuals:AddSection("Killer")

KillerSection:AddToggle("KillerESP", {
    Title = "Killer ESP",
    Default = false
})

KillerSection:AddToggle("ShowKillerName", {
    Title = "Show Killer Name",
    Default = false
})

KillerSection:AddToggle("ShowKillerHealth", {
    Title = "Show Killer Health",
    Default = false
})

KillerSection:AddSlider("KillerFillTransparency", {
    Title = "Fill Transparency",
    Default = 0.7,
    Min = 0,
    Max = 1,
    Rounding = 2
})

KillerSection:AddSlider("KillerOutlineTransparency", {
    Title = "Outline Transparency",
    Default = 0.3,
    Min = 0,
    Max = 1,
    Rounding = 2
})

KillerSection:AddColorpicker("KillerColor", {
    Title = "Killer Color",
    Default = Color3.fromRGB(255, 50, 50)
})

local SurvivorSection = Tabs.Visuals:AddSection("Survivor")

SurvivorSection:AddToggle("SurvivorESP", {
    Title = "Survivor ESP",
    Default = false
})

SurvivorSection:AddToggle("ShowSurvivorName", {
    Title = "Show Survivor Name",
    Default = false
})

SurvivorSection:AddToggle("ShowSurvivorHealth", {
    Title = "Show Survivor Health",
    Default = false
})

SurvivorSection:AddSlider("SurvivorFillTransparency", {
    Title = "Fill Transparency",
    Default = 0.7,
    Min = 0,
    Max = 1,
    Rounding = 2
})

SurvivorSection:AddSlider("SurvivorOutlineTransparency", {
    Title = "Outline Transparency",
    Default = 0.3,
    Min = 0,
    Max = 1,
    Rounding = 2
})

SurvivorSection:AddColorpicker("SurvivorColor", {
    Title = "Survivor Color",
    Default = Color3.fromRGB(50, 255, 50)
})

local MiscellaneousSection = Tabs.Visuals:AddSection("Miscellaneous")

MiscellaneousSection:AddDropdown("ObjectESP", {
    Title = "Object ESP",
    Values = { "Generator", "Item", "Tripwire", "Mine", "Ritual", "Graffiti" },
    Multi = true,
    Default = {}
})

MiscellaneousSection:AddDropdown("Tracers", {
    Title = "Tracers",
    Values = { "Killer", "Survivor", "Generator", "Item", "Tripwire", "Mine" },
    Multi = true,
    Default = {}
})


--// Managers
SaveManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
SaveManager:SetFolder("Forsakenium")

InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("Forsakenium")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)


--// Select Default Tab
Window:SelectTab(1)


--// Unload Handler
_G.__Forsakenium = function()
    Player:Unload()
    Fluent:Destroy()
end


--// Load Auto-Saved Config
SaveManager:LoadAutoloadConfig()
