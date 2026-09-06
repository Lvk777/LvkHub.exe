-- Persistent World controls. Vegetation removes Workspace.Map.Vegetation children
-- from the local Workspace while enabled, so Bushes/Trees stop rendering and simulating.

return function(State, Registry, UI)
    local Lighting=game:GetService("Lighting")
    local Workspace=game:GetService("Workspace")
    local page=UI.Pages.World

    UI.Section(page,"World")
    UI.Toggle(page,"FullBrightness",function() return State.World.FullBrightness end,function(v) State.World.FullBrightness=v end)
    UI.Toggle(page,"No Fog",function() return State.World.NoFog end,function(v) State.World.NoFog=v end)
    UI.Toggle(page,"Vegetation",function() return State.World.Vegetation end,function(v) State.World.Vegetation=v end)
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

    -- Workspace > Map > Vegetation > Bushes / Trees from the supplied Explorer screenshots.
    -- We detach direct children instead of permanently Destroying them so the toggle can restore them.
    local vegetationFolder=nil
    local vegetationStash=setmetatable({}, {__mode="k"})
    local vegetationConn=nil

    local function resolveVegetation()
        local map=Workspace:FindFirstChild("Map")
        return map and map:FindFirstChild("Vegetation") or nil
    end

    local function detachVegetationChild(child)
        if not State.World.Vegetation or not child or child.Parent~=vegetationFolder then return end
        if vegetationStash[child]==nil then vegetationStash[child]=vegetationFolder end
        child.Parent=nil
    end

    local function attachVegetationFolder(folder)
        if vegetationFolder==folder then return end
        if vegetationConn then vegetationConn:Disconnect(); vegetationConn=nil end
        vegetationFolder=folder
        if vegetationFolder then
            vegetationConn=vegetationFolder.ChildAdded:Connect(function(child)
                if State.World.Vegetation then task.defer(detachVegetationChild,child) end
            end)
        end
    end

    local function applyVegetation()
        local current=resolveVegetation()
        if current~=vegetationFolder then attachVegetationFolder(current) end
        if State.World.Vegetation then
            if vegetationFolder then
                local children=vegetationFolder:GetChildren()
                for i,child in ipairs(children) do
                    detachVegetationChild(child)
                    if i%40==0 then task.wait() end
                end
            end
        else
            local target=resolveVegetation()
            if target then
                for child in pairs(vegetationStash) do
                    if child and child.Parent==nil then pcall(function() child.Parent=target end) end
                    vegetationStash[child]=nil
                end
            end
        end
    end

    Workspace.DescendantAdded:Connect(function(obj)
        if obj.Name=="Vegetation" and obj.Parent and obj.Parent.Name=="Map" then
            task.defer(function()
                attachVegetationFolder(obj)
                if State.World.Vegetation then applyVegetation() end
            end)
        end
    end)

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

    attachVegetationFolder(resolveVegetation())
    task.spawn(function()
        local vegetationWas=false
        local fpsWas=false
        while UI.Gui.Parent do
            task.wait(.50)
            enforceLighting()
            if State.World.Vegetation~=vegetationWas then
                applyVegetation()
                vegetationWas=State.World.Vegetation
            elseif State.World.Vegetation then
                local current=resolveVegetation()
                if current~=vegetationFolder then attachVegetationFolder(current) end
                if vegetationFolder and #vegetationFolder:GetChildren()>0 then applyVegetation() end
            end
            if State.World.FPSBoost~=fpsWas then applyFPS(); fpsWas=State.World.FPSBoost end
        end
    end)
end
