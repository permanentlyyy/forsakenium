print("Forsaken Plus loaded!")

local BASE_URL = "https://raw.githubusercontent.com/permanentlyyy/forsakenium/main/"

local function LoadModule(path)
    local source = game:HttpGet(BASE_URL .. path)
    return loadstring(source)()
end

local Player = LoadModule("Functions/Player.lua")

Player:Test()
