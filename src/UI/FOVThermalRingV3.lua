-- Single thermal-style animated FOV border.
-- Hides the original CombatV4 fill/stroke every frame so only one perimeter ring is visible.
return function(State, UI)
    local RunService=game:GetService("RunService")
    local CoreGui=game:GetService("CoreGui")
    local parent=(gethui and gethui()) or CoreGui
    local fovGui=parent:FindFirstChild("LvkHubAimFOV")
    if not fovGui then return end

    local circle=nil
    for _,x in ipairs(fovGui:GetChildren()) do
        if x:IsA("Frame") and x.Name~="LvkHubThermalFOVRingV2" and x.Name~="LvkHubThermalFOVRingV3" then
            circle=x
            break
        end
    end
    if not circle then return end

    for _,name in ipairs({"LvkHubThermalFOVRingV2","LvkHubThermalFOVRingV3"}) do
        local old=fovGui:FindFirstChild(name)
        if old then old:Destroy() end
    end

    local holder=Instance.new("Frame")
    holder.Name="LvkHubThermalFOVRingV3"
    holder.BackgroundTransparency=1
    holder.Size=UDim2.fromScale(1,1)
    holder.Position=UDim2.fromScale(0,0)
    holder.ZIndex=25
    holder.Parent=fovGui

    local N=120
    local segs={}
    for i=1,N do
        local f=Instance.new("Frame")
        f.AnchorPoint=Vector2.new(.5,.5)
        f.BorderSizePixel=0
        f.BackgroundColor3=Color3.fromRGB(119,120,255)
        f.ZIndex=26
        f.Parent=holder
        local c=Instance.new("UICorner")
        c.CornerRadius=UDim.new(1,0)
        c.Parent=f
        segs[i]=f
    end

    local stops={
        {0.00,Color3.fromRGB(92,105,255)},
        {0.18,Color3.fromRGB(67,215,255)},
        {0.38,Color3.fromRGB(130,95,255)},
        {0.58,Color3.fromRGB(248,77,186)},
        {0.78,Color3.fromRGB(255,126,86)},
        {1.00,Color3.fromRGB(92,105,255)},
    }

    local function colorAt(t)
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

        -- CombatV4 keeps animating its old UIStroke; suppress it continuously.
        circle.BackgroundTransparency=1
        local oldStroke=circle:FindFirstChildWhichIsA("UIStroke")
        if oldStroke then oldStroke.Transparency=1 end
        local oldGrad=circle:FindFirstChildWhichIsA("UIGradient")
        if oldGrad then oldGrad.Enabled=false end

        local show=State.Combat and State.Combat.ShowAimFOV==true and circle.Visible~=false
        holder.Visible=show
        if not show then return end

        phase=(phase+dt*.095)%1
        local ap=circle.AbsolutePosition
        local as=circle.AbsoluteSize
        local center=Vector2.new(ap.X+as.X*.5,ap.Y+as.Y*.5)
        local radius=math.max(2,math.min(as.X,as.Y)*.5)
        local circumference=2*math.pi*radius
        local segLen=math.max(2.5,circumference/N*1.12)

        for i,f in ipairs(segs) do
            local k=(i-1)/N
            local a=k*math.pi*2
            local p=center+Vector2.new(math.cos(a),math.sin(a))*radius
            f.Position=UDim2.fromOffset(p.X,p.Y)
            f.Size=UDim2.fromOffset(segLen,2.35)
            f.Rotation=math.deg(a)+90

            local u=(k+phase)%1
            local hot=.5+.5*math.cos((u-.04)*math.pi*2)
            hot=hot^5
            local pulse=.5+.5*math.sin(k*math.pi*10-os.clock()*2.4)
            f.BackgroundColor3=colorAt(u)
            f.BackgroundTransparency=.03+.18*(1-hot)+.06*(1-pulse)
        end
    end)
end
