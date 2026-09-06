-- Unified bot/vehicle visuals. Targets only Registry.Bots (non-player rigs) and Registry.Vehicles.

return function(State, Registry, UI)
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")
    local UIS=game:GetService("UserInputService")
    local page=UI.Pages.Visuals
    local parent=UI.Gui.Parent

    UI.Section(page,"Visuals")
    UI.Toggle(page,"ESP Pack",function() return State.Visuals.ESP end,function(v) State.Visuals.ESP=v end)
    UI.Toggle(page,"Chams",function() return State.Visuals.Chams end,function(v) State.Visuals.Chams=v end)
    UI.Toggle(page,"Corner Box",function() return State.Visuals.CornerBox end,function(v) State.Visuals.CornerBox=v end)
    UI.Toggle(page,"3D Box",function() return State.Visuals.Box3D end,function(v) State.Visuals.Box3D=v end)
    UI.Toggle(page,"HealthBar",function() return State.Visuals.HealthBar end,function(v) State.Visuals.HealthBar=v end)
    UI.Toggle(page,"Name + Distance",function() return State.Visuals.NameDistance end,function(v) State.Visuals.NameDistance=v end)
    UI.Toggle(page,"Thermal Corner",function() return State.Visuals.ThermalCorner end,function(v) State.Visuals.ThermalCorner=v end)
    UI.Toggle(page,"Tracers",function() return State.Visuals.Tracers end,function(v) State.Visuals.Tracers=v end)
    UI.Toggle(page,"Skeleton",function() return State.Visuals.Skeleton end,function(v) State.Visuals.Skeleton=v end)
    UI.Toggle(page,"Preview",function() return State.Visuals.Preview end,function(v) State.Visuals.Preview=v end)
    UI.Number(page,"FOV Changer",function() return State.Visuals.FOV end,function(v) State.Visuals.FOV=v end,30,120)
    UI.Toggle(page,"Car ESP",function() return State.Visuals.CarESP end,function(v) State.Visuals.CarESP=v end)

    local _,status=UI.Row(page,"Bots: 0  •  Vehicles: 0")
    status.TextColor3=Color3.fromRGB(150,200,255)

    local overlay=Instance.new("ScreenGui")
    overlay.Name="LvkHubVisuals"; overlay.IgnoreGuiInset=true; overlay.ResetOnSpawn=false; overlay.DisplayOrder=8500; overlay.Parent=parent

    local stores=setmetatable({}, {__mode="k"})
    local carStores=setmetatable({}, {__mode="k"})

    local function line()
        local f=Instance.new("Frame"); f.AnchorPoint=Vector2.new(.5,.5); f.BorderSizePixel=0; f.Visible=false; f.BackgroundColor3=Color3.new(1,1,1); f.Parent=overlay; return f
    end
    local function setLine(f,a,b,thick,color,trans)
        local d=b-a; if d.Magnitude<.1 then f.Visible=false return end
        f.Size=UDim2.fromOffset(d.Magnitude,thick or 1); f.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2); f.Rotation=math.deg(math.atan2(d.Y,d.X)); f.BackgroundColor3=color or Color3.new(1,1,1); f.BackgroundTransparency=trans or 0; f.Visible=true
    end
    local function hideLines(list) for _,x in ipairs(list or {}) do x.Visible=false end end

    local function createStore(model)
        local s={}
        s.highlight=Instance.new("Highlight"); s.highlight.Name="LvkHubChams"; s.highlight.Adornee=model; s.highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; s.highlight.Enabled=false; s.highlight.Parent=model
        s.corner={}; for i=1,8 do s.corner[i]=line() end
        s.thermal={}; for i=1,8 do s.thermal[i]=line() end
        s.box3d={}; for i=1,12 do s.box3d[i]=line() end
        s.skel={}; for i=1,14 do s.skel[i]=line() end
        s.tracer=line()
        s.name=Instance.new("TextLabel"); s.name.BackgroundTransparency=1; s.name.Size=UDim2.fromOffset(250,18); s.name.Font=Enum.Font.Code; s.name.TextSize=11; s.name.TextColor3=Color3.new(1,1,1); s.name.TextStrokeTransparency=0; s.name.Visible=false; s.name.Parent=overlay
        s.hb=Instance.new("Frame"); s.hb.BorderSizePixel=0; s.hb.BackgroundColor3=Color3.new(0,0,0); s.hb.Visible=false; s.hb.Parent=overlay
        s.hp=Instance.new("Frame"); s.hp.BorderSizePixel=0; s.hp.Visible=false; s.hp.Parent=overlay
        stores[model]=s; return s
    end
    local function hideStore(s)
        s.highlight.Enabled=false; s.name.Visible=false; s.hb.Visible=false; s.hp.Visible=false; s.tracer.Visible=false; hideLines(s.corner); hideLines(s.thermal); hideLines(s.box3d); hideLines(s.skel)
    end
    local function destroyStore(m)
        local s=stores[m]; if not s then return end
        for _,v in pairs(s) do if typeof(v)=="Instance" then pcall(function() v:Destroy() end) elseif type(v)=="table" then for _,x in ipairs(v) do pcall(function() x:Destroy() end) end end end
        stores[m]=nil
    end

    local function bounds(model,cam)
        local ok,cf,size=pcall(function() return model:GetBoundingBox() end); if not ok then return nil end
        local minX,minY,maxX,maxY=math.huge,math.huge,-math.huge,-math.huge; local any=false
        for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
            local p=cam:WorldToViewportPoint((cf*CFrame.new(size.X*x/2,size.Y*y/2,size.Z*z/2)).Position)
            if p.Z>0 then any=true; minX=math.min(minX,p.X); minY=math.min(minY,p.Y); maxX=math.max(maxX,p.X); maxY=math.max(maxY,p.Y) end
        end end end
        if not any then return nil end
        return Vector2.new(minX,minY),Vector2.new(maxX,maxY)
    end
    local function corners(lines,tl,br,color)
        local l,t,r,b=tl.X,tl.Y,br.X,br.Y; local w,h=r-l,b-t; local cw,ch=math.max(6,w*.2),math.max(6,h*.2)
        local seg={{Vector2.new(l,t),Vector2.new(l+cw,t)},{Vector2.new(l,t),Vector2.new(l,t+ch)},{Vector2.new(r,t),Vector2.new(r-cw,t)},{Vector2.new(r,t),Vector2.new(r,t+ch)},{Vector2.new(l,b),Vector2.new(l+cw,b)},{Vector2.new(l,b),Vector2.new(l,b-ch)},{Vector2.new(r,b),Vector2.new(r-cw,b)},{Vector2.new(r,b),Vector2.new(r,b-ch)}}
        for i,v in ipairs(seg) do setLine(lines[i],v[1],v[2],1,color) end
    end

    local r15={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"}}
    local r6={{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
    local function skeleton(lines,model,cam,color)
        hideLines(lines)
        local bones=model:FindFirstChild("UpperTorso") and r15 or r6
        for i,pair in ipairs(bones) do
            local a,b=model:FindFirstChild(pair[1]),model:FindFirstChild(pair[2]); local f=lines[i]
            if a and b and f then
                local pa,ona=cam:WorldToViewportPoint(a.Position); local pb,onb=cam:WorldToViewportPoint(b.Position)
                if ona and onb and pa.Z>0 and pb.Z>0 then setLine(f,Vector2.new(pa.X,pa.Y),Vector2.new(pb.X,pb.Y),1,color) end
            end
        end
    end
    local function box3d(lines,root,cam,color)
        hideLines(lines); if not root then return end
        local cf=root.CFrame*CFrame.new(0,-.5,0); local sz=Vector3.new(3,5,3)/2; local pts={}
        for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do table.insert(pts,(cf*CFrame.new(sz*Vector3.new(x,y,z))).Position) end end end
        local s={}; for i,p in ipairs(pts) do local q,on=cam:WorldToViewportPoint(p); if not on or q.Z<=0 then return end; s[i]=Vector2.new(q.X,q.Y) end
        local e={{1,2},{2,4},{4,3},{3,1},{5,6},{6,8},{8,7},{7,5},{1,5},{2,6},{3,7},{4,8}}
        for i,v in ipairs(e) do setLine(lines[i],s[v[1]],s[v[2]],1,color) end
    end

    local preview=Instance.new("Frame")
    preview.Size=UDim2.fromOffset(150,220); preview.Position=UDim2.new(1,-170,.5,-110); preview.BackgroundTransparency=.8; preview.BackgroundColor3=Color3.fromRGB(20,20,28); preview.BorderSizePixel=0; preview.Visible=false; preview.Parent=overlay
    Instance.new("UICorner", preview).CornerRadius=UDim.new(0,8)
    local pst=Instance.new("UIStroke", preview); pst.Color=Color3.fromRGB(125,82,235); pst.Thickness=2
    local ptxt=Instance.new("TextLabel"); ptxt.BackgroundTransparency=1; ptxt.Size=UDim2.fromScale(1,1); ptxt.Font=Enum.Font.GothamBold; ptxt.TextSize=13; ptxt.TextColor3=Color3.new(1,1,1); ptxt.Text="ESP PREVIEW"; ptxt.Parent=preview

    local function vehicleRoot(model)
        if not model then return nil end
        local seat=model:FindFirstChild("Seat1",true) or model:FindFirstChildWhichIsA("VehicleSeat",true)
        return seat or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart",true)
    end
    local function makeCar(model)
        local hi=Instance.new("Highlight"); hi.Name="LvkHubCarESP"; hi.Adornee=model; hi.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hi.FillTransparency=.82; hi.OutlineTransparency=.05; hi.FillColor=Color3.fromRGB(60,220,180); hi.OutlineColor=Color3.fromRGB(60,220,180); hi.Enabled=false; hi.Parent=model
        local root=vehicleRoot(model)
        local bb=nil
        if root then bb=Instance.new("BillboardGui"); bb.Adornee=root; bb.AlwaysOnTop=true; bb.Size=UDim2.fromOffset(220,24); bb.StudsOffsetWorldSpace=Vector3.new(0,3,0); bb.Parent=root; local t=Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Size=UDim2.fromScale(1,1); t.Font=Enum.Font.Code; t.TextSize=11; t.TextColor3=Color3.fromRGB(80,240,190); t.TextStrokeTransparency=.2; t.Parent=bb end
        local s={hi=hi,bb=bb}; carStores[model]=s; return s
    end

    RunService.RenderStepped:Connect(function()
        local cam=Workspace.CurrentCamera; if not cam then return end
        cam.FieldOfView=State.Visuals.FOV
        preview.Visible=State.Visuals.Preview
        status.Text="Bots: "..Registry.CountBots().."  •  Vehicles: "..Registry.CountVehicles()

        for m in pairs(stores) do if not Registry.Bots[m] or not Registry.IsBot(m) then destroyStore(m) end end
        for model in pairs(Registry.Bots) do
            if Registry.IsBot(model) then
                local s=stores[model] or createStore(model)
                local root=Registry.RootOf(model); local hum=Registry.HumanoidOf(model); local tl,br=bounds(model,cam)
                local active=State.Visuals.ESP or State.Visuals.Chams or State.Visuals.CornerBox or State.Visuals.Box3D or State.Visuals.HealthBar or State.Visuals.NameDistance or State.Visuals.ThermalCorner or State.Visuals.Tracers or State.Visuals.Skeleton
                if not active then hideStore(s) continue end
                local col=Color3.fromRGB(125,150,255)
                s.highlight.Enabled=State.Visuals.Chams or State.Visuals.ESP; s.highlight.FillColor=col; s.highlight.OutlineColor=col; s.highlight.FillTransparency=.72; s.highlight.OutlineTransparency=.03
                if tl and br then
                    if State.Visuals.CornerBox or State.Visuals.ESP then corners(s.corner,tl,br,col) else hideLines(s.corner) end
                    if State.Visuals.ThermalCorner then local pulse=.5+.5*math.sin(os.clock()*3); corners(s.thermal,tl,br,Color3.fromHSV(.72,.7,.65+.35*pulse)) else hideLines(s.thermal) end
                    local dist=root and (root.Position-cam.CFrame.Position).Magnitude or 0
                    if State.Visuals.NameDistance or State.Visuals.ESP then s.name.Text=model.Name.."  ["..math.floor(dist).."]"; s.name.Position=UDim2.fromOffset((tl.X+br.X)/2-125,tl.Y-18); s.name.Visible=true else s.name.Visible=false end
                    if (State.Visuals.HealthBar or State.Visuals.ESP) and hum then local ratio=math.clamp(hum.Health/math.max(1,hum.MaxHealth),0,1); local h=br.Y-tl.Y; s.hb.Position=UDim2.fromOffset(br.X+4,tl.Y); s.hb.Size=UDim2.fromOffset(4,h); s.hb.Visible=true; s.hp.Position=UDim2.fromOffset(br.X+5,tl.Y+1+(h-2)*(1-ratio)); s.hp.Size=UDim2.fromOffset(2,(h-2)*ratio); s.hp.BackgroundColor3=Color3.fromHSV(ratio*.33,.8,1); s.hp.Visible=true else s.hb.Visible=false; s.hp.Visible=false end
                    if State.Visuals.Tracers then setLine(s.tracer,Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y),Vector2.new((tl.X+br.X)/2,br.Y),1,col,.05) else s.tracer.Visible=false end
                else s.name.Visible=false; s.hb.Visible=false; s.hp.Visible=false; s.tracer.Visible=false; hideLines(s.corner); hideLines(s.thermal) end
                if State.Visuals.Skeleton then skeleton(s.skel,model,cam,Color3.new(1,1,1)) else hideLines(s.skel) end
                if State.Visuals.Box3D then box3d(s.box3d,root,cam,col) else hideLines(s.box3d) end
            end
        end

        for model in pairs(carStores) do if not Registry.Vehicles[model] or not model.Parent then local s=carStores[model]; if s.hi then s.hi:Destroy() end; if s.bb then s.bb:Destroy() end; carStores[model]=nil end end
        for model in pairs(Registry.Vehicles) do
            local s=carStores[model] or makeCar(model); local root=vehicleRoot(model)
            s.hi.Enabled=State.Visuals.CarESP
            if s.bb then s.bb.Enabled=State.Visuals.CarESP; local t=s.bb:FindFirstChildOfClass("TextLabel"); if t and root then local d=(root.Position-cam.CFrame.Position).Magnitude; t.Text=model.Name.."  ["..math.floor(d).."]" end end
        end
    end)
end
