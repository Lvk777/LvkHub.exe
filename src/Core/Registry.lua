-- LvkHub.exe shared registries
-- Bots: direct Models inside Workspace.Players that are NOT real Roblox Player characters.
-- Vehicles: direct Models inside Workspace.Vehicles.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Registry = {
    Bots = setmetatable({}, {__mode = "k"}),
    Vehicles = setmetatable({}, {__mode = "k"}),
    BotFolder = nil,
    VehicleFolder = nil,
    _connections = {},
}

local function disconnectAll(list)
    for _, c in ipairs(list) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(list)
end

function Registry.IsRealPlayerCharacter(model)
    if not model or not model:IsA("Model") then return false end
    local ok, plr = pcall(function()
        return Players:GetPlayerFromCharacter(model)
    end)
    if ok and plr then return true end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == model then return true end
    end
    return false
end

function Registry.RootOf(model)
    if not model then return nil end
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Torso")
        or model.PrimaryPart
        or model:FindFirstChildWhichIsA("BasePart")
end

function Registry.HumanoidOf(model)
    return model and model:FindFirstChildOfClass("Humanoid") or nil
end

function Registry.IsBot(model)
    if not Registry.BotFolder then return false end
    if not model or not model:IsA("Model") or model.Parent ~= Registry.BotFolder then return false end
    if Registry.IsRealPlayerCharacter(model) then return false end
    local hum = Registry.HumanoidOf(model)
    local root = Registry.RootOf(model)
    return hum ~= nil and root ~= nil and hum.Health > 0
end

local function rescanBots()
    table.clear(Registry.Bots)
    local folder = Registry.BotFolder
    if not folder then return end
    for _, child in ipairs(folder:GetChildren()) do
        if Registry.IsBot(child) then
            Registry.Bots[child] = true
        end
    end
end

local function attachBots(folder)
    Registry.BotFolder = folder
    rescanBots()
    if not folder then return end
    table.insert(Registry._connections, folder.ChildAdded:Connect(function(child)
        task.defer(function()
            if Registry.IsBot(child) then Registry.Bots[child] = true end
        end)
    end))
    table.insert(Registry._connections, folder.ChildRemoved:Connect(function(child)
        Registry.Bots[child] = nil
    end))
end

local function rescanVehicles()
    table.clear(Registry.Vehicles)
    local folder = Registry.VehicleFolder
    if not folder then return end
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then Registry.Vehicles[child] = true end
    end
end

local function attachVehicles(folder)
    Registry.VehicleFolder = folder
    rescanVehicles()
    if not folder then return end
    table.insert(Registry._connections, folder.ChildAdded:Connect(function(child)
        if child:IsA("Model") then Registry.Vehicles[child] = true end
    end))
    table.insert(Registry._connections, folder.ChildRemoved:Connect(function(child)
        Registry.Vehicles[child] = nil
    end))
end

function Registry.Refresh()
    disconnectAll(Registry._connections)
    attachBots(Workspace:FindFirstChild("Players"))
    attachVehicles(Workspace:FindFirstChild("Vehicles"))
    table.insert(Registry._connections, Workspace.ChildAdded:Connect(function(child)
        if child.Name == "Players" and not Registry.BotFolder then attachBots(child) end
        if child.Name == "Vehicles" and not Registry.VehicleFolder then attachVehicles(child) end
    end))
    table.insert(Registry._connections, Workspace.ChildRemoved:Connect(function(child)
        if child == Registry.BotFolder then Registry.BotFolder = nil; table.clear(Registry.Bots) end
        if child == Registry.VehicleFolder then Registry.VehicleFolder = nil; table.clear(Registry.Vehicles) end
    end))
end

function Registry.CountBots()
    local n = 0
    for model in pairs(Registry.Bots) do
        if Registry.IsBot(model) then n += 1 else Registry.Bots[model] = nil end
    end
    return n
end

function Registry.CountVehicles()
    local n = 0
    for model in pairs(Registry.Vehicles) do
        if model and model.Parent then n += 1 else Registry.Vehicles[model] = nil end
    end
    return n
end

Registry.Refresh()
return Registry
