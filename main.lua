--// Services


--// Modules
local Player = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/permanentlyyy/forsakenium/main/Functions/player.lua"
))()


--// Fluent
local Fluent = loadstring(game:HttpGet(
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()


--// Save Manager
local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"
))()


--// Interface Manager
local InterfaceManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"
))()


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
local Tabs = {
    Player = Window:AddTab({
        Title = "Player",
        Icon = "user"
    }),

    Sprinting = Window:AddTab({
        Title = "Sprinting",
        Icon = "activity"
    }),

    Combat = Window:AddTab({
        Title = "Combat",
        Icon = "swords"
    }),

    Visuals = Window:AddTab({
        Title = "Visuals",
        Icon = "eye"
    }),

    Survivors = Window:AddTab({
        Title = "Survivors",
        Icon = "person-standing"
    }),

    Killers = Window:AddTab({
        Title = "Killers",
        Icon = "skull"
    }),

    Miscellaneous = Window:AddTab({
        Title = "Miscellaneous",
        Icon = "cloudy"
    }),

    Settings = Window:AddTab({
        Title = "Settings",
        Icon = "settings"
    })
}


--// Save Manager Setup
SaveManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
SaveManager:SetFolder("Forsakenium")


--// Interface Manager Setup
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("Forsakenium")

--// Player Tabs
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


--// Settings Tab
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)


--// Select Default Tab
Window:SelectTab(1)

--// Load Auto-Saved Config
SaveManager:LoadAutoloadConfig()
