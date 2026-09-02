--// Unload Previous Instance
if _G.__Forsakenium then
    pcall(_G.__Forsakenium)
end


--// Sources
local Sources = {
    Fluent = "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua",
    SaveManager = "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua",
    InterfaceManager = "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"
}


--// Loader
local function load(url)
    return loadstring(game:HttpGet(url .. "?v=" .. os.time()))()
end


--// Libraries
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
addTab("Combat", "Combat", "swords")
addTab("Visuals", "Visuals", "eye")
addTab("Survivors", "Survivors", "person-standing")
addTab("Killers", "Killers", "skull")
addTab("Miscellaneous", "Miscellaneous", "cloudy")
addTab("Settings", "Settings", "settings")


--// Player Tab
local StaminaSection = Tabs.Player:AddSection("Stamina")

StaminaSection:AddToggle("InfiniteStamina", {
    Title = "Infinite Stamina",
    Default = false
})

StaminaSection:AddToggle("ShowLegitStaminaView", {
    Title = "Show Legit Stamina View",
    Default = false
})

StaminaSection:AddToggle("AlwaysSprint", {
    Title = "Always Sprint",
    Default = false
})

local CharacterSection = Tabs.Player:AddSection("Character")

CharacterSection:AddToggle("GodMode", {
    Title = "Invincible",
    Default = false
})

CharacterSection:AddToggle("Invisibility", {
    Title = "Invisibility",
    Default = false
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

GridSection:AddSlider("GridSize", {
    Title = "Size",
    Default = 10,
    Min = 2,
    Max = 30,
    Rounding = 0
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
    Fluent:Destroy()
end


--// Load Auto-Saved Config
SaveManager:LoadAutoloadConfig()
