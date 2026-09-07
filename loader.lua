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

    -- Restrictions are optional for UI loading, but targeting fails closed if the
    -- policy file is unavailable. Missing policy never falls back to real Players.
    local Restrictions=nil
    local policyOK,policyResult=pcall(function()
        return loadModule("src/Restrictions/Policy.lua")
    end)
    if policyOK and type(policyResult)=="table" and type(policyResult.Targets)=="table" then
        Restrictions=policyResult
    else
        Restrictions={
            Name="LvkHubRestrictionsFallback",
            FailClosed=true,
            Targets={
                Mode="TEST_DUMMIES_ONLY",
                IsAllowedTarget=function() return false end,
                IsRealPlayerCharacter=function() return true end,
                CanCloneSource=function() return false end,
                Describe=function() return false,"restrictions unavailable: targeting disabled" end,
            },
            OtherPlayerCount=function() return math.huge end,
            SoloWeaponModsAllowed=function() return false end,
            VehicleBringAllowed=function() return false end,
            RealPlayerInSeat=function() return true end,
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
    loadModule("src/Visuals/PreviewV11.lua")(State,Registry,UI)
    loadModule("src/Visuals/PreviewLocalPlayerV2.lua")(State,Registry,UI)
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
    loadModule("src/Local/BulletTracerV7.lua")(State,Registry,UI)
    loadModule("src/UI/LocalOrderPolish.lua")(State,UI)
    loadModule("src/Local/DummyHitSoundV2.lua")(State,Registry,UI)
    loadModule("src/Local/TrailGlow.lua")(State,Registry,UI)
    loadModule("src/Local/BringCarStudio.lua")(Registry,UI)
    loadModule("src/Vehicle/VehicleStatusPolish.lua")(State,Registry,UI)

    loadModule("src/UI/Keybinds.lua")(State,Registry,UI)
    loadModule("src/UI/DummyTargetInfo.lua")(State,Registry,UI)
    loadModule("src/UI/CompactLabels.lua")(State,UI)
    loadModule("src/UI/LocalPopupPolishV6.lua")(State,UI)
    loadModule("src/UI/FOVThermalRingV2.lua")(State,UI)
    loadModule("src/UI/SoloSurvivalToLocal.lua")(State,UI)

    loadModule("src/Core/YokaiPolish.lua")(UI)
    loadModule("src/Core/YokaiBlueTheme.lua")(UI)

    -- Final layout/docking after every frame/popup owner exists.
    loadModule("src/UI/LayoutFinalV4.lua")(State,UI)
    loadModule("src/UI/DockBelowMovementV3.lua")(State,UI)
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
