-- LvkHub.exe TARGET RESTRICTIONS
-- ============================================================================
-- EDUCATIONAL / AUDITABLE TARGET POLICY
--
-- This file contains the target-selection restrictions used by RegistryV2.
-- Combat and Visuals consume Registry.Bots; they do not build real-player
-- target lists themselves.
--
-- IMPORTANT FAIL-CLOSED DESIGN:
-- If this policy is missing or fails to load, RegistryV2 registers ZERO targets.
-- Removing this file does NOT fall back to Players/GetPlayers targeting.
-- ============================================================================

local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")

local Policy={
    Name="LvkHubTargetRestrictions",
    Mode="TEST_DUMMIES_ONLY",
    FailClosed=true,
    TargetFolderName="TestPlayers",
    ManagedDummyAttribute="LvkHubManagedDummy",
}

-- ============================================================================
-- >>> REAL PLAYER CHARACTER EXCLUSION <<<
-- Any Model owned by a Roblox Player is rejected as a target.
-- ============================================================================
function Policy.IsRealPlayerCharacter(model)
    if not model or not model:IsA("Model") then return false end

    local ok,player=pcall(function()
        return Players:GetPlayerFromCharacter(model)
    end)
    if ok and player then return true end

    for _,plr in ipairs(Players:GetPlayers()) do
        local character=plr.Character
        if character and (
            model==character
            or model:IsDescendantOf(character)
            or character:IsDescendantOf(model)
        ) then
            return true
        end
    end

    return false
end

-- ============================================================================
-- >>> ONLY LOCAL MANAGED TEST DUMMIES MAY ENTER Registry.Bots <<<
-- ============================================================================
function Policy.IsAllowedTarget(model)
    if not model or not model:IsA("Model") then return false end

    local folder=Workspace:FindFirstChild(Policy.TargetFolderName)
    if not folder then return false end
    if not model:IsDescendantOf(folder) then return false end
    if model:GetAttribute(Policy.ManagedDummyAttribute)~=true then return false end
    if Policy.IsRealPlayerCharacter(model) then return false end

    return true
end

-- Source rigs may be copied into local TestPlayers dummies. They are never
-- registered directly as targets; only the sanitized clone can pass above.
function Policy.CanCloneSource(model)
    if not model or not model:IsA("Model") then return false end
    local source=Workspace:FindFirstChild("Players")
    if not source then return false end
    return model.Parent==source or model:IsDescendantOf(source)
end

function Policy.Describe(model)
    if not model then return false,"nil target" end
    if Policy.IsRealPlayerCharacter(model) then return false,"real Player.Character excluded" end
    local folder=Workspace:FindFirstChild(Policy.TargetFolderName)
    if not folder or not model:IsDescendantOf(folder) then return false,"outside Workspace.TestPlayers" end
    if model:GetAttribute(Policy.ManagedDummyAttribute)~=true then return false,"not an LvkHub managed dummy" end
    return true,"allowed local test dummy"
end

return Policy
