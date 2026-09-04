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

local function sameCell(a, b)
    return a.row == b.row and a.col == b.col
end

local function isColorSolved(activeGame, colorIndex)
    local path = activeGame.paths[colorIndex]
    local pair = activeGame.targetPairs[colorIndex]
    if not path or #path < 2 then
        return false
    end
    local first, last = path[1], path[#path]
    local a, b = pair[1], pair[2]
    return (sameCell(first, a) and sameCell(last, b)) or (sameCell(first, b) and sameCell(last, a))
end

local function isLive(activeGame, token)
    return running and State.Enabled and session.token == token
        and not activeGame.gameEnded and FlowGameManager.activeGame == activeGame
end

local function drawColor(activeGame, colorIndex, ordered, token)
    local t0 = os.clock()
    while activeGame.isDrawing and os.clock() - t0 < 2 do
        if not isLive(activeGame, token) then
            return
        end
        task.wait(0.05)
    end

    activeGame.paths[colorIndex] = {}
    for _, node in ipairs(ordered) do
        if not isLive(activeGame, token) then
            return
        end
        table.insert(activeGame.paths[colorIndex], { row = node.row, col = node.col })
        activeGame:updateGui()
        task.wait(nextDelay())
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
            if not isLive(activeGame, token) then
                return
            end

            local orderedColors = {}
            for ci, cells in ipairs(activeGame.Solution) do
                local ordered = orderSolution(cells, activeGame.targetPairs[ci])
                if not ordered or #ordered == 0 then
                    return
                end
                orderedColors[ci] = ordered
            end

            for _ = 1, 5 do
                if not isLive(activeGame, token) then
                    return
                end

                local pending = 0
                for ci, ordered in ipairs(orderedColors) do
                    if not isColorSolved(activeGame, ci) then
                        pending += 1
                        drawColor(activeGame, ci, ordered, token)
                    end
                end

                if not isLive(activeGame, token) then
                    return
                end

                if activeGame:checkWin() then
                    activeGame:checkForWin()
                    return
                end

                if pending == 0 then
                    return
                end

                task.wait(0.25)
            end
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
