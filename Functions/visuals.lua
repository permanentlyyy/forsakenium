local Visuals = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

Visuals.State = {
    KillerESP = false, ShowKillerName = false, ShowKillerHealth = false,
    KillerFillTransparency = 0.7, KillerOutlineTransparency = 0.3,
    SurvivorESP = false, ShowSurvivorName = false, ShowSurvivorHealth = false,
    SurvivorFillTransparency = 0.7, SurvivorOutlineTransparency = 0.3,
    GeneratorESP = false, ItemESP = false, TripwireESP = false, MineESP = false,
    GraffitiESP = false, PizzaDeliveryESP = false, ZombieESP = false,
    GroundbulbESP = false, VineESP = false, DigitalFootprintESP = false,
    GeneratorTracers = false, ItemTracers = false,
    PizzaDeliveryTracers = false, ZombieTracers = false,
}

local VisualState = Visuals.State
local PlayerVisuals, ObjectVisuals = {}, {}
local Running = false
local Connections = {}

local function getPart(object)
    if object:IsA("BasePart") then return object end
    return object:FindFirstChild("HumanoidRootPart")
        or object.PrimaryPart
        or object:FindFirstChildWhichIsA("BasePart", true)
end

local function makeLabel(parent, part)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ForsakeniumBillboard"
    billboard.Adornee = part
    billboard.Size = UDim2.fromOffset(140, 38)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Jura
    label.TextSize = 12
    label.TextStrokeTransparency = 0.5
    label.Parent = billboard
    return billboard, label
end

local function removeVisual(object)
    local data = PlayerVisuals[object] or ObjectVisuals[object]
    if not data then return end
    if data.highlight then data.highlight:Destroy() end
    if data.billboard then data.billboard:Destroy() end
    if data.tracer then data.tracer:Remove() end
    PlayerVisuals[object], ObjectVisuals[object] = nil, nil
end

local function addPlayerVisual(model, isKiller)
    local part = getPart(model)
    if PlayerVisuals[model] or not part then return end
    local color = isKiller and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ForsakeniumHighlight"
    highlight.Adornee = model
    highlight.FillColor, highlight.OutlineColor = color, color
    highlight.Parent = model
    local billboard, label = makeLabel(model, part)
    label.TextColor3 = color
    PlayerVisuals[model] = { highlight = highlight, billboard = billboard, label = label, isKiller = isKiller }
end

local ObjectColors = {
    Generator = Color3.fromRGB(200, 100, 200), Item = Color3.fromRGB(200, 200, 0),
    Tripwire = Color3.fromRGB(100, 0, 100), Mine = Color3.fromRGB(255, 0, 255),
    Graffiti = Color3.fromRGB(255, 255, 255), PizzaDelivery = Color3.fromRGB(200, 100, 100),
    Zombie = Color3.fromRGB(200, 100, 100), Groundbulb = Color3.fromRGB(0, 255, 200),
    Vine = Color3.fromRGB(200, 0, 255), DigitalFootprint = Color3.fromRGB(255, 80, 90),
}

local function enabled(kind)
    return VisualState[kind .. "ESP"] == true
end

local function addObjectVisual(model, kind)
    local part = getPart(model)
    if ObjectVisuals[model] or not part then return end
    if kind == "DigitalFootprint" and model:IsA("BasePart") then
        model.Transparency = 0
    end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ForsakeniumHighlight"
    highlight.Adornee = model
    highlight.FillColor = ObjectColors[kind]
    highlight.OutlineColor = highlight.FillColor
    highlight.FillTransparency, highlight.OutlineTransparency = 0.7, 0.3
    highlight.Enabled = enabled(kind)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = model:IsA("Model") and model or Workspace
    local billboard, label = makeLabel(model, part)
    label.TextColor3 = highlight.FillColor
    label.Text = model:GetAttribute("Type") or model.Name
    ObjectVisuals[model] = {
        highlight = highlight,
        billboard = billboard,
        label = label,
        part = part,
        kind = kind,
    }
end

local function playerText(data, model)
    local role = data.isKiller and "Killer" or "Survivor"
    local lines = {}
    if VisualState["Show" .. role .. "Name"] then
        table.insert(lines, model:GetAttribute("ActorDisplayName") or model.Name)
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if VisualState["Show" .. role .. "Health"] and humanoid then
        table.insert(lines, string.format("HP: %d/%d", humanoid.Health, humanoid.MaxHealth))
    end
    data.label.Text = table.concat(lines, "\n")
    data.label.Visible = #lines > 0
    data.highlight.FillTransparency = VisualState[role .. "FillTransparency"]
    data.highlight.OutlineTransparency = VisualState[role .. "OutlineTransparency"]
end

local function updateVisuals()
    local seenPlayers, seenObjects = {}, {}
    local playersFolder = Workspace:FindFirstChild("Players")
    if playersFolder then
        for _, role in ipairs({ "Killers", "Survivors" }) do
            local folder = playersFolder:FindFirstChild(role)
            if folder then
                for _, model in ipairs(folder:GetChildren()) do
                    local isKiller = role == "Killers"
                    if VisualState[isKiller and "KillerESP" or "SurvivorESP"]
                        and model ~= LocalPlayer.Character and getPart(model) then
                        seenPlayers[model] = true
                        addPlayerVisual(model, isKiller)
                        playerText(PlayerVisuals[model], model)
                    end
                end
            end
        end
    end
    for model in pairs(PlayerVisuals) do
        if not seenPlayers[model] then removeVisual(model) end
    end

    local map = Workspace:FindFirstChild("Map")
    local ingame = map and map:FindFirstChild("Ingame")
    if not ingame then
        for model in pairs(ObjectVisuals) do removeVisual(model) end
        return
    end
    local function mark(model, kind)
        if model then seenObjects[model] = kind end
    end
    local mapContents = ingame:FindFirstChild("Map")
    if mapContents then
        for _, model in ipairs(mapContents:GetChildren()) do
            if model:IsA("Model") then
                local lower = model.Name:lower()
                local progress = model:FindFirstChild("Progress")
                if lower:find("generator") and model.Name ~= "FakeGenerator"
                    and (enabled("Generator") or VisualState.GeneratorTracers)
                    and (not progress or progress.Value < 100) then
                    mark(model, "Generator")
                elseif model:FindFirstChild("ItemRoot")
                    and (enabled("Item") or VisualState.ItemTracers) then
                    mark(model, "Item")
                end
            end
        end
    end
    for _, itemRoot in ipairs(ingame:GetDescendants()) do
        if itemRoot.Name == "ItemRoot" and itemRoot.Parent and itemRoot.Parent:IsA("Model")
            and (enabled("Item") or VisualState.ItemTracers) then
            mark(itemRoot.Parent, "Item")
        end
    end
    local deliveryNames = {
        PizzaDeliveryRig = true, Mafiaso1 = true, Mafiaso2 = true, Builderman = true,
        Elliot = true, ShedletskyCORRUPT = true, ChanceCORRUPT = true,
    }
    for _, object in ipairs(ingame:GetChildren()) do
        if object:IsA("Folder") and object.Name:match("Shadows$")
            and enabled("DigitalFootprint") then
            for _, footprint in ipairs(object:GetChildren()) do
                if footprint:IsA("BasePart") then mark(footprint, "DigitalFootprint") end
            end
        end
        if object:IsA("Model") then
            local lower = object.Name:lower()
            if lower:match("taphtripwire$") and enabled("Tripwire") then mark(object, "Tripwire") end
            if object.Name == "SubspaceTripmine" and enabled("Mine") then mark(object, "Mine") end
            if object.Name == "1x1x1x1Zombie"
                and (enabled("Zombie") or VisualState.ZombieTracers) then
                mark(object, "Zombie")
            end
            if deliveryNames[object.Name]
                and (enabled("PizzaDelivery") or VisualState.PizzaDeliveryTracers) then
                mark(object, "PizzaDelivery")
            end
        elseif object:IsA("BasePart") and object.Name == "GraffitiCL" and enabled("Graffiti") then
            mark(object, "Graffiti")
        end
    end
    for _, object in ipairs(ingame:GetDescendants()) do
        if object:IsA("Model") then
            local lower = object.Name:lower()
            if lower == "groundbulbmodel" and enabled("Groundbulb") then mark(object, "Groundbulb") end
            if lower == "vinemodel" and enabled("Vine") then mark(object, "Vine") end
        end
    end
    for model, kind in pairs(seenObjects) do
        addObjectVisual(model, kind)
        ObjectVisuals[model].highlight.Enabled = enabled(kind)
        ObjectVisuals[model].label.Text = model:GetAttribute("Type") or model.Name
    end
    for model in pairs(ObjectVisuals) do
        if not seenObjects[model] then removeVisual(model) end
    end
end

local function updateTracers()
    if not Drawing then return end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    for _, data in pairs(ObjectVisuals) do
        local show = data.kind == "Generator" and VisualState.GeneratorTracers
            or data.kind == "Item" and VisualState.ItemTracers
            or data.kind == "PizzaDelivery" and VisualState.PizzaDeliveryTracers
            or data.kind == "Zombie" and VisualState.ZombieTracers
        if show then
            if not data.tracer then
                data.tracer = Drawing.new("Line")
                data.tracer.Thickness = 1
                data.tracer.Color = data.highlight.FillColor
            end
            local point, visible = camera:WorldToViewportPoint(data.part.Position)
            local start = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
            local finish = Vector2.new(point.X, point.Y)
            data.tracer.Visible = visible and point.Z > 0
            data.tracer.From = start
            data.tracer.To = finish
        elseif data.tracer then
            data.tracer.Visible = false
        end
        if not show and data.tracer then
            data.tracer:Remove()
            data.tracer = nil
        end
    end
end

function Visuals:Refresh()
    pcall(updateVisuals)
end

function Visuals:Start()
    if Running then return end
    Running = true

    table.insert(Connections, Workspace.DescendantAdded:Connect(function(instance)
        if instance:IsA("BasePart") and instance.Parent
            and instance.Parent.Name:match("Shadows$") then
            task.defer(function() pcall(updateVisuals) end)
        end
    end))

    table.insert(Connections, RunService.RenderStepped:Connect(updateTracers))

    task.spawn(function()
        while Running do
            task.wait(0.15)
            pcall(updateVisuals)
        end
    end)
end

function Visuals:Unload()
    Running = false
    for _, connection in ipairs(Connections) do
        connection:Disconnect()
    end
    table.clear(Connections)
    for model in pairs(PlayerVisuals) do removeVisual(model) end
    for model in pairs(ObjectVisuals) do removeVisual(model) end
end

Visuals:Start()

return Visuals
