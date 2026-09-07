-- Continuous border-beam animation for the existing LvkHub FOV ring.
-- Reuses the current LvkHubAimFOV circle; no second FOV circle is created.
-- Two-tone animated border for the EXISTING LvkHub FOV ring.
-- No second FOV circle/holder is created.
return function(State, UI)
    local RunService=game:GetService("RunService")
    local CoreGui=game:GetService("CoreGui")
@@ -10,97 +10,61 @@ return function(State, UI)

    local circle=nil
    for _,x in ipairs(fovGui:GetChildren()) do
        if x:IsA("Frame") then circle=x break end
        if x:IsA("Frame") and x.Name~="LvkHubFOVBorderBeam" then
            circle=x
            break
        end
    end
    if not circle then return end

    -- The original ring becomes the geometry source only. Center stays transparent.
    circle.BackgroundTransparency=1
    local oldGrad=circle:FindFirstChildWhichIsA("UIGradient")
    if oldGrad then oldGrad.Enabled=false end
    local stroke=circle:FindFirstChildWhichIsA("UIStroke")
    if stroke then
        stroke.Transparency=1
    end

    local old=fovGui:FindFirstChild("LvkHubFOVBorderBeam")
    if old then old:Destroy() end
    -- Remove the old segmented second ring if a previous build created it.
    local duplicate=fovGui:FindFirstChild("LvkHubFOVBorderBeam")
    if duplicate then duplicate:Destroy() end

    local holder=Instance.new("Frame")
    holder.Name="LvkHubFOVBorderBeam"
    holder.BackgroundTransparency=1
    holder.Size=UDim2.fromScale(1,1)
    holder.Position=UDim2.fromOffset(0,0)
    holder.BorderSizePixel=0
    holder.ZIndex=30
    holder.Parent=fovGui
    -- Keep the center completely transparent; only the original border is styled.
    circle.BackgroundTransparency=1
    local bodyGradient=circle:FindFirstChildWhichIsA("UIGradient")
    if bodyGradient then bodyGradient.Enabled=false end

    -- Closely-connected chords form one continuous circular border.
    local count=112
    local segs={}
    for i=1,count do
        local seg=Instance.new("Frame")
        seg.Name="BeamSegment"..i
        seg.AnchorPoint=Vector2.new(.5,.5)
        seg.BorderSizePixel=0
        seg.BackgroundColor3=Color3.fromRGB(88,130,255)
        seg.BackgroundTransparency=.16
        seg.ZIndex=31
        seg.Parent=holder
        local corner=Instance.new("UICorner")
        corner.CornerRadius=UDim.new(1,0)
        corner.Parent=seg
        segs[i]=seg
    local stroke=circle:FindFirstChildWhichIsA("UIStroke")
    if not stroke then
        stroke=Instance.new("UIStroke")
        stroke.Parent=circle
    end
    stroke.Thickness=1.65
    stroke.Transparency=.025
    stroke.Color=Color3.new(1,1,1)

    local phase=0
    local tau=math.pi*2
    local oldGradient=stroke:FindFirstChild("LvkHubFOVStrokeGradient")
    if oldGradient then oldGradient:Destroy() end

    local function cyclicDistance(a,b)
        local d=math.abs((a-b)%tau)
        return math.min(d,tau-d)
    end
    local gradient=Instance.new("UIGradient")
    gradient.Name="LvkHubFOVStrokeGradient"
    gradient.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0.00,Color3.fromRGB(248,105,218)),
        ColorSequenceKeypoint.new(0.28,Color3.fromRGB(194,118,255)),
        ColorSequenceKeypoint.new(0.52,Color3.fromRGB(118,126,255)),
        ColorSequenceKeypoint.new(0.76,Color3.fromRGB(95,205,255)),
        ColorSequenceKeypoint.new(1.00,Color3.fromRGB(235,118,230)),
    })
    gradient.Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,.02),
        NumberSequenceKeypoint.new(.5,.10),
        NumberSequenceKeypoint.new(1,.02),
    })
    gradient.Rotation=28
    gradient.Parent=stroke

    local rotation=28
    RunService.RenderStepped:Connect(function(dt)
        if not circle.Parent or not holder.Parent then return end
        local show=circle.Visible==true and State.Combat and State.Combat.ShowAimFOV==true
        holder.Visible=show
        if not circle.Parent or not stroke.Parent or not gradient.Parent then return end
        local show=State.Combat and State.Combat.ShowAimFOV==true
        stroke.Enabled=show
        if not show then return end

        phase=(phase+dt*1.45)%tau
        local p=circle.AbsolutePosition
        local s=circle.AbsoluteSize
        local cx=p.X+s.X/2
        local cy=p.Y+s.Y/2
        local rx=math.max(2,s.X/2)
        local ry=math.max(2,s.Y/2)
        local da=tau/count

        for i,seg in ipairs(segs) do
            local a=((i-1)/count)*tau
            local b=a+da*1.08
            local ax=cx+math.cos(a)*rx
            local ay=cy+math.sin(a)*ry
            local bx=cx+math.cos(b)*rx
            local by=cy+math.sin(b)*ry
            local dx,dy=bx-ax,by-ay
            local len=math.sqrt(dx*dx+dy*dy)

            seg.Position=UDim2.fromOffset((ax+bx)/2,(ay+by)/2)
            seg.Size=UDim2.fromOffset(math.max(2,len+1.6),2.2)
            seg.Rotation=math.deg(math.atan2(dy,dx))

            -- Bright beam head + long soft tail moving around the same ring.
            local d=cyclicDistance(a,phase)
            local head=math.clamp(1-d/.34,0,1)
            local tail=math.clamp(1-d/1.55,0,1)
            local glow=math.max(head,tail*.48)
            local base=Color3.fromRGB(92,112,190)
            local beam=Color3.fromRGB(110,225,255)
            local white=Color3.fromRGB(238,250,255)
            seg.BackgroundColor3=base:Lerp(beam,glow):Lerp(white,head*.72)
            seg.BackgroundTransparency=.26-glow*.20
            seg.Size=UDim2.fromOffset(math.max(2,len+1.6),2.1+head*1.8)
        end
        -- Slow thermal-like movement around the same border: opposite sides keep
        -- visibly different pink/purple and blue/cyan tones.
        rotation=(rotation+dt*7.5)%360
        gradient.Rotation=rotation
    end)
end
