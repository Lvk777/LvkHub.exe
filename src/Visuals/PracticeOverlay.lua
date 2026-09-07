-- Local practice overlay for Workspace.TestPlayers only: snapline, target focus and custom crosshair.
return function(State, Registry, UI)
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")
    local UIS=game:GetService("UserInputService")

    State.Visuals.Snapline=State.Visuals.Snapline==true
    State.Visuals.CustomCrosshair=State.Visuals.CustomCrosshair==true
    local C=State.Visuals._PracticeOverlay or {
        SnapColor=Color3.fromRGB(119,120,255), SnapTransparency=0,
        CrossColor=Color3.fromRGB(255,255,255), CrossTransparency=0,
        CrossSize=8, CrossGap=5,
    }
    State.Visuals._PracticeOverlay=C

    local function rounded(o,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 4); c.Parent=o end
    local function makeLine(name)
        local f=Instance.new("Frame"); f.Name=name; f.AnchorPoint=Vector2.new(.5,.5); f.BorderSizePixel=0; f.Visible=false; f.ZIndex=150; f.Parent=UI.Gui; return f
    end
    local function setLine(f,a,b,width,color,trans)
        local d=b-a
        if d.Magnitude<.01 then f.Visible=false return end
        f.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
        f.Size=UDim2.fromOffset(d.Magnitude,width)
        f.Rotation=math.deg(math.atan2(d.Y,d.X))
        f.BackgroundColor3=color
        f.BackgroundTransparency=math.clamp((trans or 0)/100,0,1)
        f.Visible=true
    end

    local snap=makeLine("LvkHubPracticeSnapline")
    local cross={makeLine("CrossL"),makeLine("CrossR"),makeLine("CrossT"),makeLine("CrossB")}
    local focus=nil
    local focusModel=nil

    local function addSimpleToggle(label,get,set)
        local row,text=UI.Row(UI.Pages.Visuals,label); text.Size=UDim2.new(1,-48,1,0)
        local b=Instance.new("TextButton"); b.AnchorPoint=Vector2.new(1,.5); b.Position=UDim2.new(1,-7,.5,0); b.Size=UDim2.fromOffset(28,18); b.Text=""; b.BorderSizePixel=0; b.Parent=row; rounded(b,3)
        local mark=Instance.new("Frame"); mark.AnchorPoint=Vector2.new(.5,.5); mark.Position=UDim2.fromScale(.5,.5); mark.Size=UDim2.fromOffset(18,10); mark.BorderSizePixel=0; mark.Parent=b; rounded(mark,2)
        local function paint() local on=get(); b.BackgroundColor3=on and UI.Accent or Color3.fromRGB(45,45,45); mark.BackgroundColor3=on and Color3.fromRGB(238,238,240) or Color3.fromRGB(86,86,86) end
        b.MouseButton1Click:Connect(function() set(not get()); paint() end); paint()
    end

    UI.Section(UI.Pages.Visuals,"Practice Overlay")
    addSimpleToggle("Snapline",function() return State.Visuals.Snapline end,function(v) State.Visuals.Snapline=v end)
    addSimpleToggle("Custom Crosshair",function() return State.Visuals.CustomCrosshair end,function(v) State.Visuals.CustomCrosshair=v end)

    local function currentTarget()
        local m=State.Combat and State.Combat.SelectedBot or nil
        if m and Registry.IsBot(m) then
            local p=m:FindFirstChild("Head") or Registry.RootOf(m)
            return m,p
        end
        return nil,nil
    end

    RunService.RenderStepped:Connect(function()
        local cam=Workspace.CurrentCamera
        if not cam then return end
        local m,p=currentTarget()

        if focusModel~=m then if focus then focus:Destroy(); focus=nil end; focusModel=m end
        if m and Registry.IsBot(m) then
            if not focus then focus=Instance.new("Highlight"); focus.Name="LvkHubPracticeTargetBlue"; focus.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; focus.FillTransparency=.84; focus.OutlineTransparency=0; focus.Parent=m end
            focus.Adornee=m; focus.FillColor=UI.Accent; focus.OutlineColor=UI.Accent; focus.Enabled=true
        elseif focus then focus.Enabled=false end

        if State.Visuals.Snapline and m and p then
            local sp,on=cam:WorldToViewportPoint(p.Position)
            if on and sp.Z>0 then setLine(snap,cam.ViewportSize/2,Vector2.new(sp.X,sp.Y),1.25,C.SnapColor,C.SnapTransparency) else snap.Visible=false end
        else snap.Visible=false end

        if State.Visuals.CustomCrosshair then
            local c=cam.ViewportSize/2; local s=C.CrossSize; local g=C.CrossGap; local col=C.CrossColor; local tr=C.CrossTransparency
            setLine(cross[1],Vector2.new(c.X-g-s,c.Y),Vector2.new(c.X-g,c.Y),1.5,col,tr)
            setLine(cross[2],Vector2.new(c.X+g,c.Y),Vector2.new(c.X+g+s,c.Y),1.5,col,tr)
            setLine(cross[3],Vector2.new(c.X,c.Y-g-s),Vector2.new(c.X,c.Y-g),1.5,col,tr)
            setLine(cross[4],Vector2.new(c.X,c.Y+g),Vector2.new(c.X,c.Y+g+s),1.5,col,tr)
        else for _,f in ipairs(cross) do f.Visible=false end end
    end)
end
