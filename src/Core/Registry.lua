-- LvkHub.exe shared registries
-- Bots: non-player Humanoid rigs anywhere in Workspace. Real Roblox Player characters
-- and player-named proxy rigs are always excluded. Vehicles: Models inside Workspace.Vehicles.

local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")

local Registry={
    Bots=setmetatable({}, {__mode="k"}),
    Vehicles=setmetatable({}, {__mode="k"}),
    VehicleFolder=nil,
    _connections={},
}

local function disconnectAll(list)
    for _,c in ipairs(list) do pcall(function() c:Disconnect() end) end
    table.clear(list)
end

local function playerOwned(model)
    if not model or not model:IsA("Model") then return false end
    local ok,plr=pcall(function() return Players:GetPlayerFromCharacter(model) end)
    if ok and plr then return true end

    local modelName=string.lower(model.Name)
    local hum=model:FindFirstChildOfClass("Humanoid")
    local displayName=hum and string.lower(hum.DisplayName or "") or ""
    for _,p in ipairs(Players:GetPlayers()) do
        local char=p.Character
        if char and (model==char or model:IsDescendantOf(char) or char:IsDescendantOf(model)) then return true end
        local pn=string.lower(p.Name)
        local pd=string.lower(p.DisplayName or "")
        if modelName==pn or (pd~="" and modelName==pd) then return true end
        if displayName~="" and (displayName==pn or (pd~="" and displayName==pd)) then return true end
    end
    return false
end

function Registry.IsRealPlayerCharacter(model)
    return playerOwned(model)
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

local function excludedContainer(model)
    local cur=model
    while cur and cur~=Workspace do
        local n=string.lower(cur.Name)
        if n:find("corpse",1,true) or n=="playercorpses" or n=="grounditems" then return true end
        if Registry.VehicleFolder and (cur==Registry.VehicleFolder or cur:IsDescendantOf(Registry.VehicleFolder)) then return true end
        cur=cur.Parent
    end
    return false
end

local function candidateBot(model)
    if not model or not model:IsA("Model") or not model:IsDescendantOf(Workspace) then return false end
    if playerOwned(model) or excludedContainer(model) then return false end
    local hum=Registry.HumanoidOf(model)
    local root=Registry.RootOf(model)
    return hum~=nil and root~=nil
end

function Registry.IsBot(model)
    if not candidateBot(model) then return false end
    local hum=Registry.HumanoidOf(model)
    return hum and hum.Health>0 or false
end

local function considerModel(model)
    if candidateBot(model) then Registry.Bots[model]=true end
end

local function considerObject(obj)
    if not obj then return end
    if obj:IsA("Model") then considerModel(obj) end
    local cur=obj.Parent
    local depth=0
    while cur and cur~=Workspace and depth<8 do
        if cur:IsA("Model") then considerModel(cur) end
        cur=cur.Parent
        depth+=1
    end
end

local function rescanBots()
    table.clear(Registry.Bots)
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then considerModel(obj) end
    end
end

local function rescanVehicles()
    table.clear(Registry.Vehicles)
    local folder=Registry.VehicleFolder
    if not folder then return end
    for _,child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then Registry.Vehicles[child]=true end
    end
end

local function attachVehicles(folder)
    Registry.VehicleFolder=folder
    rescanVehicles()
end

function Registry.Refresh()
    disconnectAll(Registry._connections)
    attachVehicles(Workspace:FindFirstChild("Vehicles"))
    rescanBots()

    table.insert(Registry._connections,Workspace.DescendantAdded:Connect(function(obj)
        task.defer(function()
            if obj and obj.Parent then considerObject(obj) end
            if obj and obj.Parent==Registry.VehicleFolder and obj:IsA("Model") then Registry.Vehicles[obj]=true end
        end)
    end))
    table.insert(Registry._connections,Workspace.DescendantRemoving:Connect(function(obj)
        if Registry.Bots[obj] then Registry.Bots[obj]=nil end
        if Registry.Vehicles[obj] then Registry.Vehicles[obj]=nil end
    end))
    table.insert(Registry._connections,Workspace.ChildAdded:Connect(function(child)
        if child.Name=="Vehicles" then attachVehicles(child) end
    end))
    table.insert(Registry._connections,Workspace.ChildRemoved:Connect(function(child)
        if child==Registry.VehicleFolder then Registry.VehicleFolder=nil; table.clear(Registry.Vehicles) end
    end))
    table.insert(Registry._connections,Players.PlayerAdded:Connect(function() task.defer(rescanBots) end))
    table.insert(Registry._connections,Players.PlayerRemoving:Connect(function() task.defer(rescanBots) end))
end

function Registry.CountBots()
    local n=0
    for model in pairs(Registry.Bots) do
        if not model or not model.Parent or playerOwned(model) then
            Registry.Bots[model]=nil
        elseif Registry.IsBot(model) then
            n+=1
        end
    end
    return n
end

function Registry.CountVehicles()
    local n=0
    for model in pairs(Registry.Vehicles) do
        if model and model.Parent then n+=1 else Registry.Vehicles[model]=nil end
    end
    return n
end

Registry.Refresh()
return Registry
