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

    -- Restrictions are a required module. There is no synthetic DENY_ALL / FailClosed fallback.
    local Restrictions=loadModule("src/Restrictions/Policy.lua")
    if type(Restrictions)~="table" or type(Restrictions.Targets)~="table" then
        error("LvkHub: src/Restrictions/Policy.lua is required")
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

    loadModule("src/Movement/MainV2.lua")(State,Registry,UI)

    loadModule("src/Visuals/UnifiedTestVisualsV5.lua")(State,Registry,UI)
    loadModule("src/Visuals/PreviewV11.lua")(State,Registry,UI)
    loadModule("src/Visuals/PracticeOverlayV2.lua")(State,Registry,UI)

    loadModule("src/Vehicle/Main.lua")(State,Registry,UI)

    loadModule("src/Utility/Main.lua")(State,Registry,UI)
    loadModule("src/Utility/SoloSurvival.lua")(State,Registry,UI)
    loadModule("src/World/Main.lua")(State,Registry,UI)

    loadModule("src/Local/MainV4.lua")(State,Registry,UI)
    loadModule("src/Local/MuteGunshotsV3.lua")(State,Registry,UI)
    loadModule("src/Local/GunshotReplacementV1.lua")(State,Registry,UI)
    loadModule("src/Local/BulletTracerV5.lua")(State,Registry,UI)
    loadModule("src/UI/LocalOrderPolish.lua")(State,UI)
    loadModule("src/Local/DummyHitSoundV2.lua")(State,Registry,UI)
    loadModule("src/Local/TrailGlow.lua")(State,Registry,UI)
    loadModule("src/Local/BringCarStudio.lua")(Registry,UI)

    loadModule("src/UI/Keybinds.lua")(State,Registry,UI)
    loadModule("src/UI/DummyTargetInfo.lua")(State,Registry,UI)
    loadModule("src/UI/CompactLabels.lua")(State,UI)
    loadModule("src/UI/LocalPopupPolishV5.lua")(State,UI)
    loadModule("src/UI/FOVBorderPolish.lua")(State,UI)

    loadModule("src/Core/YokaiPolish.lua")(UI)
    loadModule("src/Core/YokaiBlueTheme.lua")(UI)

    -- Final layout/docking is loaded after every frame/popup owner exists.
    loadModule("src/UI/LayoutFinalV4.lua")(State,UI)
    loadModule("src/UI/DockBelowVehicleV1.lua")(State,UI)
    loadModule("src/UI/DragPolishV1.lua")(State,UI)
    loadModule("src/UI/WatermarkV3.lua")(State,UI)

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
