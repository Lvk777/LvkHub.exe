-- Thermal-style animated border for the existing FOV circle.
-- Center stays completely transparent; animation runs only around the perimeter.
return function(State, UI)
    local RunService=game:GetService("RunService")
    local CoreGui=game:GetService("CoreGui")
    local parent=(gethui and gethui()) or CoreGui
    local fovGui=parent:FindFirstChild("LvkHubAimFOV")
    if not fovGui then return end

    local circle=nil
    for _,x in ipairs(fovGui:GetChildren()) do if x:IsA("Frame") then circle=x break end end
    if not circle then return end
    circle.BackgroundTransparency=1
    local oldGrad=circle:FindFirstChildWhichIsA("UIGradient")
    if oldGrad then oldGrad.Enabled=false end
    local oldStroke=circle:FindFirstChildWhichIsA("UIStroke")
    if oldStroke then oldStroke.Transparency=.82;oldStroke.Color=Color3.fromRGB(90,95,130);oldStroke.Thickness=1 end

    local old=fovGui:FindFirstChild("LvkHubThermalFOVRingV2")
    if old then old:Destroy() end
    local holder=Instance.new("Frame")
    holder.Name="LvkHubThermalFOVRingV2"
    holder.BackgroundTransparency=1
    holder.Size=UDim2.fromScale(1,1)
    holder.Position=UDim2.fromScale(0,0)
    holder.ZIndex=20
    holder.Parent=fovGui

    local N=72
    local segs={}
    for i=1,N do
        local f=Instance.new("Frame")
        f.AnchorPoint=Vector2.new(.5,.5)
        f.BorderSizePixel=0
        f.BackgroundColor3=Color3.fromRGB(120,120,255)
        f.ZIndex=21
        f.Parent=holder
        local c=Instance.new("UICorner");c.CornerRadius=UDim.new(1,0);c.Parent=f
        segs[i]=f
    end

    local stops={
        {0.00,Color3.fromRGB(72,84,255)},
        {0.20,Color3.fromRGB(54,205,255)},
        {0.43,Color3.fromRGB(137,90,255)},
        {0.66,Color3.fromRGB(245,78,205)},
        {0.84,Color3.fromRGB(255,132,92)},
        {1.00,Color3.fromRGB(72,84,255)},
    }
    local function thermalColor(t)
        t=t%1
        for i=1,#stops-1 do
            local a,b=stops[i],stops[i+1]
            if t>=a[1] and t<=b[1] then
                local u=(t-a[1])/math.max(.0001,b[1]-a[1])
                return a[2]:Lerp(b[2],u)
            end
        end
        return stops[#stops][2]
    end

    local phase=0
    RunService.RenderStepped:Connect(function(dt)
        if not circle.Parent or not holder.Parent then return end
        local show=State.Combat and State.Combat.ShowAimFOV==true and circle.Visible~=false
        holder.Visible=show
        if not show then return end
        phase=(phase+dt*.11)%1

        local ap=circle.AbsolutePosition
        local as=circle.AbsoluteSize
        local center=Vector2.new(ap.X+as.X*.5,ap.Y+as.Y*.5)
        local radius=math.max(2,math.min(as.X,as.Y)*.5)
        local circumference=2*math.pi*radius
        local segLen=math.max(3,circumference/N*1.16)

        for i,f in ipairs(segs) do
            local a=((i-1)/N)*math.pi*2
            local p=center+Vector2.new(math.cos(a),math.sin(a))*radius
            f.Position=UDim2.fromOffset(p.X,p.Y)
            f.Size=UDim2.fromOffset(segLen,2.2)
            f.Rotation=math.deg(a)+90
            local u=((i-1)/N+phase)%1
            local pulse=.5+.5*math.sin((u-phase)*math.pi*2*3-os.clock()*1.6)
            f.BackgroundColor3=thermalColor(u)
            f.BackgroundTransparency=.02+.28*(1-pulse)
        end
    end)
end
