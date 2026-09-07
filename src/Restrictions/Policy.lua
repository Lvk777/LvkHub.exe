-- LvkHub.exe centralized restrictions policy.
-- FAIL-CLOSED: if this folder/module is absent, loader supplies a deny-all fallback.
local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local LP=Players.LocalPlayer

local Policy={
    Name="LvkHubRestrictions",
    FailClosed=true,
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
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then n+=1 end end
    return n
end

function Policy.SoloWeaponModsAllowed()
    return Policy.OtherPlayerCount()==0
end

function Policy.VehicleBringAllowed()
    return Policy.OtherPlayerCount()==0
end

return Policy
