-- Border-only animated FOV polish for the local TestPlayers practice ring.
-- Keeps the center fully transparent and animates a bright travelling arc around
-- the circumference instead of filling the circle with a rainbow gradient.
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

    circle.BackgroundTransparency=1
    local oldGrad=circle:FindFirstChildWhichIsA("UIGradient")
    if oldGrad then oldGrad.Enabled=false end
    local stroke=circle:FindFirstChildWhichIsA("UIStroke")
    if stroke then
        stroke.Color=Color3.fromRGB(76,80,112)
        stroke.Transparency=.35
        stroke.Thickness=1
    end

    local old=fovGui:FindFirstChild("LvkHubFOVBorderSegments")
    if old then old:Destroy() end
    local holder=Instance.new("Frame")
    holder.Name="LvkHubFOVBorderSegments"
    holder.BackgroundTransparency=1
    holder.Size=UDim2.fromScale(1,1)
    holder.Position=UDim2.fromOffset(0,0)
    holder.Parent=fovGui

    local count=48
    local dots={}
    for i=1,count do
        local d=Instance.new("Frame")
        d.Name="FOVDot"..i
        d.AnchorPoint=Vector2.new(.5,.5)
        d.Size=UDim2.fromOffset(3,3)
        d.BorderSizePixel=0
        d.BackgroundColor3=Color3.fromRGB(78,92,150)
        d.BackgroundTransparency=.78
        d.ZIndex=20
        d.Parent=holder
        local c=Instance.new("UICorner")
        c.CornerRadius=UDim.new(1,0)
        c.Parent=d
        dots[i]=d
    end

    local phase=0
    RunService.RenderStepped:Connect(function(dt)
        if not circle.Parent or not holder.Parent then return end
        local show=circle.Visible==true and State.Combat and State.Combat.ShowAimFOV==true
        holder.Visible=show
        if not show then return end

        phase=(phase+dt*1.18)%(math.pi*2)
        local p=circle.AbsolutePosition
        local s=circle.AbsoluteSize
        local cx=p.X+s.X/2
        local cy=p.Y+s.Y/2
        local rx=math.max(1,s.X/2)
        local ry=math.max(1,s.Y/2)

        for i,d in ipairs(dots) do
            local a=((i-1)/count)*math.pi*2
            d.Position=UDim2.fromOffset(cx+math.cos(a)*rx,cy+math.sin(a)*ry)

            local delta=(a-phase)%(math.pi*2)
            if delta>math.pi then delta=math.pi*2-delta end
            local glow=math.clamp(1-delta/.95,0,1)
            local tail=math.clamp(1-delta/2.3,0,1)
            local hue=(.58+((i-1)/count)*.16+phase/(math.pi*2)*.08)%1
            local bright=Color3.fromHSV(hue,.58,1)
            local base=Color3.fromRGB(75,82,135)
            d.BackgroundColor3=base:Lerp(bright,math.max(glow,tail*.42))
            d.BackgroundTransparency=.78-(glow*.66)-(tail*.10)
            local size=3+glow*2
            d.Size=UDim2.fromOffset(size,size)
        end
    end)
end
