-- LvkHub.exe shared registries
--
-- ============================================================================
-- BOT PRACTICE SESSION GUARD
-- ============================================================================
-- Target features (ESP/Aimbot/SilentAim/MagicBullets/HitBoxes) consume Registry.Bots.
-- By default, bot-practice targeting is disabled whenever another REAL Roblox Player
-- is present in Players. This is a session-level guard only.
--
-- IMPORTANT: this guard is SEPARATE from the real-player exclusion invariant below.
-- Real Player characters are NEVER inserted into Registry.Bots, even if this session
-- guard is relaxed in the future. That separation keeps the registry stable and avoids
-- accidental Player targeting.
-- ============================================================================

local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local LocalPlayer=Players.LocalPlayer

local Registry={
    Bots=setmetatable({}, {__mode="k"}),
    Vehicles=setmetatable({}, {__mode="k"}),
    VehicleFolder=nil,
    _connections={},
}

local function disconnectAll(list)
    for _,c in ipairs(list) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(list)
end

-- ============================================================================
-- SESSION-LEVEL BOT PRACTICE GUARD
-- ============================================================================
-- true  = bot targeting is disabled while another real Player is in the session.
-- false = bot targeting may continue while other Players are present, BUT the
--         real-player exclusion invariant below still keeps their characters out.
-- ============================================================================
local BLOCK_PRACTICE_WHEN_OTHER_REAL_PLAYERS=true

function Registry.HasOtherRealPlayer()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then return true end
    end
    return false
end

function Registry.PracticeAllowed()
    if not BLOCK_PRACTICE_WHEN_OTHER_REAL_PLAYERS then return true end
    return not Registry.HasOtherRealPlayer()
end

-- ============================================================================
-- REAL-PLAYER EXCLUSION INVARIANT
-- ============================================================================
-- This is deliberately independent from PracticeAllowed().
-- Any Model actually owned by Roblox Players is rejected from Registry.Bots.
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

local function candidateBot(model)
    if not Registry.PracticeAllowed() then return false end
    if not model or not model:IsA("Model") or not model:IsDescendantOf(Workspace) then return false end

    -- Hard invariant: real Player characters never become practice targets.
    if realPlayerOwned(model) then return false end
    if excludedContainer(model) then return false end

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
    if candidateBot(model) then
        Registry.Bots[model]=true
    else
        Registry.Bots[model]=nil
    end
end

local function considerObject(obj)
    if not Registry.PracticeAllowed() or not obj then return end

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
    if not Registry.PracticeAllowed() then return end

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
            if Registry.PracticeAllowed() and obj and obj.Parent then considerObject(obj) end
            if obj and obj.Parent==Registry.VehicleFolder and obj:IsA("Model") then
                Registry.Vehicles[obj]=true
            end
        end)
    end))

    table.insert(Registry._connections,Workspace.DescendantRemoving:Connect(function(obj)
        Registry.Bots[obj]=nil
        Registry.Vehicles[obj]=nil
    end))

    table.insert(Registry._connections,Workspace.ChildAdded:Connect(function(child)
        if child.Name=="Vehicles" then attachVehicles(child) end
    end))

    table.insert(Registry._connections,Workspace.ChildRemoved:Connect(function(child)
        if child==Registry.VehicleFolder then
            Registry.VehicleFolder=nil
            table.clear(Registry.Vehicles)
        end
    end))

    table.insert(Registry._connections,Players.PlayerAdded:Connect(function(p)
        if p~=LocalPlayer and BLOCK_PRACTICE_WHEN_OTHER_REAL_PLAYERS then
            table.clear(Registry.Bots)
        else
            task.defer(rescanBots)
        end
    end))

    table.insert(Registry._connections,Players.PlayerRemoving:Connect(function()
        task.defer(function()
            task.wait()
            rescanBots()
        end)
    end))
end

function Registry.CountBots()
    if not Registry.PracticeAllowed() then
        table.clear(Registry.Bots)
        return 0
    end

    local n=0
    for model in pairs(Registry.Bots) do
        if not model or not model.Parent or realPlayerOwned(model) then
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
