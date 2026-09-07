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

    local Restrictions=nil
    local policyOK,policyResult=pcall(function()
        return loadModule("src/Restrictions/Policy.lua")
    end)
    if policyOK and type(policyResult)=="table" then Restrictions=policyResult end
    if not Restrictions then
        Restrictions={
            Name="LvkHubRestrictionsFallback",
            FailClosed=true,
            Targets={
                Mode="DENY_ALL",
                IsAllowedTarget=function() return false end,
                IsRealPlayerCharacter=function() return true end,
                CanCloneSource=function() return false end,
                Describe=function() return false,"restrictions missing: fail closed" end,
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

    loadModule("src/Movement/MainV2.lua")(State,Registry,UI)

    loadModule("src/Visuals/UnifiedTestVisualsV5.lua")(State,Registry,UI)
    loadModule("src/Visuals/PreviewPolishV2.lua")(State,Registry,UI)
    loadModule("src/Visuals/PracticeOverlay.lua")(State,Registry,UI)

    loadModule("src/Vehicle/Main.lua")(State,Registry,UI)

    loadModule("src/Utility/Main.lua")(State,Registry,UI)
    loadModule("src/Utility/SoloSurvival.lua")(State,Registry,UI)
    loadModule("src/World/Main.lua")(State,Registry,UI)
    loadModule("src/Local/MainV3.lua")(State,Registry,UI)
    loadModule("src/Local/ConfirmedHitSound.lua")(State)
    loadModule("src/Local/HitSoundAsset.lua")(State,UI)
    loadModule("src/Local/DummyHitSoundFallback.lua")(State,Registry,UI)
    loadModule("src/Local/TrailGlow.lua")(State,Registry,UI)
    loadModule("src/Local/BringCarStudio.lua")(Registry,UI)

    loadModule("src/UI/Keybinds.lua")(State,Registry,UI)
    loadModule("src/UI/DummyTargetInfo.lua")(State,Registry,UI)
    loadModule("src/UI/LayoutPolishV2.lua")(State,UI)

    loadModule("src/Core/YokaiPolish.lua")(UI)
    loadModule("src/Core/YokaiBlueTheme.lua")(UI)

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
