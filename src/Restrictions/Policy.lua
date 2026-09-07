-- LvkHub.exe centralized restrictions policy.
-- Single source of truth for target/session authorization.
local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local LP=Players.LocalPlayer

local Policy={
    Name="LvkHubRestrictions",
}

local Targets={
    Mode="TEST_DUMMIES_ONLY",
    TargetFolderName="TestPlayers",
    ManagedDummyAttribute="LvkHubManagedDummy",
}

function Targets.IsRealPlayerCharacter(model)
    if not model or not model:IsA("Model") then return false end
    local ok,p=pcall(function() return Players:GetPlayerFromCharacter(model) end)
    if ok and p then return true end
    for _,plr in ipairs(Players:GetPlayers()) do
        local ch=plr.Character
        if ch and (model==ch or model:IsDescendantOf(ch) or ch:IsDescendantOf(model)) then return true end
    end
    return false
end

function Targets.IsAllowedTarget(model)
    if not model or not model:IsA("Model") then return false end
    local folder=Workspace:FindFirstChild(Targets.TargetFolderName)
    if not folder or not model:IsDescendantOf(folder) then return false end
    if model:GetAttribute(Targets.ManagedDummyAttribute)~=true then return false end
    if Targets.IsRealPlayerCharacter(model) then return false end
    return true
end

-- Registry/visual/combat candidate enumeration comes from the policy too.
function Targets.GetCandidates()
    local out={}
    local folder=Workspace:FindFirstChild(Targets.TargetFolderName)
    if not folder then return out end
    for _,model in ipairs(folder:GetChildren()) do
        if Targets.IsAllowedTarget(model) then
            table.insert(out,model)
        end
    end
    return out
end

-- Roots whose child changes should trigger a target-index refresh.
function Targets.GetWatchRoots()
    local roots={}
    local folder=Workspace:FindFirstChild(Targets.TargetFolderName)
    if folder then table.insert(roots,folder) end
    return roots
end

function Targets.CanCloneSource(model)
    if not model or not model:IsA("Model") then return false end
    local source=Workspace:FindFirstChild("Players")
    return source~=nil and model:IsDescendantOf(source)
end

function Targets.Describe(model)
    if not model then return false,"nil target" end
    if Targets.IsRealPlayerCharacter(model) then return false,"real Player.Character excluded" end
    if not Targets.IsAllowedTarget(model) then return false,"outside managed TestPlayers policy" end
    return true,"allowed local test dummy"
end

Policy.Targets=Targets

function Policy.OtherPlayerCount()
    local n=0
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP then n+=1 end
    end
    return n
end

function Policy.SoloWeaponModsAllowed()
    return Policy.OtherPlayerCount()==0
end

function Policy.VehicleBringAllowed()
    return Policy.OtherPlayerCount()==0
end

function Policy.RealPlayerInSeat(seat)
    if not seat then return nil end
    local ok,occupant=pcall(function() return seat.Occupant end)
    if not ok or not occupant then return nil end
    local character=occupant.Parent
    if not character then return nil end
    local okPlayer,player=pcall(function() return Players:GetPlayerFromCharacter(character) end)
    if okPlayer and player then return player end
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Character==character then return p end
    end
    return nil
end

return Policy
