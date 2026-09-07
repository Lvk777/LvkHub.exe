-- Dedicated Visuals preview built from a synthetic local dummy.
-- It never clones or displays a real Player.Character.
return function(State, Registry, UI)
    local RunService=game:GetService("RunService")
    local UIS=game:GetService("UserInputService")
    local Workspace=game:GetService("Workspace")

    local old=UI.Gui:FindFirstChild("LvkHubVisualsDummyPreview")
    if old then old:Destroy() end

    local cfg=State.Visuals._V5Config or {}
    State.Visuals.PreviewHealth=tonumber(State.Visuals.PreviewHealth) or 100

    local function rounded(o,r)
        local c=Instance.new("UICorner")
        c.CornerRadius=UDim.new(0,r or 5)
        c.Parent=o
    end

    local frame=Instance.new("Frame")
    frame.Name="LvkHubVisualsDummyPreview"
    frame.Size=UDim2.fromOffset(230,322)
    frame.Position=UDim2.fromOffset(1398,220)
    frame.BackgroundColor3=Color3.fromRGB(15,16,20)
    frame.BorderSizePixel=0
    frame.Visible=false
    frame.ZIndex=170
    frame.Parent=UI.Gui
    rounded(frame,7)
    local outline=Instance.new("UIStroke")
    outline.Color=Color3.fromRGB(55,58,70)
    outline.Transparency=.08
    outline.Parent=frame

    local header=Instance.new("Frame")
    header.Name="Header"
    header.Size=UDim2.new(1,0,0,38)
    header.BackgroundColor3=Color3.fromRGB(20,21,27)
    header.BorderSizePixel=0
    header.Active=true
    header.ZIndex=171
    header.Parent=frame
    rounded(header,7)

    local accent=Instance.new("Frame")
    accent.Position=UDim2.fromOffset(7,9)
    accent.Size=UDim2.fromOffset(3,20)
    accent.BackgroundColor3=UI.Accent
    accent.BorderSizePixel=0
    accent.ZIndex=172
    accent.Parent=header
    rounded(accent,2)

    local title=Instance.new("TextLabel")
    title.BackgroundTransparency=1
    title.Position=UDim2.fromOffset(17,0)
    title.Size=UDim2.new(1,-25,1,0)
    title.Font=Enum.Font.SourceSansSemibold
    title.TextSize=14
    title.TextColor3=Color3.fromRGB(238,238,242)
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Text="Visuals Preview"
    title.ZIndex=172
    title.Parent=header

    local vp=Instance.new("ViewportFrame")
    vp.Position=UDim2.fromOffset(9,46)
    vp.Size=UDim2.new(1,-18,0,205)
    vp.BackgroundColor3=Color3.fromRGB(22,23,29)
    vp.BackgroundTransparency=.05
    vp.BorderSizePixel=0
    vp.Ambient=Color3.fromRGB(165,168,178)
    vp.LightColor=Color3.fromRGB(255,255,255)
    vp.LightDirection=Vector3.new(-1,-1,-1)
    vp.ZIndex=171
    vp.Parent=frame
    rounded(vp,6)

    local world=Instance.new("WorldModel")
    world.Parent=vp
    local cam=Instance.new("Camera")
    cam.FieldOfView=34
    cam.CFrame=CFrame.lookAt(Vector3.new(0,1.4,8.8),Vector3.new(0,1.2,0))
    cam.Parent=vp
    vp.CurrentCamera=cam

    local dummy=Instance.new("Model")
    dummy.Name="TEST_DUMMY"
    dummy.Parent=world

    local dummyParts={}
    local function part(name,size,pos,color)
        local p=Instance.new("Part")
        p.Name=name
        p.Size=size
        p.CFrame=CFrame.new(pos)
        p.Anchored=true
        p.CanCollide=false
        p.Material=Enum.Material.SmoothPlastic
        p.Color=color
        p.Parent=dummy
        dummyParts[p]=color
        return p
    end

    local skin=Color3.fromRGB(232,195,157)
    local shirt=Color3.fromRGB(86,98,118)
    local pants=Color3.fromRGB(38,42,50)
    part("Head",Vector3.new(1.45,1.25,1.2),Vector3.new(0,3.05,0),skin)
    part("Torso",Vector3.new(2.15,2.15,1.05),Vector3.new(0,1.35,0),shirt)
    part("Left Arm",Vector3.new(.8,2.05,.85),Vector3.new(-1.48,1.35,0),skin)
    part("Right Arm",Vector3.new(.8,2.05,.85),Vector3.new(1.48,1.35,0),skin)
    part("Left Leg",Vector3.new(.9,2.15,.95),Vector3.new(-.58,-.78,0),pants)
    part("Right Leg",Vector3.new(.9,2.15,.95),Vector3.new(.58,-.78,0),pants)

    local overlay=Instance.new("Frame")
    overlay.Name="PreviewOverlay"
    overlay.Position=vp.Position
    overlay.Size=vp.Size
    overlay.BackgroundTransparency=1
    overlay.ZIndex=180
    overlay.Parent=frame

    local function guiLine(name,a,b,thick,color)
        local f=Instance.new("Frame")
        f.Name=name
        f.AnchorPoint=Vector2.new(.5,.5)
        f.BorderSizePixel=0
        f.ZIndex=181
        f.Parent=overlay
        local d=b-a
        f.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
        f.Size=UDim2.fromOffset(math.max(1,d.Magnitude),thick or 1)
        f.Rotation=math.deg(math.atan2(d.Y,d.X))
        f.BackgroundColor3=color or Color3.new(1,1,1)
        return f
    end

    local box=Instance.new("Frame")
    box.Position=UDim2.fromOffset(57,13)
    box.Size=UDim2.fromOffset(98,174)
    box.BackgroundTransparency=1
    box.BorderSizePixel=1
    box.BorderColor3=Color3.fromRGB(119,120,255)
    box.ZIndex=181
    box.Visible=false
    box.Parent=overlay

    local corners={}
    local function addCorner(a,b) table.insert(corners,guiLine("Corner",a,b,1.5,Color3.new(1,1,1))) end
    local l,r,t,b=57,155,13,187
    local cw,ch=25,32
    addCorner(Vector2.new(l,t),Vector2.new(l+cw,t)); addCorner(Vector2.new(l,t),Vector2.new(l,t+ch))
    addCorner(Vector2.new(r,t),Vector2.new(r-cw,t)); addCorner(Vector2.new(r,t),Vector2.new(r,t+ch))
    addCorner(Vector2.new(l,b),Vector2.new(l+cw,b)); addCorner(Vector2.new(l,b),Vector2.new(l,b-ch))
    addCorner(Vector2.new(r,b),Vector2.new(r-cw,b)); addCorner(Vector2.new(r,b),Vector2.new(r,b-ch))

    local tracer=guiLine("Tracer",Vector2.new(106,205),Vector2.new(106,102),1.4,Color3.new(1,1,1))
    tracer.Visible=false

    local skeleton={
        guiLine("Bone",Vector2.new(106,43),Vector2.new(106,86),1.5,Color3.new(1,1,1)),
        guiLine("Bone",Vector2.new(106,86),Vector2.new(106,125),1.5,Color3.new(1,1,1)),
        guiLine("Bone",Vector2.new(106,72),Vector2.new(72,105),1.5,Color3.new(1,1,1)),
        guiLine("Bone",Vector2.new(106,72),Vector2.new(140,105),1.5,Color3.new(1,1,1)),
        guiLine("Bone",Vector2.new(106,125),Vector2.new(82,173),1.5,Color3.new(1,1,1)),
        guiLine("Bone",Vector2.new(106,125),Vector2.new(130,173),1.5,Color3.new(1,1,1)),
    }
    for _,x in ipairs(skeleton) do x.Visible=false end

    local name=Instance.new("TextLabel")
    name.BackgroundTransparency=1
    name.Position=UDim2.fromOffset(25,2)
    name.Size=UDim2.fromOffset(162,18)
    name.Font=Enum.Font.Code
    name.TextSize=10
    name.TextStrokeTransparency=.15
    name.TextColor3=Color3.new(1,1,1)
    name.Text="TEST_DUMMY"
    name.ZIndex=182
    name.Visible=false
    name.Parent=overlay

    local distance=Instance.new("TextLabel")
    distance.BackgroundTransparency=1
    distance.Position=UDim2.fromOffset(62,184)
    distance.Size=UDim2.fromOffset(90,16)
    distance.Font=Enum.Font.Code
    distance.TextSize=9
    distance.TextStrokeTransparency=.2
    distance.TextColor3=Color3.new(1,1,1)
    distance.Text="25 studs"
    distance.ZIndex=182
    distance.Visible=false
    distance.Parent=overlay

    local hpBack=Instance.new("Frame")
    hpBack.Position=UDim2.fromOffset(49,12)
    hpBack.Size=UDim2.fromOffset(4,176)
    hpBack.BackgroundColor3=Color3.fromRGB(20,20,22)
    hpBack.BorderSizePixel=0
    hpBack.ZIndex=182
    hpBack.Visible=false
    hpBack.Parent=overlay
    local hpFill=Instance.new("Frame")
    hpFill.AnchorPoint=Vector2.new(0,1)
    hpFill.Position=UDim2.new(0,0,1,0)
    hpFill.Size=UDim2.fromScale(1,1)
    hpFill.BorderSizePixel=0
    hpFill.ZIndex=183
    hpFill.Parent=hpBack

    local info=Instance.new("TextLabel")
    info.Position=UDim2.fromOffset(12,258)
    info.Size=UDim2.new(1,-24,0,20)
    info.BackgroundTransparency=1
    info.Font=Enum.Font.SourceSansSemibold
    info.TextSize=12
    info.TextColor3=Color3.fromRGB(232,232,238)
    info.TextXAlignment=Enum.TextXAlignment.Left
    info.Text="TEST_DUMMY • HP 100%"
    info.ZIndex=172
    info.Parent=frame

    local hpSlider=Instance.new("Frame")
    hpSlider.Position=UDim2.fromOffset(12,286)
    hpSlider.Size=UDim2.new(1,-24,0,8)
    hpSlider.BackgroundColor3=Color3.fromRGB(39,40,48)
    hpSlider.BorderSizePixel=0
    hpSlider.Active=true
    hpSlider.ZIndex=172
    hpSlider.Parent=frame
    rounded(hpSlider,4)
    local hpSliderFill=Instance.new("Frame")
    hpSliderFill.Size=UDim2.fromScale(1,1)
    hpSliderFill.BorderSizePixel=0
    hpSliderFill.ZIndex=173
    hpSliderFill.Parent=hpSlider
    rounded(hpSliderFill,4)
    local hint=Instance.new("TextLabel")
    hint.Position=UDim2.fromOffset(12,298)
    hint.Size=UDim2.new(1,-24,0,16)
    hint.BackgroundTransparency=1
    hint.Font=Enum.Font.SourceSans
    hint.TextSize=10
    hint.TextColor3=Color3.fromRGB(130,135,150)
    hint.TextXAlignment=Enum.TextXAlignment.Left
    hint.Text="drag HP bar to preview gradient"
    hint.ZIndex=172
    hint.Parent=frame

    local function healthColor(ratio)
        ratio=math.clamp(ratio,0,1)
        if ratio>=.5 then
            local t=(ratio-.5)/.5
            return Color3.new(1-t,1,0)
        end
        return Color3.new(1,ratio/.5,0)
    end

    local hpDragging=false
    local function setHPFromX(x)
        local a=math.clamp((x-hpSlider.AbsolutePosition.X)/math.max(1,hpSlider.AbsoluteSize.X),0,1)
        State.Visuals.PreviewHealth=math.floor(a*100+.5)
    end
    hpSlider.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then hpDragging=true; setHPFromX(i.Position.X) end
    end)
    UIS.InputChanged:Connect(function(i)
        if hpDragging and i.UserInputType==Enum.UserInputType.MouseMovement then setHPFromX(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then hpDragging=false end
    end)

    local dragging=false
    local startMouse,startPos
    header.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; startMouse=i.Position; startPos=frame.Position end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-startMouse
            frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)

    local function setLines(lines,visible,color,trans)
        for _,x in ipairs(lines) do
            x.Visible=visible
            x.BackgroundColor3=color
            x.BackgroundTransparency=math.clamp((trans or 0)/100,0,1)
        end
    end

    RunService.RenderStepped:Connect(function()
        -- Hide the legacy preview generated by UnifiedTestVisualsV5; this dedicated
        -- preview is synthetic and therefore never shows a real player's avatar.
        local legacy=UI.Gui:FindFirstChild("LvkHubUnifiedPreviewV4")
        if legacy then legacy.Visible=false end

        frame.Visible=State.Visuals.Preview==true and UI.Main.Visible==true
        if not frame.Visible then return end

        cfg=State.Visuals._V5Config or cfg
        local hp=math.clamp((tonumber(State.Visuals.PreviewHealth) or 100)/100,0,1)
        local hc=healthColor(hp)
        hpSliderFill.Size=UDim2.new(hp,0,1,0)
        hpSliderFill.BackgroundColor3=hc
        hpFill.Size=UDim2.new(1,0,hp,0)
        hpFill.BackgroundColor3=hc
        info.Text=string.format("TEST_DUMMY • HP %d%%",math.floor(hp*100+.5))

        local targetBlue=UI.Accent
        local boxColor=cfg.Box3DColor or targetBlue
        local cornerColor=cfg.CornerColor or Color3.new(1,1,1)
        local nameColor=cfg.NameColor or Color3.new(1,1,1)
        local tracerColor=cfg.TracerColor or Color3.new(1,1,1)
        local skeletonColor=cfg.SkeletonColor or Color3.new(1,1,1)
        local thermalColor=cfg.ThermalColor or Color3.fromRGB(255,145,60)
        local espColor=cfg.ESPVisibleColor or Color3.fromRGB(55,235,95)

        local esp=State.Visuals.ESP==true
        box.Visible=State.Visuals.Box3D==true
        box.BorderColor3=boxColor
        box.BackgroundTransparency=1

        local cornersVisible=State.Visuals.CornerBox==true or esp or State.Visuals.ThermalCorner==true
        local cc=esp and espColor or (State.Visuals.ThermalCorner and thermalColor or cornerColor)
        setLines(corners,cornersVisible,cc,esp and cfg.ESPTransparency or cfg.CornerTransparency)

        local chams=State.Visuals.Chams==true or esp
        local chamsColor=esp and espColor or (cfg.ChamsColor or targetBlue)
        for p,original in pairs(dummyParts) do
            if chams then
                p.Color=chamsColor
                p.Material=Enum.Material.ForceField
                p.Transparency=math.clamp((cfg.ChamsTransparency or 62)/100,0,.9)
            else
                p.Color=original
                p.Material=Enum.Material.SmoothPlastic
                p.Transparency=0
            end
        end

        local namesOn=State.Visuals.NameDistance==true or esp
        name.Visible=namesOn
        distance.Visible=namesOn
        name.TextColor3=esp and espColor or nameColor
        distance.TextColor3=name.TextColor3
        name.TextTransparency=math.clamp((cfg.NameTransparency or 0)/100,0,1)
        distance.TextTransparency=name.TextTransparency

        hpBack.Visible=State.Visuals.HealthBar==true or esp
        hpBack.BackgroundTransparency=math.clamp((cfg.HealthTransparency or 0)/100,0,1)
        hpFill.BackgroundTransparency=hpBack.BackgroundTransparency

        tracer.Visible=State.Visuals.Tracers==true
        tracer.BackgroundColor3=tracerColor
        tracer.BackgroundTransparency=math.clamp((cfg.TracerTransparency or 0)/100,0,1)

        setLines(skeleton,State.Visuals.Skeleton==true,skeletonColor,cfg.SkeletonTransparency)
    end)
end
