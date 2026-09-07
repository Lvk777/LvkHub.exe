-- Rehomes Visuals ••• popups below Utility and replaces RGB typing with hue drag bars.
return function(State, UI)
    local UIS=game:GetService("UserInputService")
    local visualWin=UI.Windows.Visuals
    local utilityWin=UI.Windows.Utility
    if not visualWin or not utilityWin then return end

    local cfg=State.Visuals._V4Config
    if not cfg then return end

    local map={
        ["3D Box"]={Color="Box3DColor"},
        ["Chams"]={Color="ChamsColor"},
        ["Corner Box"]={Color="CornerColor"},
        ["ESP"]={Visible="ESPVisibleColor",Hidden="ESPHiddenColor"},
        ["Name + Distance"]={Color="NameColor"},
        ["Preview"]={Accent="PreviewAccent"},
        ["Thermal Corner"]={Color="ThermalColor"},
        ["Tracers"]={Color="TracerColor"},
        ["Skeleton"]={Color="SkeletonColor"},
        ["Car ESP"]={Color="CarColor"},
    }

    local rainbow=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(1/6,Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(2/6,Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(3/6,Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(4/6,Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(5/6,Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0)),
    })

    local function titleOf(popup)
        for _,d in ipairs(popup:GetDescendants()) do
            if d:IsA("TextLabel") and map[d.Text] then return d.Text end
        end
    end

    local function enhanceColorRow(row,key)
        if row:FindFirstChild("LvkHueBar") then return end
        for _,d in ipairs(row:GetChildren()) do
            if d:IsA("TextBox") then d.Visible=false end
        end
        local label=row:FindFirstChildWhichIsA("TextLabel")
        if label then label.Size=UDim2.fromOffset(68,row.AbsoluteSize.Y>0 and row.AbsoluteSize.Y or 34) end

        local bar=Instance.new("Frame")
        bar.Name="LvkHueBar"
        bar.Position=UDim2.fromOffset(76,9)
        bar.Size=UDim2.new(1,-86,0,16)
        bar.BackgroundColor3=Color3.new(1,1,1)
        bar.BorderSizePixel=0
        bar.Active=true
        bar.ZIndex=70
        bar.Parent=row
        local bc=Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,4); bc.Parent=bar
        local grad=Instance.new("UIGradient"); grad.Color=rainbow; grad.Parent=bar

        local knob=Instance.new("Frame")
        knob.Name="Knob"
        knob.AnchorPoint=Vector2.new(.5,.5)
        knob.Position=UDim2.new(0,0,.5,0)
        knob.Size=UDim2.fromOffset(4,22)
        knob.BackgroundColor3=Color3.fromRGB(245,245,248)
        knob.BorderSizePixel=0
        knob.ZIndex=72
        knob.Parent=bar
        local ks=Instance.new("UIStroke"); ks.Color=Color3.fromRGB(25,25,28); ks.Thickness=1; ks.Parent=knob

        local dragging=false
        local function paintFromColor()
            local c=cfg[key]
            if typeof(c)~="Color3" then return end
            local h=select(1,c:ToHSV())
            knob.Position=UDim2.new(h,0,.5,0)
        end
        local function setFromX(x)
            local w=math.max(1,bar.AbsoluteSize.X)
            local h=math.clamp((x-bar.AbsolutePosition.X)/w,0,1)
            cfg[key]=Color3.fromHSV(h,1,1)
            knob.Position=UDim2.new(h,0,.5,0)
        end
        bar.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; setFromX(input.Position.X) end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then setFromX(input.Position.X) end
        end)
        UIS.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
        task.defer(paintFromColor)
    end

    local function enhance(popup)
        if not popup or popup.Name~="VisualSettingsPopupV4" then return end
        popup.Parent=utilityWin
        popup.Position=UDim2.new(0,0,1,6)
        popup.ZIndex=80
        task.delay(.04,function()
            if not popup.Parent then return end
            local title=titleOf(popup)
            local keys=title and map[title]
            if not keys then return end
            for _,row in ipairs(popup:GetDescendants()) do
                if row:IsA("Frame") then
                    local lbl=row:FindFirstChildWhichIsA("TextLabel")
                    local key=lbl and keys[lbl.Text]
                    if key then enhanceColorRow(row,key) end
                end
            end
        end)
    end

    visualWin.ChildAdded:Connect(function(child) if child.Name=="VisualSettingsPopupV4" then task.defer(enhance,child) end end)
    local existing=visualWin:FindFirstChild("VisualSettingsPopupV4")
    if existing then enhance(existing) end
end
