-- Persistent World controls. Uses property-change listeners + slow watchdogs to avoid flicker.

return function(State, Registry, UI)
    local Lighting=game:GetService("Lighting")
    local Workspace=game:GetService("Workspace")
    local page=UI.Pages.World

    UI.Section(page,"World")
    UI.Toggle(page,"FullBrightness",function() return State.World.FullBrightness end,function(v) State.World.FullBrightness=v end)
    UI.Toggle(page,"No Fog",function() return State.World.NoFog end,function(v) State.World.NoFog=v end)
    UI.Toggle(page,"No Leaves (all leaves)",function() return State.World.NoLeaves end,function(v) State.World.NoLeaves=v end)
    UI.Toggle(page,"No Shadows",function() return State.World.NoShadows end,function(v) State.World.NoShadows=v end)
    UI.Toggle(page,"FPS Boost",function() return State.World.FPSBoost end,function(v) State.World.FPSBoost=v end)

    local skyOrder={"Default","Bright Day","Night"}
    UI.Button(page,"ChangeSkyDome","CYCLE",function(button)
        local i=table.find(skyOrder,State.World.Sky) or 1
        State.World.Sky=skyOrder[i%#skyOrder+1]
        button.Text=string.upper(State.World.Sky)
    end)

    local original={
        Brightness=Lighting.Brightness,
        ClockTime=Lighting.ClockTime,
        Ambient=Lighting.Ambient,
        OutdoorAmbient=Lighting.OutdoorAmbient,
        GlobalShadows=Lighting.GlobalShadows,
        FogStart=Lighting.FogStart,
        FogEnd=Lighting.FogEnd,
        FogColor=Lighting.FogColor,
    }
    local touching=false
    local leafOriginal=setmetatable({}, {__mode="k"})
    local effectOriginal=setmetatable({}, {__mode="k"})

    local function enforceLighting()
        if touching then return end
        touching=true
        if State.World.FullBrightness then
            Lighting.Brightness=3
            Lighting.ClockTime=14
            Lighting.Ambient=Color3.fromRGB(190,190,190)
            Lighting.OutdoorAmbient=Color3.fromRGB(190,190,190)
        end
        if State.World.NoFog then
            Lighting.FogStart=1e7
            Lighting.FogEnd=1e7+1000
            for _,x in ipairs(Lighting:GetChildren()) do
                if x:IsA("Atmosphere") then
                    if not effectOriginal[x] then effectOriginal[x]={Density=x.Density,Haze=x.Haze,Glare=x.Glare} end
                    x.Density=0; x.Haze=0; x.Glare=0
                end
            end
        end
        if State.World.NoShadows then Lighting.GlobalShadows=false end
        if State.World.Sky=="Bright Day" then Lighting.ClockTime=13 elseif State.World.Sky=="Night" then Lighting.ClockTime=0 end
        touching=false
    end

    for _,prop in ipairs({"Brightness","ClockTime","Ambient","OutdoorAmbient","FogStart","FogEnd","GlobalShadows"}) do
        Lighting:GetPropertyChangedSignal(prop):Connect(function()
            if State.World.FullBrightness or State.World.NoFog or State.World.NoShadows or State.World.Sky~="Default" then task.defer(enforceLighting) end
        end)
    end

    Lighting.ChildAdded:Connect(function(x)
        if x:IsA("Atmosphere") and State.World.NoFog then task.defer(enforceLighting) end
    end)

    local function leafLike(x)
        local n=string.lower(x.Name)
        return n:find("leaf",1,true) or n:find("leaves",1,true) or n:find("foliage",1,true)
    end
    local function applyLeaf(x)
        if not State.World.NoLeaves or not x:IsA("BasePart") or not leafLike(x) then return end
        if leafOriginal[x]==nil then leafOriginal[x]=x.LocalTransparencyModifier end
        x.LocalTransparencyModifier=1
    end
    local function scanLeaves()
        if not State.World.NoLeaves then return end
        for _,x in ipairs(Workspace:GetDescendants()) do applyLeaf(x) end
    end
    Workspace.DescendantAdded:Connect(function(x) if State.World.NoLeaves then task.defer(applyLeaf,x) end end)

    local function applyFPS()
        for _,x in ipairs(Workspace:GetDescendants()) do
            if x:IsA("ParticleEmitter") or x:IsA("Trail") or x:IsA("Beam") or x:IsA("Smoke") or x:IsA("Fire") or x:IsA("Sparkles") then
                if effectOriginal[x]==nil then effectOriginal[x]={Enabled=x.Enabled} end
                x.Enabled=not State.World.FPSBoost
            end
        end
        for _,x in ipairs(Lighting:GetChildren()) do
            if x:IsA("BloomEffect") or x:IsA("SunRaysEffect") or x:IsA("DepthOfFieldEffect") then
                if effectOriginal[x]==nil then effectOriginal[x]={Enabled=x.Enabled} end
                x.Enabled=not State.World.FPSBoost
            end
        end
    end

    task.spawn(function()
        local leavesWas=false; local fpsWas=false
        while UI.Gui.Parent do
            task.wait(.75)
            enforceLighting()
            if State.World.NoLeaves then scanLeaves() elseif leavesWas then
                for x,v in pairs(leafOriginal) do if x and x.Parent then pcall(function() x.LocalTransparencyModifier=v end) end; leafOriginal[x]=nil end
            end
            leavesWas=State.World.NoLeaves
            if State.World.FPSBoost~=fpsWas then applyFPS(); fpsWas=State.World.FPSBoost end
        end
    end)
end
