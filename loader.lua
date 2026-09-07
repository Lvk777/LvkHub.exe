-- LvkHub.exe V2 RUNTIME LOADER
-- STRICTLY ISOLATED FROM main runtime:
--   * every module is fetched from the v2-runtime branch
--   * policy comes from v2/Policy.lua on the v2-runtime branch
--   * never calls main/loader.lua
--   * never fetches modules from the main branch

local OWNER="v2"
local BRANCH="v2-runtime"

if shared.LvkHubRuntimeOwner and shared.LvkHubRuntimeOwner~=OWNER then
    warn("[LvkHub V2] another LvkHub runtime already owns this session: "..tostring(shared.LvkHubRuntimeOwner))
    return
end

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

shared.LvkHubRuntimeOwner=OWNER
shared.LvkHubV2Loaded=true
shared.LvkHubV2StartupHidden=true

local RunService=game:GetService("RunService")
local CoreGui=game:GetService("CoreGui")
local BASE="https://raw.githubusercontent.com/Lvk777/LvkHub.exe/"..BRANCH.."/"

local function loadV2(path)
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
    -- V2 CORE — all files below come from v2-runtime branch only.
    ------------------------------------------------------------------------
    local State=loadV2("src/Core/State.lua")
    local Restrictions=loadV2("v2/Policy.lua")
    assert(type(Restrictions)=="table" and type(Restrictions.Targets)=="table","invalid V2 policy")

    shared.LvkHubV2Restrictions=Restrictions
    shared.LvkHubV2TargetRestrictions=Restrictions.Targets

    local MakeRegistry=loadV2("src/Core/RegistryV3.lua")
    local Registry=MakeRegistry(Restrictions.Targets)

    local MakeTargetProvider=loadV2("src/Core/TargetProvider.lua")
    local TargetProvider=MakeTargetProvider(Registry,Restrictions.Targets)
    shared.LvkHubV2TargetProvider=TargetProvider

    ------------------------------------------------------------------------
    -- V2 UI
    ------------------------------------------------------------------------
    local MakeUI=loadV2("src/UI/Main.lua")
    local UI=MakeUI(State)
    UI.Gui.Enabled=false
    UI.Main.Visible=true
    State.UI.Visible=true

    loadV2("src/UI/Enhancements.lua")(State,UI)

    ------------------------------------------------------------------------
    -- V2 COMBAT / PRACTICE
    ------------------------------------------------------------------------
    loadV2("src/Combat/MainV4.lua")(State,TargetProvider,UI)

    local startupFov=uiParent():FindFirstChild("LvkHubAimFOV")
    if startupFov and startupFov:IsA("ScreenGui") then startupFov.Enabled=false end

    loadV2("src/UI/FOVBorderPolish.lua")(State,UI)
    local LegacyPracticeAdapter=loadV2("src/Combat/WeaponSystemDummyAdapterV3.lua")
    loadV2("src/Combat/WeaponSystemTargetAdapterV4.lua")(State,TargetProvider,UI,LegacyPracticeAdapter)
    loadV2("src/Combat/SoloWeaponMods.lua")(State,Registry,UI)
    loadV2("src/Combat/SoloNoSpread.lua")(State,Registry,UI)

    ------------------------------------------------------------------------
    -- V2 MOVEMENT / VISUALS
    ------------------------------------------------------------------------
    loadV2("src/Movement/MainV2.lua")(State,Registry,UI)
    loadV2("src/Visuals/UnifiedTestVisualsV5.lua")(State,TargetProvider,UI)
    loadV2("src/Visuals/ChamsWallCheckV1.lua")(State,TargetProvider,UI)
    loadV2("src/Visuals/PreviewV11.lua")(State,TargetProvider,UI)
    loadV2("src/Visuals/PreviewLocalPlayerV3.lua")(State,TargetProvider,UI)
    loadV2("src/Visuals/PracticeOverlayV2.lua")(State,TargetProvider,UI)
    loadV2("src/Visuals/RuntimeConsistencyFix.lua")(State,TargetProvider,UI)

    ------------------------------------------------------------------------
    -- V2 VEHICLE / UTILITY / WORLD / LOCAL
    ------------------------------------------------------------------------
    loadV2("src/Vehicle/Main.lua")(State,Registry,UI)
    loadV2("src/Utility/Main.lua")(State,Registry,UI)
    loadV2("src/Utility/Presets.lua")(State,Registry,UI)
    loadV2("src/Utility/SoloSurvivalV2.lua")(State,Registry,UI)
    loadV2("src/World/Main.lua")(State,Registry,UI)

    loadV2("src/Local/MainV4.lua")(State,Registry,UI)
    loadV2("src/Local/ChamsMaterialV1.lua")(State,Registry,UI)
    loadV2("src/Local/MuteGunshotsV4.lua")(State,Registry,UI)
    loadV2("src/Local/GunshotReplacementV1.lua")(State,Registry,UI)
    loadV2("src/Local/BulletTracerV8.lua")(State,Registry,UI)
    loadV2("src/UI/LocalOrderPolish.lua")(State,UI)
    loadV2("src/Local/DummyHitSoundV2.lua")(State,TargetProvider,UI)
    loadV2("src/Local/TrailGlow.lua")(State,Registry,UI)
    loadV2("src/Local/BringCarStudio.lua")(Registry,UI)
    loadV2("src/Vehicle/VehicleStatusPolish.lua")(State,Registry,UI)

    ------------------------------------------------------------------------
    -- V2 INPUT / UI POLISH
    ------------------------------------------------------------------------
    loadV2("src/UI/Keybinds.lua")(State,TargetProvider,UI)
    loadV2("src/UI/DummyTargetInfo.lua")(State,TargetProvider,UI)
    loadV2("src/UI/CompactLabels.lua")(State,UI)
    loadV2("src/UI/LocalPopupPolishV6.lua")(State,UI)
    loadV2("src/UI/SoloSurvivalToLocal.lua")(State,UI)
    loadV2("src/Core/YokaiPolish.lua")(UI)
    loadV2("src/Core/YokaiBlueTheme.lua")(UI)
    loadV2("src/UI/LayoutFinalV4.lua")(State,UI)
    loadV2("src/UI/DockBelowMovementV4.lua")(State,UI)
    loadV2("src/UI/DragPolishV2.lua")(State,UI)
    loadV2("src/UI/WatermarkV4.lua")(State,UI)
    loadV2("src/Core/RuntimeOwnershipGuardV1.lua")(State,TargetProvider,UI)

    local Runtime={
        Version=2,
        Branch=BRANCH,
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

    ------------------------------------------------------------------------
    -- FINAL STARTUP BARRIER
    ------------------------------------------------------------------------
    local deadline=os.clock()+3.25
    while UI.LayoutReady~=true and os.clock()<deadline do
        task.wait(.025)
    end
    if type(UI.ApplyFinalLayout)=="function" then pcall(UI.ApplyFinalLayout) end
    pcall(function() RunService.RenderStepped:Wait() end)
    if type(UI.ApplyFinalLayout)=="function" then pcall(UI.ApplyFinalLayout) end

    shared.LvkHubV2StartupHidden=false
    startupFov=uiParent():FindFirstChild("LvkHubAimFOV")
    if startupFov and startupFov:IsA("ScreenGui") then startupFov.Enabled=true end
    UI.Gui.Enabled=true
end)

if not ok then
    shared.LvkHubV2StartupHidden=nil
    shared.LvkHubV2Loaded=nil
    shared.LvkHubV2=nil
    if shared.LvkHubRuntimeOwner==OWNER then shared.LvkHubRuntimeOwner=nil end
    warn("[LvkHub V2] load failed: "..tostring(err))
end
