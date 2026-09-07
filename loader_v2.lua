-- V2 branch compatibility entry point.
-- Always resolves to this branch's own loader; never calls main.
if shared.LvkHubRuntimeOwner and shared.LvkHubRuntimeOwner~="v2" then
    warn("[LvkHub V2] another isolated runtime already owns this session: "..tostring(shared.LvkHubRuntimeOwner))
    return
end
shared.LvkHubRuntimeOwner="v2"
loadstring(game:HttpGet("https://raw.githubusercontent.com/Lvk777/LvkHub.exe/v2-runtime/loader.lua",true))()
