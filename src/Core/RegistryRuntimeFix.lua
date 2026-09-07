-- Runtime repair for the local TestPlayers registry.
-- Keeps target eligibility dummy-only and rebuilds the weak target index reliably.
return function(Registry)
    local Workspace=game:GetService("Workspace")
    local Policy=shared.LvkHubTargetRestrictions

    if not Registry then return end

    local function policyReady()
        return type(Policy)=="table"
            and Policy.Mode=="TEST_DUMMIES_ONLY"
            and type(Policy.IsAllowedTarget)=="function"
            and type(Policy.IsRealPlayerCharacter)=="function"
    end

    -- RegistryV2 previously used `return ok and result==true or true`, which
    -- evaluates to true even when the policy correctly returns false.
    function Registry.IsRealPlayerCharacter(model)
        if not policyReady() then return true end
        local ok,result=pcall(Policy.IsRealPlayerCharacter,model)
        if not ok then return true end
        return result==true
    end

    function Registry.TargetAllowed(model)
        if not policyReady() then return false end
        local ok,result=pcall(Policy.IsAllowedTarget,model)
        return ok and result==true
    end

    local function valid(model)
        if not model or not model:IsA("Model") then return false end
        if not Registry.TargetAllowed(model) then return false end
        local hum=Registry.HumanoidOf and Registry.HumanoidOf(model)
        local root=Registry.RootOf and Registry.RootOf(model)
        return hum~=nil and root~=nil and hum.Health>0
    end

    function Registry.RebuildTargetIndex()
        table.clear(Registry.Bots)
        local folder=Workspace:FindFirstChild("TestPlayers")
        if not folder then return 0 end
        local n=0
        for _,model in ipairs(folder:GetChildren()) do
            if valid(model) then
                Registry.Bots[model]=true
                n+=1
            end
        end
        return n
    end

    local originalRefresh=Registry.RefreshTargets
    function Registry.RefreshTargets()
        if type(originalRefresh)=="function" then pcall(originalRefresh) end
        return Registry.RebuildTargetIndex()
    end

    function Registry.IsBot(model)
        return model~=nil
            and model:IsDescendantOf(Workspace)
            and Registry.Bots[model]==true
            and valid(model)
    end

    function Registry.CountBots()
        local n=0
        for model in pairs(Registry.Bots) do
            if Registry.IsBot(model) then n+=1 else Registry.Bots[model]=nil end
        end
        return n
    end

    local function bindFolder(folder)
        if not folder then return end
        folder.ChildAdded:Connect(function() task.defer(Registry.RebuildTargetIndex) end)
        folder.ChildRemoved:Connect(function() task.defer(Registry.RebuildTargetIndex) end)
    end

    bindFolder(Workspace:FindFirstChild("TestPlayers"))
    Workspace.ChildAdded:Connect(function(child)
        if child.Name=="TestPlayers" then
            bindFolder(child)
            task.defer(Registry.RebuildTargetIndex)
        end
    end)

    Registry.RefreshTargets()
    task.spawn(function()
        for _,delay in ipairs({0.10,0.30,0.70,1.30,2.20}) do
            task.wait(delay)
            Registry.RefreshTargets()
        end
    end)
end
