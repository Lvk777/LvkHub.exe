-- Continuous border-beam animation for the existing LvkHub FOV ring.
-- Reuses the current LvkHubAimFOV circle; no second FOV circle is created.
return function(State, UI)
    local RunService=game:GetService("RunService")
    local CoreGui=game:GetService("CoreGui")

    local parent=(gethui and gethui()) or CoreGui
    local fovGui=parent:FindFirstChild("LvkHubAimFOV")
    if not fovGui then return end

    local circle=nil
    for _,x in ipairs(fovGui:GetChildren()) do
        if x:IsA("Frame") then circle=x break end
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

    local holder=Instance.new("Frame")
    holder.Name="LvkHubFOVBorderBeam"
    holder.BackgroundTransparency=1
    holder.Size=UDim2.fromScale(1,1)
    holder.Position=UDim2.fromOffset(0,0)
    holder.BorderSizePixel=0
    holder.ZIndex=30
    holder.Parent=fovGui

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
    end

    local phase=0
    local tau=math.pi*2

    local function cyclicDistance(a,b)
        local d=math.abs((a-b)%tau)
        return math.min(d,tau-d)
    end

    RunService.RenderStepped:Connect(function(dt)
        if not circle.Parent or not holder.Parent then return end
        local show=circle.Visible==true and State.Combat and State.Combat.ShowAimFOV==true
        holder.Visible=show
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
    end)
end
