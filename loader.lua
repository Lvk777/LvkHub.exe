-- LvkHub.exe loader
if shared.LvkHubExeLoaded then
    local ok,parent=pcall(function() return (gethui and gethui()) or game:GetService("CoreGui") end)
    if ok and parent then
        local gui=parent:FindFirstChild("LvkHubExe")
        if gui and gui:FindFirstChild("Main") then gui.Main.Visible=not gui.Main.Visible end
    end
    return
end
shared.LvkHubExeLoaded=true

local BASE="https://raw.githubusercontent.com/Lvk777/LvkHub.exe/main/"
local function loadModule(path)
    local src=game:HttpGet(BASE..path,true)
    local fn,err=loadstring(src)
    if not fn then error("LvkHub compile error in "..path..": "..tostring(err)) end
    return fn()
end

local ok,err=pcall(function()
    local State=loadModule("src/Core/State.lua")

    -- Policy is the normal source of target/session authorization.
    -- If the file is missing, the hub keeps working in LOCAL TEST-DUMMY mode
    -- instead of switching to real Player.Character targets.
    local Restrictions=nil
    local policyOK,policyResult=pcall(function()
        return loadModule("src/Restrictions/Policy.lua")
    end)
    if policyOK and type(policyResult)=="table" and type(policyResult.Targets)=="table" then
        Restrictions=policyResult
    end
    if not Restrictions then
        local Players=game:GetService("Players")
        local Workspace=game:GetService("Workspace")
        local LP=Players.LocalPlayer

        local LocalTargets={
            Mode="TEST_DUMMIES_ONLY",
            TargetFolderName="TestPlayers",
            ManagedDummyAttribute="LvkHubManagedDummy",
        }

        function LocalTargets.IsRealPlayerCharacter(model)
            if not model or not model:IsA("Model") then return false end
            local okPlayer,player=pcall(function() return Players:GetPlayerFromCharacter(model) end)
            if okPlayer and player then return true end
            for _,p in ipairs(Players:GetPlayers()) do
                local ch=p.Character
                if ch and (model==ch or model:IsDescendantOf(ch) or ch:IsDescendantOf(model)) then return true end
            end
            return false
        end

        function LocalTargets.IsAllowedTarget(model)
            if not model or not model:IsA("Model") then return false end
            local folder=Workspace:FindFirstChild(LocalTargets.TargetFolderName)
            if not folder or not model:IsDescendantOf(folder) then return false end
            if model:GetAttribute(LocalTargets.ManagedDummyAttribute)~=true then return false end
            return not LocalTargets.IsRealPlayerCharacter(model)
        end

        function LocalTargets.CanCloneSource(model)
            if not model or not model:IsA("Model") then return false end
            local source=Workspace:FindFirstChild("Players")
            return source~=nil and model:IsDescendantOf(source)
        end

        function LocalTargets.GetCandidates()
            local out={}
            local folder=Workspace:FindFirstChild(LocalTargets.TargetFolderName)
            if folder then
                for _,m in ipairs(folder:GetChildren()) do
                    if LocalTargets.IsAllowedTarget(m) then table.insert(out,m) end
                end
            end
            return out
        end

        function LocalTargets.GetWatchRoots()
            local roots={}
            local f=Workspace:FindFirstChild(LocalTargets.TargetFolderName)
            if f then table.insert(roots,f) end
            return roots
        end

        function LocalTargets.Describe(model)
            if LocalTargets.IsAllowedTarget(model) then return true,"allowed local test dummy (fallback)" end
            if LocalTargets.IsRealPlayerCharacter(model) then return false,"real Player.Character excluded" end
            return false,"outside managed TestPlayers fallback"
        end

        Restrictions={
            Name="LvkHubLocalPracticeFallback",
            FailClosed=false,
            Targets=LocalTargets,
            OtherPlayerCount=function()
                local n=0
                for _,p in ipairs(Players:GetPlayers()) do if p~=LP then n+=1 end end
                return n
            end,
            SoloWeaponModsAllowed=function() return false end,
            VehicleBringAllowed=function() return false end,
            RealPlayerInSeat=function(seat)
                if not seat then return nil end
                local okOcc,occupant=pcall(function() return seat.Occupant end)
                if not okOcc or not occupant then return nil end
                return Players:GetPlayerFromCharacter(occupant.Parent)
            end,
        }
    end
    shared.LvkHubRestrictions=Restrictions
    shared.LvkHubTargetRestrictions=Restrictions.Targets

    local Registry=loadModule("src/Core/RegistryV2.lua")
    loadModule("src/Core/RegistryBootstrap.lua")(Registry)
    loadModule("src/Core/RegistryRuntimeFix.lua")(Registry)

    local MakeUI=loadModule("src/UI/Main.lua")
    local UI=MakeUI(State)
    loadModule("src/UI/Enhancements.lua")(State,UI)

    loadModule("src/Combat/MainV4.lua")(State,Registry,UI)
    loadModule("src/Combat/WeaponSystemDummyAdapterV3.lua")(State,Registry,UI)
    loadModule("src/Combat/SoloWeaponMods.lua")(State,Registry,UI)
    loadModule("src/Combat/SoloNoSpread.lua")(State,Registry,UI)
    loadModule("src/Combat/DummyHitFeedbackV4.lua")(State,Registry,UI)

    loadModule("src/Movement/MainV2.lua")(State,Registry,UI)

    loadModule("src/Visuals/UnifiedTestVisualsV5.lua")(State,Registry,UI)
    loadModule("src/Visuals/ChamsWallCheckV1.lua")(State,Registry,UI)
    loadModule("src/Visuals/PreviewV11.lua")(State,Registry,UI)
    loadModule("src/Visuals/PreviewLocalPlayerV3.lua")(State,Registry,UI)
    loadModule("src/Visuals/PracticeOverlayV2.lua")(State,Registry,UI)

    loadModule("src/Vehicle/Main.lua")(State,Registry,UI)

    loadModule("src/Utility/Main.lua")(State,Registry,UI)
    loadModule("src/Utility/Presets.lua")(State,Registry,UI)
    loadModule("src/Utility/SoloSurvivalV2.lua")(State,Registry,UI)
    loadModule("src/World/Main.lua")(State,Registry,UI)

    loadModule("src/Local/MainV4.lua")(State,Registry,UI)
    loadModule("src/Local/ChamsMaterialV1.lua")(State,Registry,UI)
    loadModule("src/Local/MuteGunshotsV4.lua")(State,Registry,UI)
    loadModule("src/Local/GunshotReplacementV1.lua")(State,Registry,UI)
    loadModule("src/Local/BulletTracerV8.lua")(State,Registry,UI)
    loadModule("src/UI/LocalOrderPolish.lua")(State,UI)
    loadModule("src/Local/DummyHitSoundV2.lua")(State,Registry,UI)
    loadModule("src/Local/TrailGlow.lua")(State,Registry,UI)
    loadModule("src/Local/BringCarStudio.lua")(Registry,UI)
    loadModule("src/Vehicle/VehicleStatusPolish.lua")(State,Registry,UI)

    loadModule("src/UI/Keybinds.lua")(State,Registry,UI)
    loadModule("src/UI/DummyTargetInfo.lua")(State,Registry,UI)
    loadModule("src/UI/CompactLabels.lua")(State,UI)
    loadModule("src/UI/LocalPopupPolishV6.lua")(State,UI)
    loadModule("src/UI/FOVThermalRingV3.lua")(State,UI)
    loadModule("src/UI/SoloSurvivalToLocal.lua")(State,UI)

    loadModule("src/Core/YokaiPolish.lua")(UI)
    loadModule("src/Core/YokaiBlueTheme.lua")(UI)

    -- Final layout/docking after every frame/popup owner exists.
    loadModule("src/UI/LayoutFinalV4.lua")(State,UI)
    loadModule("src/UI/DockBelowMovementV4.lua")(State,UI)
    loadModule("src/UI/DragPolishV2.lua")(State,UI)
    loadModule("src/UI/WatermarkV4.lua")(State,UI)

    shared.LvkHubExe={
        State=State,
        Registry=Registry,
        UI=UI,
        Restrictions=Restrictions,
        TargetRestrictions=Restrictions.Targets,
    }
end)

if not ok then
    shared.LvkHubExeLoaded=nil
    warn("[LvkHub.exe] load failed: "..tostring(err))
end
