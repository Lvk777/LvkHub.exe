-- LvkHub.exe shared registries
--
-- ============================================================================
-- TEST PLAYER TARGET SOURCE (DUMMIES / NPCs ONLY)
-- ============================================================================
-- Combat + Visuals continue to consume Registry.Bots for compatibility, but that
-- table is now populated ONLY from Workspace.TestPlayers.
--
-- Workspace.TestPlayers can contain:
--   1) NPC/dummy Models directly, or
--   2) ObjectValues whose Value points to an NPC/dummy Model elsewhere in Workspace.
--
-- For GunTesting, this module creates client-side ObjectValue references for the
-- non-player rigs found directly under Workspace.Players. This gives the rest of
-- the hub a Player-style target list without ever using Roblox Player.Character
-- objects as targets.
--
-- HARD SAFETY INVARIANT:
-- Any Model owned by the Roblox Players service is rejected from Registry.Bots.
-- This check is independent from folder names and remains active at all times.
-- ============================================================================

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

local function disconnectAll(list)
    for _,c in ipairs(list) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(list)
end

function Registry.HasOtherRealPlayer()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then return true end
    end
    return false
end

-- TestPlayers is safe to keep active even when real Players are in the server,
-- because real Player.Character models are filtered independently below.
function Registry.PracticeAllowed()
    return true
end

-- ============================================================================
-- REAL-PLAYER EXCLUSION INVARIANT
-- ============================================================================
-- This is the authoritative distinction between a real Roblox Player character
-- and a player-shaped NPC/dummy. Real Player characters NEVER enter Registry.Bots.
-- ============================================================================
local function realPlayerOwned(model)
    if not model or not model:IsA("Model") then return false end

    local ok,p=pcall(function()
        return Players:GetPlayerFromCharacter(model)
    end)
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

local function excludedContainer(model)
    local cur=model
    while cur and cur~=Workspace do
        local n=string.lower(cur.Name)
        if n:find("corpse",1,true) or n=="playercorpses" or n=="grounditems" then
            return true
        end
        if Registry.VehicleFolder and (cur==Registry.VehicleFolder or cur:IsDescendantOf(Registry.VehicleFolder)) then
            return true
        end
        cur=cur.Parent
    end
    return false
end

local function validTestTarget(model)
    if not model or not model:IsA("Model") or not model:IsDescendantOf(Workspace) then return false end
    if realPlayerOwned(model) or excludedContainer(model) then return false end
    local hum=Registry.HumanoidOf(model)
    local root=Registry.RootOf(model)
    return hum~=nil and root~=nil and hum.Health>0
end

function Registry.IsBot(model)
    return validTestTarget(model) and Registry.Bots[model]==true
end

local function ensureTestPlayersFolder()
    local folder=Workspace:FindFirstChild("TestPlayers")
    if not folder then
        folder=Instance.new("Folder")
        folder.Name="TestPlayers"
        folder:SetAttribute("LvkHubManagedFolder",true)
        folder.Parent=Workspace
    end
    Registry.TestPlayersFolder=folder
    return folder
end

local mirrorBusy=false
local function sourceBotFolder()
    local f=Workspace:FindFirstChild("Players")
    return (f and f:IsA("Folder")) and f or nil
end

local function syncManagedReferences()
    if mirrorBusy then return end
    mirrorBusy=true

    local testFolder=ensureTestPlayersFolder()
    local source=sourceBotFolder()
    local wanted=setmetatable({}, {__mode="k"})

    if source then
        for _,m in ipairs(source:GetChildren()) do
            if m:IsA("Model") and validTestTarget(m) then
                wanted[m]=true
            end
        end
    end

    local existing=setmetatable({}, {__mode="k"})
    for _,entry in ipairs(testFolder:GetChildren()) do
        if entry:IsA("ObjectValue") and entry:GetAttribute("LvkHubManaged")==true then
            local model=entry.Value
            if model and wanted[model] and validTestTarget(model) then
                existing[model]=entry
                if entry.Name~=model.Name then entry.Name=model.Name end
            else
                entry:Destroy()
            end
        end
    end

    for model in pairs(wanted) do
        if not existing[model] then
            local ref=Instance.new("ObjectValue")
            ref.Name=model.Name
            ref.Value=model
            ref:SetAttribute("LvkHubManaged",true)
            ref.Parent=testFolder
        end
    end

    mirrorBusy=false
end

local function resolveTestEntry(entry)
    if not entry then return nil end
    if entry:IsA("Model") then
        return validTestTarget(entry) and entry or nil
    end
    if entry:IsA("ObjectValue") then
        local model=entry.Value
        return validTestTarget(model) and model or nil
    end
    return nil
end

local function rebuildTargets()
    table.clear(Registry.Bots)
    local folder=ensureTestPlayersFolder()
    for _,entry in ipairs(folder:GetChildren()) do
        local model=resolveTestEntry(entry)
        if model then Registry.Bots[model]=true end
    end
end

function Registry.RefreshTargets()
    syncManagedReferences()
    rebuildTargets()
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

local function attachPlayerCharacterRefresh(player)
    table.insert(Registry._connections,player.CharacterAdded:Connect(function()
        task.defer(Registry.RefreshTargets)
    end))
    table.insert(Registry._connections,player.CharacterRemoving:Connect(function()
        task.defer(Registry.RefreshTargets)
    end))
end

function Registry.Refresh()
    disconnectAll(Registry._connections)

    attachVehicles(Workspace:FindFirstChild("Vehicles"))
    Registry.RefreshTargets()

    local testFolder=ensureTestPlayersFolder()
    table.insert(Registry._connections,testFolder.ChildAdded:Connect(function()
        if not mirrorBusy then task.defer(rebuildTargets) end
    end))
    table.insert(Registry._connections,testFolder.ChildRemoved:Connect(function()
        if not mirrorBusy then task.defer(rebuildTargets) end
    end))

    local source=sourceBotFolder()
    if source then
        table.insert(Registry._connections,source.ChildAdded:Connect(function() task.defer(Registry.RefreshTargets) end))
        table.insert(Registry._connections,source.ChildRemoved:Connect(function() task.defer(Registry.RefreshTargets) end))
    end

    table.insert(Registry._connections,Workspace.ChildAdded:Connect(function(child)
        if child.Name=="Vehicles" then
            attachVehicles(child)
        elseif child.Name=="Players" or child.Name=="TestPlayers" then
            task.defer(Registry.Refresh)
        end
    end))

    table.insert(Registry._connections,Workspace.ChildRemoved:Connect(function(child)
        if child==Registry.VehicleFolder then
            Registry.VehicleFolder=nil
            table.clear(Registry.Vehicles)
        end
        if child==Registry.TestPlayersFolder or child.Name=="Players" then
            task.defer(Registry.Refresh)
        end
    end))

    table.insert(Registry._connections,Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Humanoid") or obj.Name=="HumanoidRootPart" or obj.Name=="Head" then
            local sourceNow=sourceBotFolder()
            if sourceNow and obj:IsDescendantOf(sourceNow) then task.defer(Registry.RefreshTargets) end
        end
        if obj and obj.Parent==Registry.VehicleFolder and obj:IsA("Model") then
            Registry.Vehicles[obj]=true
        end
    end))

    table.insert(Registry._connections,Workspace.DescendantRemoving:Connect(function(obj)
        Registry.Bots[obj]=nil
        Registry.Vehicles[obj]=nil
    end))

    table.insert(Registry._connections,Players.PlayerAdded:Connect(function(p)
        attachPlayerCharacterRefresh(p)
        task.defer(Registry.RefreshTargets)
    end))
    table.insert(Registry._connections,Players.PlayerRemoving:Connect(function()
        task.defer(Registry.RefreshTargets)
    end))
    for _,p in ipairs(Players:GetPlayers()) do attachPlayerCharacterRefresh(p) end
end

function Registry.CountBots()
    local n=0
    for model in pairs(Registry.Bots) do
        if not validTestTarget(model) then
            Registry.Bots[model]=nil
        else
            n+=1
        end
    end
    return n
end

function Registry.CountVehicles()
    local n=0
    for model in pairs(Registry.Vehicles) do
        if model and model.Parent then
            n+=1
        else
            Registry.Vehicles[model]=nil
        end
    end
    return n
end

Registry.Refresh()
return Registry
