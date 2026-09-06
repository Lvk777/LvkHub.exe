-- LvkHub.exe loader
-- Clean Yokai-style build with only the requested categories/features.

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
    local Registry=loadModule("src/Core/Registry.lua")
    local MakeUI=loadModule("src/UI/Main.lua")
    local UI=MakeUI(State)

    loadModule("src/Combat/Main.lua")(State,Registry,UI)
    loadModule("src/Movement/Main.lua")(State,Registry,UI)
    loadModule("src/Visuals/Main.lua")(State,Registry,UI)
    loadModule("src/Utility/Main.lua")(State,Registry,UI)
    loadModule("src/World/Main.lua")(State,Registry,UI)
    loadModule("src/Local/Main.lua")(State,Registry,UI)
    loadModule("src/Local/BringCarStudio.lua")(Registry,UI)
    loadModule("src/Core/YokaiPolish.lua")(UI)

    shared.LvkHubExe={State=State,Registry=Registry,UI=UI}
end)

if not ok then
    shared.LvkHubExeLoaded=nil
    warn("[LvkHub.exe] load failed: "..tostring(err))
end
