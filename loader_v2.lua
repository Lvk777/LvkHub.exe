-- LvkHub.exe V2 STANDALONE LOADER
-- Independent entry point: does NOT load src/Restrictions/Policy.lua and does
-- not call loader.lua. It uses v2/Policy.lua directly.
-- Run V2 by itself in a fresh session; do not run main + V2 together.

if shared.LvkHubV2Loaded then
    if shared.LvkHubV2StartupHidden==true then return end
    local CoreGui=game:GetService("CoreGui")
    local ok,parent=pcall(function() return (gethui and gethui()) or CoreGui end)
    if ok and parent then
        local gui=parent:FindFirstChild("LvkHubExe")
        if gui and gui:FindFirstChild("Main") then
            gui.Main.Visible=not gui.Main.Visible
        end
    end
    return
end

-- Prevent two complete runtimes from owning the same GUI/render bindings.
if shared.LvkHubExeLoaded then
    warn("[LvkHub V2] main runtime is already loaded. Rejoin and run loader_v2.lua by itself.")
    return
end

shared.LvkHubV2Loaded=true
shared.LvkHubV2StartupHidden=true

local RunService=game:GetService("RunService")
local CoreGui=game:GetService("CoreGui")
local BASE="https://raw.githubusercontent.com/Lvk777/LvkHub.exe/main/"

local function loadModule(path)
    local src=game:HttpGet(BASE..path,true)
    local fn,err=loadstring(src)
    if not fn then
        error("LvkHub V2 compile error in "..path..": "..tostring(err))
    end
    return fn()
end

local function uiParent()
    local ok,parent=pcall(function() return (gethui and gethui()) or CoreGui end)
    return ok and parent or CoreGui
end

local ok,err=pcall(function()
    ------------------------------------------------------------------------
    -- V2 OWNERSHIP
    -- State + Policy + Registry + TargetProvider are assembled here without
    -- depending on loader.lua or src/Restrictions/Policy.lua.
    ------------------------------------------------------------------------
    local State=loadModule("src/Core/State.lua")
    local Restrictions=loadModule("v2/Policy.lua")
    assert(type(Restrictions)=="table" and type(Restrictions.Targets)=="table","invalid V2 policy")

    shared.LvkHubV2Restrictions=Restrictions
    shared.LvkHubV2TargetRestrictions=Restrictions.Targets

    -- Compatibility globals are intentionally supplied because some current
    -- local/solo modules read them. V2 remains the owner of these globals for
    -- the lifetime of this standalone runtime.
    shared.LvkHubRestrictions=Restrictions
    shared.LvkHubTargetRestrictions=Restrictions.Targets

    local MakeRegistry=loadModule("src/Core/RegistryV3.lua")
    local Registry=MakeRegistry(Restrictions.Targets)

    local MakeTargetProvider=loadModule("src/Core/TargetProvider.lua")
    local TargetProvider=MakeTargetProvider(Registry,Restrictions.Targets)
    shared.LvkHubV2TargetProvider=TargetProvider
    shared.LvkHubTargetProvider=TargetProvider

    ------------------------------------------------------------------------
    -- UI
    ------------------------------------------------------------------------
    local MakeUI=loadModule("src/UI/Main.lua")
    local UI=MakeUI(State)
    UI.Gui.Enabled=false
    UI.Main.Visible=true
    State.UI.Visible=true

    loadModule("src/UI/Enhancements.lua")(State,UI)

    ------------------------------------------------------------------------
    -- COMBAT / PRACTICE TARGETS
    ------------------------------------------------------------------------
    loadModule("src/Combat/MainV4.lua")(State,TargetProvider,UI)

    local startupFov=uiParent():FindFirstChild("LvkHubAimFOV")
    if startupFov and startupFov:IsA("ScreenGui") then startupFov.Enabled=false end

    loadModule("src/UI/FOVBorderPolish.lua")(State,UI)
    local LegacyPracticeAdapter=loadModule("src/Combat/WeaponSystemDummyAdapterV3.lua")
    loadModule("src/Combat/WeaponSystemTargetAdapterV4.lua")(State,TargetProvider,UI,LegacyPracticeAdapter)

    ------------------------------------------------------------------------
    -- LOCAL / SOLO FEATURES
    ------------------------------------------------------------------------
    loadModule("src/Combat/SoloWeaponMods.lua")(State,Registry,UI)
    loadModule("src/Combat/SoloNoSpread.lua")(State,Registry,UI)
    loadModule("src/Movement/MainV2.lua")(State,Registry,UI)

    ------------------------------------------------------------------------
    -- VISUALS
    ------------------------------------------------------------------------
    loadModule("src/Visuals/UnifiedTestVisualsV5.lua")(State,TargetProvider,UI)
    loadModule("src/Visuals/ChamsWallCheckV1.lua")(State,TargetProvider,UI)
    loadModule("src/Visuals/PreviewV11.lua")(State,TargetProvider,UI)
    loadModule("src/Visuals/PreviewLocalPlayerV3.lua")(State,TargetProvider,UI)
    loadModule("src/Visuals/PracticeOverlayV2.lua")(State,TargetProvider,UI)
    loadModule("src/Visuals/RuntimeConsistencyFix.lua")(State,TargetProvider,UI)

    ------------------------------------------------------------------------
    -- VEHICLE / UTILITY / WORLD / LOCAL
    ------------------------------------------------------------------------
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
    loadModule("src/Local/DummyHitSoundV2.lua")(State,TargetProvider,UI)
    loadModule("src/Local/TrailGlow.lua")(State,Registry,UI)
    loadModule("src/Local/BringCarStudio.lua")(Registry,UI)
    loadModule("src/Vehicle/VehicleStatusPolish.lua")(State,Registry,UI)

    ------------------------------------------------------------------------
    -- INPUT / TARGET UI / POLISH
    ------------------------------------------------------------------------
    loadModule("src/UI/Keybinds.lua")(State,TargetProvider,UI)
    loadModule("src/UI/DummyTargetInfo.lua")(State,TargetProvider,UI)
    loadModule("src/UI/CompactLabels.lua")(State,UI)
    loadModule("src/UI/LocalPopupPolishV6.lua")(State,UI)
    loadModule("src/UI/SoloSurvivalToLocal.lua")(State,UI)

    loadModule("src/Core/YokaiPolish.lua")(UI)
    loadModule("src/Core/YokaiBlueTheme.lua")(UI)

    loadModule("src/UI/LayoutFinalV4.lua")(State,UI)
    loadModule("src/UI/DockBelowMovementV4.lua")(State,UI)
    loadModule("src/UI/DragPolishV2.lua")(State,UI)
    loadModule("src/UI/WatermarkV4.lua")(State,UI)

    loadModule("src/Core/RuntimeOwnershipGuardV1.lua")(State,TargetProvider,UI)

    ------------------------------------------------------------------------
    -- V2 PUBLIC API
    ------------------------------------------------------------------------
    local Runtime={
        Version=2,
        Standalone=true,
        State=State,
        Registry=Registry,
        TargetProvider=TargetProvider,
        Targets=TargetProvider,
        UI=UI,
        Restrictions=Restrictions,
        TargetRestrictions=Restrictions.Targets,
    }

    shared.LvkHubV2=Runtime

    -- Compatibility alias for modules/tools that inspect the current runtime.
    -- The V2 boot flag remains separate from main loader's boot flag.
    shared.LvkHubExe=Runtime

    ------------------------------------------------------------------------
    -- FINAL STARTUP BARRIER
    ------------------------------------------------------------------------
    local deadline=os.clock()+3.25
    while UI.LayoutReady~=true and os.clock()<deadline do
        task.wait(.025)
    end

    if type(UI.ApplyFinalLayout)=="function" then
        pcall(UI.ApplyFinalLayout)
    end
    pcall(function() RunService.RenderStepped:Wait() end)
    if type(UI.ApplyFinalLayout)=="function" then
        pcall(UI.ApplyFinalLayout)
    end

    shared.LvkHubV2StartupHidden=false

    startupFov=uiParent():FindFirstChild("LvkHubAimFOV")
    if startupFov and startupFov:IsA("ScreenGui") then startupFov.Enabled=true end
    UI.Gui.Enabled=true
end)

if not ok then
    shared.LvkHubV2StartupHidden=nil
    shared.LvkHubV2Loaded=nil
    shared.LvkHubV2=nil
    warn("[LvkHub V2] load failed: "..tostring(err))
end
