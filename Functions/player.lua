local Player = {}

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

function Player:SetMaxZoom(value)
    LocalPlayer.CameraMaxZoomDistance = value
end

return Player
