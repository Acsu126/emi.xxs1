--[[
    Aurora X — Fast Attack (standalone)
    Extraído de Kaitun Dungeon. Sin UI, sin teleport, sin auto-farm.
    Al ejecutarlo se activa solo y ataca a los enemigos cercanos.
]]

if getgenv and getgenv().AuroraFastAttack then return end
if getgenv then getgenv().AuroraFastAttack = true end

local cloneref = cloneref or function(o) return o end
local function service(name) return cloneref(game:GetService(name)) end

local Players           = service("Players")
local Workspace         = service("Workspace")
local ReplicatedStorage = service("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Configuración
local RANGE = 60          -- distancia máxima (studs) para golpear enemigos
local MAX_TARGETS = 8     -- máximo de enemigos golpeados por tick

local netFolder      = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local registerAttack = netFolder:WaitForChild("RE/RegisterAttack")
local registerHit    = netFolder:WaitForChild("RE/RegisterHit")

local function getTargets()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local folder = Workspace:FindFirstChild("Enemies") or Workspace
    local list = {}

    for _, enemy in ipairs(folder:GetChildren()) do
        if enemy:IsA("Model") and enemy ~= char then
            local hum  = enemy:FindFirstChildOfClass("Humanoid")
            local head = enemy:FindFirstChild("Head")
            local eroot = enemy:FindFirstChild("HumanoidRootPart") or head
            if hum and hum.Health > 0 and head and eroot then
                local dist = (eroot.Position - root.Position).Magnitude
                if dist <= RANGE then
                    table.insert(list, {enemy = enemy, head = head, dist = dist})
                end
            end
        end
    end

    table.sort(list, function(a, b) return a.dist < b.dist end)
    return list
end

task.spawn(function()
    while true do
        local char = LocalPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        local targets = getTargets()

        if targets and #targets > 0 then
            if tool then pcall(function() tool:Activate() end) end

            pcall(function()
                registerAttack:FireServer(0)
            end)

            -- Golpea al más cercano como objetivo principal y al resto como extras
            local first = targets[1]
            local others = {}
            for i = 2, math.min(#targets, MAX_TARGETS) do
                table.insert(others, {targets[i].enemy, targets[i].head})
            end

            pcall(function()
                registerHit:FireServer(first.head, others)
            end)
        end

        task.wait()
    end
end)
