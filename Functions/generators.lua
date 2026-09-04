local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FlowGameManager = require(ReplicatedStorage.Modules.Minigames.FlowGameManager)

local running = true
local connections = {}

local State = {
    Enabled = false,
    Speed = 4.5,
    Random = false,
    RandomMax = 10,
    RandomMin = 1.5,
}

local lastGame = nil
local session = { token = 0 }

local DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

local function shuffledDirs()
    local dirs = table.clone(DIRS)
    for i = #dirs, 2, -1 do
        local j = math.random(i)
        dirs[i], dirs[j] = dirs[j], dirs[i]
    end
    return dirs
end

local function solvePuzzle(gridSize, targetPairs)
    local targetAt = {}
    for i, pair in ipairs(targetPairs) do
        for _, pt in ipairs(pair) do
            targetAt[pt.row] = targetAt[pt.row] or {}
            targetAt[pt.row][pt.col] = i
        end
    end

    local solutions = {}

    local function isFree(r, c, pairIndex)
        if r < 1 or r > gridSize or c < 1 or c > gridSize then
            return false
        end
        local owner = targetAt[r] and targetAt[r][c]
        if owner and owner ~= pairIndex then
            return false
        end
        for _, path in ipairs(solutions) do
            for _, cell in ipairs(path) do
                if cell.row == r and cell.col == c then
                    return false
                end
            end
        end
        return true
    end

    local function enumeratePaths(pairIndex, start, goal, maxCount, maxLen, budget)
        local results = {}
        local visited = {}
        local path = { { row = start.row, col = start.col } }

        local function dfs(r, c)
            if #results >= maxCount or budget.left <= 0 then
                return
            end
            budget.left -= 1
            if r == goal.row and c == goal.col then
                table.insert(results, table.clone(path))
                return
            end
            if #path >= maxLen then
                return
            end
            visited[r] = visited[r] or {}
            visited[r][c] = true
            for _, d in ipairs(shuffledDirs()) do
                if #results >= maxCount or budget.left <= 0 then
                    break
                end
                local nr, nc = r + d[1], c + d[2]
                if not (visited[nr] and visited[nr][nc]) and isFree(nr, nc, pairIndex) then
                    table.insert(path, { row = nr, col = nc })
                    dfs(nr, nc)
                    table.remove(path)
                end
            end
            visited[r][c] = nil
        end

        dfs(start.row, start.col)
        table.sort(results, function(a, b)
            return #a < #b
        end)
        return results
    end

    local function assign(pairIndex, budget)
        if pairIndex > #targetPairs then
            return true
        end
        local pair = targetPairs[pairIndex]
        local candidates = enumeratePaths(pairIndex, pair[1], pair[2], 6, gridSize * 2 + 2, budget)
        for _, path in ipairs(candidates) do
            table.insert(solutions, path)
            if assign(pairIndex + 1, budget) then
                return true
            end
            table.remove(solutions)
            if budget.left <= 0 then
                return false
            end
        end
        return false
    end

    if assign(1, { left = 60000 }) then
        return solutions
    end
    return nil
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
            task.wait(0.045 + math.random() * 0.045)
        end

        activeGame:DragEnd()
        task.wait(0.12 + math.random() * 0.1)
    end
end

table.insert(connections, RunService.Heartbeat:Connect(function()
    if not State.Enabled then
        lastGame = nil
        return
    end

    local activeGame = FlowGameManager.activeGame
    if activeGame and activeGame ~= lastGame and not activeGame.gameEnded then
        lastGame = activeGame
        session.token += 1
        local token = session.token

        local delay = State.Speed
        if State.Random then
            local min = math.min(State.RandomMin, State.RandomMax)
            local max = math.max(State.RandomMin, State.RandomMax)
            delay = min + (max - min) * math.random()
        end

        task.delay(delay, function()
            if not running or not State.Enabled or session.token ~= token then
                return
            end
            if FlowGameManager.activeGame ~= activeGame or activeGame.gameEnded then
                return
            end

            local ok, solutions = pcall(solvePuzzle, activeGame.gridSize, activeGame.targetPairs)
            if ok and solutions then
                pcall(drawSolutions, activeGame, solutions, token)
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
