-- LvkHub.exe V2 standalone policy
-- This file is intentionally independent from src/Restrictions/Policy.lua.
-- It authorizes only local managed practice dummies and keeps session-sensitive
-- features gated to LocalPlayer-only sessions.

local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local LP=Players.LocalPlayer

local Policy={
    Name="LvkHubV2StandalonePolicy",
    Version=2,
    Independent=true,
}

local Targets={
    Mode="TEST_DUMMIES_ONLY",
    TargetFolderName="TestPlayers",
    ManagedDummyAttribute="LvkHubManagedDummy",
    CandidateKind="practice_dummy",
}

function Targets.IsRealPlayerCharacter(model)
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

function Targets.CanCloneSource(model)
    if not model or not model:IsA("Model") then return false end
    local source=Workspace:FindFirstChild("Players")
    return source~=nil and model:IsDescendantOf(source)
end

function Targets.IsAllowedTarget(model)
    if not model or not model:IsA("Model") then return false end
    if Targets.IsRealPlayerCharacter(model) then return false end

    local folder=Workspace:FindFirstChild(Targets.TargetFolderName)
    if not folder or not model:IsDescendantOf(folder) then return false end
    if model:GetAttribute(Targets.ManagedDummyAttribute)~=true then return false end

    local kind=model:GetAttribute("LvkHubCandidateKind")
    return kind==nil or kind==Targets.CandidateKind
end

function Targets.Describe(model)
    if Targets.IsAllowedTarget(model) then
        return true,"V2 standalone local practice target"
    end
    if Targets.IsRealPlayerCharacter(model) then
        return false,"real Player.Character excluded"
    end
    return false,"outside V2 standalone practice policy"
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
    local ch=occupant.Parent
    if not ch then return nil end
    local okPlayer,p=pcall(function() return Players:GetPlayerFromCharacter(ch) end)
    return okPlayer and p or nil
end

return Policy
