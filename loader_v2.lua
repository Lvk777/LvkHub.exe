-- V2 compatibility entry point.
-- This file does not load normal/main modules. It forwards directly to the
-- isolated v2-runtime branch, whose loader and modules all live on that branch.
if shared.LvkHubRuntimeOwner and shared.LvkHubRuntimeOwner~="v2" then
    warn("[LvkHub V2] another isolated runtime already owns this session: "..tostring(shared.LvkHubRuntimeOwner))
    return
end
shared.LvkHubRuntimeOwner="v2"
loadstring(game:HttpGet("https://raw.githubusercontent.com/Lvk777/LvkHub.exe/v2-runtime/loader.lua",true))()
