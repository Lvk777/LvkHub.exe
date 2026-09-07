-- Dummy-only Target Info card. Reads Workspace.TestPlayers through Registry only.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local UIS=game:GetService("UserInputService")

    State.Visuals.TargetInfo=State.Visuals.TargetInfo==true
    UI.Toggle(UI.Pages.Visuals,"Target Info",function() return State.Visuals.TargetInfo end,function(v) State.Visuals.TargetInfo=v end)

    local frame=Instance.new("Frame")
    frame.Name="LvkHubDummyTargetInfo"
    frame.Size=UDim2.fromOffset(245,105)
    frame.Position=UDim2.fromOffset(18,18)
    frame.BackgroundColor3=Color3.fromRGB(23,22,26)
    frame.BorderSizePixel=0
    frame.Visible=false
    frame.ZIndex=90
    frame.Parent=UI.Gui
    local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,7); corner.Parent=frame

    local header=Instance.new("Frame")
    header.Size=UDim2.new(1,0,0,37)
    header.BackgroundColor3=Color3.fromRGB(29,28,32)
    header.BorderSizePixel=0
    header.Active=true
    header.ZIndex=91
    header.Parent=frame
    local hc=Instance.new("UICorner"); hc.CornerRadius=UDim.new(0,7); hc.Parent=header

    local title=Instance.new("TextLabel")
    title.BackgroundTransparency=1
    title.Position=UDim2.fromOffset(12,0)
    title.Size=UDim2.new(1,-55,1,0)
    title.Font=Enum.Font.SourceSansSemibold
    title.TextSize=14
    title.TextColor3=Color3.fromRGB(225,225,230)
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Text="Target Info"
    title.ZIndex=92
    title.Parent=header

    local dots=Instance.new("TextButton")
    dots.AnchorPoint=Vector2.new(1,.5)
    dots.Position=UDim2.new(1,-8,.5,0)
    dots.Size=UDim2.fromOffset(28,24)
    dots.BackgroundTransparency=1
    dots.Text="⋮"
    dots.Font=Enum.Font.SourceSansBold
    dots.TextSize=20
    dots.TextColor3=Color3.fromRGB(175,175,185)
    dots.ZIndex=94
    dots.Parent=header

    local menu=Instance.new("Frame")
    menu.AnchorPoint=Vector2.new(1,0)
    menu.Position=UDim2.new(1,-4,0,34)
    menu.Size=UDim2.fromOffset(142,36)
    menu.BackgroundColor3=Color3.fromRGB(28,28,33)
    menu.BorderSizePixel=0
    menu.Visible=false
    menu.ZIndex=100
    menu.Parent=frame
    local mc=Instance.new("UICorner"); mc.CornerRadius=UDim.new(0,5); mc.Parent=menu
    local ms=Instance.new("UIStroke"); ms.Color=Color3.fromRGB(55,56,66); ms.Parent=menu

    local invButton=Instance.new("TextButton")
    invButton.Position=UDim2.fromOffset(5,5)
    invButton.Size=UDim2.new(1,-10,1,-10)
    invButton.BackgroundColor3=Color3.fromRGB(36,36,42)
    invButton.BorderSizePixel=0
    invButton.Font=Enum.Font.SourceSans
    invButton.TextSize=12
    invButton.TextColor3=Color3.fromRGB(224,224,230)
    invButton.Text="Inventory Viewer"
    invButton.ZIndex=101
    invButton.Parent=menu
    local ibc=Instance.new("UICorner"); ibc.CornerRadius=UDim.new(0,4); ibc.Parent=invButton

    local avatar=Instance.new("ImageLabel")
    avatar.Position=UDim2.fromOffset(12,46)
    avatar.Size=UDim2.fromOffset(52,52)
    avatar.BackgroundColor3=Color3.fromRGB(31,31,36)
    avatar.BorderSizePixel=0
    avatar.ZIndex=91
    avatar.Parent=frame
    local ac=Instance.new("UICorner"); ac.CornerRadius=UDim.new(1,0); ac.Parent=avatar

    local name=Instance.new("TextLabel")
    name.BackgroundTransparency=1
    name.Position=UDim2.fromOffset(75,46)
    name.Size=UDim2.new(1,-86,0,21)
    name.Font=Enum.Font.SourceSans
    name.TextSize=14
    name.TextColor3=Color3.fromRGB(190,190,198)
    name.TextXAlignment=Enum.TextXAlignment.Left
    name.Text="No target"
    name.ZIndex=91
    name.Parent=frame

    local hpBack=Instance.new("Frame")
    hpBack.Position=UDim2.fromOffset(75,76)
    hpBack.Size=UDim2.new(1,-87,0,4)
    hpBack.BackgroundColor3=Color3.fromRGB(48,48,54)
    hpBack.BorderSizePixel=0
    hpBack.ZIndex=91
    hpBack.Parent=frame
    local hp=Instance.new("Frame")
    hp.Size=UDim2.fromScale(0,1)
    hp.BackgroundColor3=Color3.fromRGB(62,204,150)
    hp.BorderSizePixel=0
    hp.ZIndex=92
    hp.Parent=hpBack

    local hpText=Instance.new("TextLabel")
    hpText.BackgroundTransparency=1
    hpText.Position=UDim2.fromOffset(75,82)
    hpText.Size=UDim2.new(1,-87,0,16)
    hpText.Font=Enum.Font.Code
    hpText.TextSize=10
    hpText.TextColor3=Color3.fromRGB(145,150,160)
    hpText.TextXAlignment=Enum.TextXAlignment.Left
    hpText.Text="HP --"
    hpText.ZIndex=91
    hpText.Parent=frame

    local dragging=false
    local startMouse,startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; startMouse=input.Position; startPos=frame.Position end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
            local d=input.Position-startMouse
            frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)

    local current=nil
    local thumbCache={}
    local thumbPending={}
    local function selectTarget()
        local api=shared.LvkHubDummyAimAPI
        if api and type(api.ChooseTarget)=="function" then
            local m=api.ChooseTarget(false)
            if m and Registry.IsBot(m) then return m end
        end
        return nil
    end

    local function updateAvatar(model)
        local source=model and model:GetAttribute("LvkHubSourceName")
        local plr=source and Players:FindFirstChild(source)
        if not plr then avatar.Image=""; return source or model.Name end
        local display=plr.DisplayName
        if thumbCache[plr.UserId] then avatar.Image=thumbCache[plr.UserId]; return display end
        if not thumbPending[plr.UserId] then
            thumbPending[plr.UserId]=true
            task.spawn(function()
                local ok,img=pcall(function() return Players:GetUserThumbnailAsync(plr.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150) end)
                thumbPending[plr.UserId]=nil
                if ok then thumbCache[plr.UserId]=img; if current==model then avatar.Image=img end end
            end)
        end
        return display
    end

    dots.MouseButton1Click:Connect(function() menu.Visible=not menu.Visible end)
    invButton.MouseButton1Click:Connect(function()
        menu.Visible=false
        if not current or not Registry.IsBot(current) then return end
        State.Combat.SelectedBot=current
        State.Combat.DummyInventoryVisible=true
    end)

    local timer=0
    RunService.RenderStepped:Connect(function(dt)
        frame.Visible=State.Visuals.TargetInfo==true
        if not frame.Visible then menu.Visible=false; return end
        timer+=dt
        if timer<.12 then return end
        timer=0
        local model=selectTarget()
        if model~=current then current=model; avatar.Image=""; menu.Visible=false end
        if not model then name.Text="No target"; hp.Size=UDim2.fromScale(0,1); hpText.Text="HP --"; return end
        local hum=Registry.HumanoidOf(model)
        local ratio=hum and math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1) or 0
        name.Text=updateAvatar(model)
        hp.Size=UDim2.new(ratio,0,1,0)
        hpText.Text=string.format("HP %.0f / %.0f",hum and hum.Health or 0,hum and hum.MaxHealth or 0)
    end)
end
