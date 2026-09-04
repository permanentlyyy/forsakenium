local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FlowGameManager = require(ReplicatedStorage.Modules.Minigames.FlowGameManager)

local running = true
local connections = {}

local State = {
    Enabled = false,
    Speed = 0.03,
    Random = false,
    RandomMax = 0.1,
    RandomMin = 0.02,
}

local lastGame = nil
local session = { token = 0 }

local NEIGHBOURS = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }

local function cellKey(cell)
    return cell.row .. "-" .. cell.col
end

local function isNeighbour(r1, c1, r2, c2)
    if r2 == r1 - 1 and c2 == c1 then
        return true
    end
    if r2 == r1 + 1 and c2 == c1 then
        return true
    end
    if r2 == r1 and c2 == c1 - 1 then
        return true
    end
    if r2 == r1 and c2 == c1 + 1 then
        return true
    end
    return false
end

local function orderSolution(cells, endpoints)
    if not cells or #cells == 0 then
        return nil
    end

    local lookup = {}
    for _, cell in ipairs(cells) do
        lookup[cellKey(cell)] = { row = cell.row, col = cell.col }
    end

    local start
    for _, ep in ipairs(endpoints or {}) do
        if lookup[cellKey(ep)] then
            start = { row = ep.row, col = ep.col }
            break
        end
    end

    if not start then
        for _, cell in pairs(lookup) do
            local count = 0
            for _, d in ipairs(NEIGHBOURS) do
                if lookup[(cell.row + d[1]) .. "-" .. (cell.col + d[2])] then
                    count += 1
                end
            end
            if count == 1 then
                start = { row = cell.row, col = cell.col }
                break
            end
        end
    end

    if not start then
        start = { row = cells[1].row, col = cells[1].col }
    end

    local pool = table.clone(lookup)
    local ordered = { start }
    pool[cellKey(start)] = nil
    local cur = start

    while next(pool) do
        local moved = false
        for k, cell in pairs(pool) do
            if isNeighbour(cur.row, cur.col, cell.row, cell.col) then
                table.insert(ordered, { row = cell.row, col = cell.col })
                pool[k] = nil
                cur = cell
                moved = true
                break
            end
        end
        if not moved then
            break
        end
    end

    return ordered
end

local function nextDelay()
    if not State.Random then
        return State.Speed
    end
    local min = math.min(State.RandomMin, State.RandomMax)
    local max = math.max(State.RandomMin, State.RandomMax)
    return min + (max - min) * math.random()
end

local function drawSolutions(activeGame, solutions, token)
    for i, path in ipairs(solutions) do
        if not running or not State.Enabled or session.token ~= token then
            return
        end
        if activeGame.gameEnded or FlowGameManager.activeGame ~= activeGame then
            return
        end

        local start = path[1]
        activeGame:DragBegin(start.row, start.col)

        for s = 2, #path do
            if not running or not State.Enabled or session.token ~= token then
                return
            end
            if activeGame.gameEnded or FlowGameManager.activeGame ~= activeGame then
                return
            end
            activeGame:__stepToCell(path[s].row, path[s].col)
            task.wait(nextDelay())
        end

        activeGame:DragEnd()
        task.wait(0)
    end
end

table.insert(connections, RunService.Heartbeat:Connect(function()
    if not State.Enabled then
        lastGame = nil
        return
    end

    local activeGame = FlowGameManager.activeGame
    if activeGame and activeGame ~= lastGame and not activeGame.gameEnded and activeGame.Solution then
        lastGame = activeGame
        session.token += 1
        local token = session.token

        task.delay(0.3, function()
            if not running or not State.Enabled or session.token ~= token then
                return
            end
            if FlowGameManager.activeGame ~= activeGame or activeGame.gameEnded then
                return
            end

            local solutions = {}
            for ci, cells in ipairs(activeGame.Solution) do
                local ordered = orderSolution(cells, activeGame.targetPairs[ci])
                if not ordered or #ordered == 0 then
                    return
                end
                solutions[ci] = ordered
            end

            pcall(drawSolutions, activeGame, solutions, token)
        end)
    end
end))

local Generators = {}

function Generators:SetAutoSolve(enabled)
    State.Enabled = enabled
    session.token += 1
end

function Generators:SetSolveSpeed(value)
    State.Speed = value
end

function Generators:SetRandomSolveSpeed(enabled)
    State.Random = enabled
end

function Generators:SetRandomSolveMax(value)
    State.RandomMax = value
end

function Generators:SetRandomSolveMin(value)
    State.RandomMin = value
end

function Generators:Unload()
    running = false
    State.Enabled = false
    session.token += 1

    for _, conn in ipairs(connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    table.clear(connections)
end

return Generators
