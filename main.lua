--// Unload Previous Instance
if _G.__Forsakenium then
    pcall(_G.__Forsakenium)
end


--// Sources
local Sources = {
    Player = "https://raw.githubusercontent.com/permanentlyyy/forsakenium/main/Functions/player.lua",
    Survivors = "https://raw.githubusercontent.com/permanentlyyy/forsakenium/main/Functions/survivors.lua",
    Visuals = "https://raw.githubusercontent.com/permanentlyyy/forsakenium/main/Functions/visuals.lua",
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
local Survivors = load(Sources.Survivors)
local Visuals = load(Sources.Visuals)
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
    Title = "No Directional Movement",
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


--// Visuals Tab
local KillerVisualsSection = Tabs.Visuals:AddSection("Killer")

KillerVisualsSection:AddToggle("KillerESP", {
    Title = "Killer ESP",
    Default = false,
    Callback = function(value)
        Visuals.State.KillerESP = value
        Visuals:Refresh()
    end
})

KillerVisualsSection:AddToggle("ShowKillerName", {
    Title = "Show Killer Name",
    Default = false,
    Callback = function(value)
        Visuals.State.ShowKillerName = value
        Visuals:Refresh()
    end
})

KillerVisualsSection:AddToggle("ShowKillerHealth", {
    Title = "Show Killer Health",
    Default = false,
    Callback = function(value)
        Visuals.State.ShowKillerHealth = value
        Visuals:Refresh()
    end
})

KillerVisualsSection:AddSlider("KillerFillTransparency", {
    Title = "Fill Transparency",
    Default = 0.7,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(value)
        Visuals.State.KillerFillTransparency = value
        Visuals:Refresh()
    end
})

KillerVisualsSection:AddSlider("KillerOutlineTransparency", {
    Title = "Outline Transparency",
    Default = 0.3,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(value)
        Visuals.State.KillerOutlineTransparency = value
        Visuals:Refresh()
    end
})

local SurvivorVisualsSection = Tabs.Visuals:AddSection("Survivor")

SurvivorVisualsSection:AddToggle("SurvivorESP", {
    Title = "Survivor ESP",
    Default = false,
    Callback = function(value)
        Visuals.State.SurvivorESP = value
        Visuals:Refresh()
    end
})

SurvivorVisualsSection:AddToggle("ShowSurvivorName", {
    Title = "Show Survivor Name",
    Default = false,
    Callback = function(value)
        Visuals.State.ShowSurvivorName = value
        Visuals:Refresh()
    end
})

SurvivorVisualsSection:AddToggle("ShowSurvivorHealth", {
    Title = "Show Survivor Health",
    Default = false,
    Callback = function(value)
        Visuals.State.ShowSurvivorHealth = value
        Visuals:Refresh()
    end
})

SurvivorVisualsSection:AddSlider("SurvivorFillTransparency", {
    Title = "Fill Transparency",
    Default = 0.7,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(value)
        Visuals.State.SurvivorFillTransparency = value
        Visuals:Refresh()
    end
})

SurvivorVisualsSection:AddSlider("SurvivorOutlineTransparency", {
    Title = "Outline Transparency",
    Default = 0.3,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(value)
        Visuals.State.SurvivorOutlineTransparency = value
        Visuals:Refresh()
    end
})

local ItemsVisualsSection = Tabs.Visuals:AddSection("Items")

ItemsVisualsSection:AddToggle("GeneratorESP", {
    Title = "Generator ESP",
    Default = false,
    Callback = function(value)
        Visuals.State.GeneratorESP = value
        Visuals:Refresh()
    end
})

ItemsVisualsSection:AddToggle("ItemESP", {
    Title = "Item ESP",
    Default = false,
    Callback = function(value)
        Visuals.State.ItemESP = value
        Visuals:Refresh()
    end
})

ItemsVisualsSection:AddToggle("TripwireESP", {
    Title = "Tripwire ESP",
    Default = false,
    Callback = function(value)
        Visuals.State.TripwireESP = value
        Visuals:Refresh()
    end
})

ItemsVisualsSection:AddToggle("MineESP", {
    Title = "Mine ESP",
    Default = false,
    Callback = function(value)
        Visuals.State.MineESP = value
        Visuals:Refresh()
    end
})

ItemsVisualsSection:AddToggle("GraffitiESP", {
    Title = "Graffiti ESP",
    Default = false,
    Callback = function(value)
        Visuals.State.GraffitiESP = value
        Visuals:Refresh()
    end
})

local SpecialVisualsSection = Tabs.Visuals:AddSection("Special")

SpecialVisualsSection:AddToggle("PizzaDeliveryESP", {
    Title = "Pizza Delivery ESP",
    Default = false,
    Callback = function(value)
        Visuals.State.PizzaDeliveryESP = value
        Visuals:Refresh()
    end
})

SpecialVisualsSection:AddToggle("ZombieESP", {
    Title = "Zombie ESP",
    Default = false,
    Callback = function(value)
        Visuals.State.ZombieESP = value
        Visuals:Refresh()
    end
})

SpecialVisualsSection:AddToggle("GroundbulbESP", {
    Title = "Groundbulb ESP",
    Default = false,
    Callback = function(value)
        Visuals.State.GroundbulbESP = value
        Visuals:Refresh()
    end
})

SpecialVisualsSection:AddToggle("VineESP", {
    Title = "Vine ESP",
    Default = false,
    Callback = function(value)
        Visuals.State.VineESP = value
        Visuals:Refresh()
    end
})

SpecialVisualsSection:AddToggle("DigitalFootprintESP", {
    Title = "Digital Footprint ESP",
    Default = false,
    Callback = function(value)
        Visuals.State.DigitalFootprintESP = value
        Visuals:Refresh()
    end
})

local TracersVisualsSection = Tabs.Visuals:AddSection("Tracers")

TracersVisualsSection:AddToggle("GeneratorTracers", {
    Title = "Generator Tracers",
    Default = false,
    Callback = function(value)
        Visuals.State.GeneratorTracers = value
        Visuals:Refresh()
    end
})

TracersVisualsSection:AddToggle("ItemTracers", {
    Title = "Item Tracers",
    Default = false,
    Callback = function(value)
        Visuals.State.ItemTracers = value
        Visuals:Refresh()
    end
})

TracersVisualsSection:AddToggle("PizzaDeliveryTracers", {
    Title = "Pizza Delivery Tracers",
    Default = false,
    Callback = function(value)
        Visuals.State.PizzaDeliveryTracers = value
        Visuals:Refresh()
    end
})

TracersVisualsSection:AddToggle("ZombieTracers", {
    Title = "Zombie Tracers",
    Default = false,
    Callback = function(value)
        Visuals.State.ZombieTracers = value
        Visuals:Refresh()
    end
})


--// Survivors Tab
local VeeronicaSection = Tabs.Survivors:AddSection("Veeronica")

VeeronicaSection:AddToggle("AutoTrick", {
    Title = "Auto Trick",
    Default = false,
    Callback = function(value)
        Survivors:SetAutoTrick(value)
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
    Survivors:Unload()
    Visuals:Unload()
end


--// Load Auto-Saved Config
SaveManager:LoadAutoloadConfig()
