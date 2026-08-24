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
    return loadstring(game:HttpGet(url))()
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
addTab("Sprinting", "Sprinting", "activity")
addTab("Combat", "Combat", "swords")
addTab("Visuals", "Visuals", "eye")
addTab("Survivors", "Survivors", "person-standing")
addTab("Killers", "Killers", "skull")
addTab("Miscellaneous", "Miscellaneous", "cloudy")
addTab("Settings", "Settings", "settings")


--// Player Tab
local CameraSection = Tabs.Player:AddSection("Camera")

CameraSection:AddSlider("MaxZoom", {
    Title = "Max Zoom",
    Default = 12,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        Player:SetMaxZoom(value)
    end
})

CameraSection:AddSlider("FOV", {
    Title = "Field Of View",
    Default = 80,
    Min = 70,
    Max = 120,
    Rounding = 0,
    Callback = function(value)
        Player:SetFOV(value)
    end
})

CameraSection:AddToggle("CameraNoclip", {
    Title = "Camera Noclip",
    Default = Player:IsCameraNoclip(),
    Callback = function(value)
        Player:SetCameraNoclip(value)
    end
})

local MovementSection = Tabs.Player:AddSection("Movement")

MovementSection:AddToggle("EqualizedMovement", {
    Title = "Directional Movement",
    Default = false,
    Callback = function(value)
        Player:SetEqualizedMovement(value)
    end
})

MovementSection:AddToggle("NoLandingSlowdown", {
    Title = "No Fall Slowness",
    Default = false,
    Callback = function(value)
        Player:SetNoLandingSlowdown(value)
    end
})

local LightingSection = Tabs.Player:AddSection("Lighting")

LightingSection:AddToggle("Fullbright", {
    Title = "Fullbright",
    Default = false,
    Callback = function(value)
        Player:SetFullbright(value)
    end
})

LightingSection:AddToggle("NoFog", {
    Title = "No Fog",
    Default = false,
    Callback = function(value)
        Player:SetNoFog(value)
    end
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
    Player:Unload()
end


--// Load Auto-Saved Config
SaveManager:LoadAutoloadConfig()
