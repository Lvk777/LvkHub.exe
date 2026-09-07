-- LvkHub.exe Registry V2
-- Local practice dummies only. Real Player.Character models are never inserted into Bots.
-- Inventory Viewer reads only a snapshot stored inside each local dummy clone.

local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local LocalPlayer=Players.LocalPlayer

local Registry={
    Bots=setmetatable({}, {__mode="k"}),
    Vehicles=setmetatable({}, {__mode="k"}),
    VehicleFolder=nil,
    TestPlayersFolder=nil,
    _connections={},
}

local function disconnectAll()
    for _,c in ipairs(Registry._connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(Registry._connections)
end

function Registry.PracticeAllowed()
    return true
end

local function realPlayerOwned(model)
    if not model or not model:IsA("Model") then return false end
    local ok,p=pcall(function() return Players:GetPlayerFromCharacter(model) end)
    if ok and p then return true end
    for _,plr in ipairs(Players:GetPlayers()) do
        local ch=plr.Character
        if ch and (model==ch or model:IsDescendantOf(ch) or ch:IsDescendantOf(model)) then
            return true
        end
    end
    return false
end

function Registry.IsRealPlayerCharacter(model)
    return realPlayerOwned(model)
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

local function validRig(model)
    return model and model:IsA("Model")
        and model:FindFirstChildOfClass("Humanoid")~=nil
        and Registry.RootOf(model)~=nil
end

local function ensureTestFolder()
    local f=Workspace:FindFirstChild("TestPlayers")
    if not f then
        f=Instance.new("Folder")
        f.Name="TestPlayers"
        f:SetAttribute("LvkHubManagedFolder",true)
        f.Parent=Workspace
    end
    Registry.TestPlayersFolder=f
    return f
end

local function sourceFolder()
    local f=Workspace:FindFirstChild("Players")
    if f and (f:IsA("Folder") or f:IsA("Model")) then return f end
    return nil
end

local function inventorySnapshotFromClone(clone)
    local names={}
    local seen={}
    for _,d in ipairs(clone:GetDescendants()) do
        if d:IsA("Tool") and not seen[d.Name] then
            seen[d.Name]=true
            table.insert(names,d.Name)
            if #names>=4 then break end
        end
    end

    local folder=Instance.new("Folder")
    folder.Name="LvkHubDummyInventory"
    folder:SetAttribute("LvkHubLocalSnapshot",true)
    folder.Parent=clone

    for i=1,4 do
        local slot=Instance.new("StringValue")
        slot.Name="Slot"..i
        slot.Value=names[i] or "Empty"
        slot.Parent=folder
    end
end

local function sanitizeClone(clone)
    inventorySnapshotFromClone(clone)
    for _,d in ipairs(clone:GetDescendants()) do
        if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
            d:Destroy()
        elseif d:IsA("Tool") then
            d:Destroy()
        elseif d:IsA("BasePart") then
            d.Anchored=true
            d.CanCollide=false
            d.CanTouch=false
            d.Massless=true
        end
    end
end

local function placement(index)
    local ch=LocalPlayer.Character
    local root=ch and ch:FindFirstChild("HumanoidRootPart")
    if root then
        local col=(index-1)%4
        local row=math.floor((index-1)/4)
        return root.CFrame*CFrame.new((col-1.5)*6,0,-18-row*7)
    end
    return CFrame.new(index*6,10,0)
end

local function cloneRig(source,index)
    local old=source.Archivable
    source.Archivable=true
    local ok,clone=pcall(function() return source:Clone() end)
    source.Archivable=old
    if not ok or not clone then return nil end

    clone.Name="TEST_"..source.Name
    clone:SetAttribute("LvkHubManagedDummy",true)
    clone:SetAttribute("LvkHubSourceName",source.Name)
    sanitizeClone(clone)
    clone.Parent=ensureTestFolder()
    pcall(function() clone:PivotTo(placement(index)) end)
    return clone
end

local syncing=false
local function syncClones()
    if syncing then return end
    syncing=true

    local folder=ensureTestFolder()
    local src=sourceFolder()
    local ordered={}
    local wantedByName={}
    if src then
        for _,m in ipairs(src:GetChildren()) do
            if validRig(m) then
                table.insert(ordered,m)
                wantedByName[m.Name]=m
            end
        end
    end
    table.sort(ordered,function(a,b) return string.lower(a.Name)<string.lower(b.Name) end)

    local existingByName={}
    for _,m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") and m:GetAttribute("LvkHubManagedDummy")==true then
            local sourceName=m:GetAttribute("LvkHubSourceName")
            if type(sourceName)=="string" and wantedByName[sourceName] and not existingByName[sourceName] then
                existingByName[sourceName]=m
            else
                m:Destroy()
            end
        end
    end

    for i,source in ipairs(ordered) do
        local clone=existingByName[source.Name]
        if not clone or not clone.Parent then
            clone=cloneRig(source,i)
            existingByName[source.Name]=clone
        end
    end

    syncing=false
end

local function rebuildBots()
    table.clear(Registry.Bots)
    local folder=ensureTestFolder()
    for _,m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") and m:GetAttribute("LvkHubManagedDummy")==true and validRig(m) and not realPlayerOwned(m) then
            local hum=Registry.HumanoidOf(m)
            if hum and hum.Health>0 then Registry.Bots[m]=true end
        end
    end
end

function Registry.RefreshTargets()
    syncClones()
    rebuildBots()
end

function Registry.IsBot(model)
    return model~=nil
        and Registry.Bots[model]==true
        and model:IsDescendantOf(Workspace)
        and not realPlayerOwned(model)
end

function Registry.CountBots()
    local n=0
    for m in pairs(Registry.Bots) do
        if Registry.IsBot(m) then n+=1 else Registry.Bots[m]=nil end
    end
    return n
end

function Registry.GetDummyInventory(model)
    local slots={"Empty","Empty","Empty","Empty"}
    if not Registry.IsBot(model) then return slots end
    local folder=model:FindFirstChild("LvkHubDummyInventory")
    if not folder then return slots end
    for i=1,4 do
        local v=folder:FindFirstChild("Slot"..i)
        if v and v:IsA("StringValue") then slots[i]=v.Value end
    end
    return slots
end

local function rescanVehicles()
    table.clear(Registry.Vehicles)
    Registry.VehicleFolder=Workspace:FindFirstChild("Vehicles")
    if not Registry.VehicleFolder then return end
    for _,m in ipairs(Registry.VehicleFolder:GetChildren()) do
        if m:IsA("Model") then Registry.Vehicles[m]=true end
    end
end

function Registry.CountVehicles()
    local n=0
    for m in pairs(Registry.Vehicles) do
        if m and m.Parent then n+=1 else Registry.Vehicles[m]=nil end
    end
    return n
end

function Registry.Refresh()
    disconnectAll()
    Registry.RefreshTargets()
    rescanVehicles()

    local src=sourceFolder()
    if src then
        table.insert(Registry._connections,src.ChildAdded:Connect(function() task.defer(Registry.RefreshTargets) end))
        table.insert(Registry._connections,src.ChildRemoved:Connect(function() task.defer(Registry.RefreshTargets) end))
    end

    local tf=ensureTestFolder()
    table.insert(Registry._connections,tf.ChildAdded:Connect(function()
        if not syncing then task.defer(rebuildBots) end
    end))
    table.insert(Registry._connections,tf.ChildRemoved:Connect(function()
        if not syncing then task.defer(rebuildBots) end
    end))

    table.insert(Registry._connections,Workspace.ChildAdded:Connect(function(child)
        if child.Name=="Players" then task.defer(Registry.Refresh)
        elseif child.Name=="Vehicles" then task.defer(rescanVehicles) end
    end))
    table.insert(Registry._connections,Workspace.ChildRemoved:Connect(function(child)
        if child==Registry.VehicleFolder then Registry.VehicleFolder=nil; table.clear(Registry.Vehicles) end
    end))

    table.insert(Registry._connections,Players.PlayerAdded:Connect(function() task.defer(Registry.RefreshTargets) end))
    table.insert(Registry._connections,Players.PlayerRemoving:Connect(function() task.defer(Registry.RefreshTargets) end))
end

Registry.Refresh()
return Registry
