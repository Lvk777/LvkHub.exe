-- UI additions: Vehicle window + reusable keybind row.
return function(State, UI)
    local UIS=game:GetService("UserInputService")
    local Workspace=game:GetService("Workspace")

    local function rounded(obj,r)
        local c=Instance.new("UICorner")
        c.CornerRadius=UDim.new(0,r or 4)
        c.Parent=obj
    end

    if not UI.Pages.Vehicle then
        local main=UI.Main
        local win=Instance.new("Frame")
        win.Name="VehicleWindow"
        win.Size=UDim2.fromOffset(220,37)
        win.Position=UDim2.fromOffset(16+6*230,55)
        win.BackgroundColor3=UI.Colors.Background
        win.BorderSizePixel=0
        win.ClipsDescendants=false
        win.Parent=main
        rounded(win,5)
        local stroke=Instance.new("UIStroke")
        stroke.Color=Color3.fromRGB(32,35,36)
        stroke.Parent=win

        local header=Instance.new("Frame")
        header.Name="Header"
        header.Size=UDim2.new(1,0,0,37)
        header.BackgroundColor3=UI.Colors.Background
        header.BorderSizePixel=0
        header.Active=true
        header.Parent=win
        rounded(header,5)

        local stripe=Instance.new("Frame")
        stripe.Size=UDim2.fromOffset(3,19)
        stripe.Position=UDim2.fromOffset(7,9)
        stripe.BorderSizePixel=0
        stripe.BackgroundColor3=UI.Accent
        stripe.Parent=header
        rounded(stripe,2)

        local title=Instance.new("TextLabel")
        title.BackgroundTransparency=1
        title.Position=UDim2.fromOffset(16,0)
        title.Size=UDim2.new(1,-48,1,0)
        title.Font=Enum.Font.SourceSansSemibold
        title.TextSize=16
        title.TextColor3=Color3.fromRGB(210,210,210)
        title.TextXAlignment=Enum.TextXAlignment.Left
        title.Text="Vehicle"
        title.Parent=header

        local arrow=Instance.new("TextButton")
        arrow.AnchorPoint=Vector2.new(1,.5)
        arrow.Position=UDim2.new(1,-8,.5,0)
        arrow.Size=UDim2.fromOffset(24,24)
        arrow.BackgroundTransparency=1
        arrow.BorderSizePixel=0
        arrow.Font=Enum.Font.SourceSansBold
        arrow.TextSize=17
        arrow.TextColor3=UI.Colors.Muted
        arrow.Text="▼"
        arrow.Parent=header

        local page=Instance.new("ScrollingFrame")
        page.Name="Vehicle"
        page.Position=UDim2.fromOffset(0,37)
        page.Size=UDim2.new(1,0,0,0)
        page.BackgroundColor3=UI.Colors.Background
        page.BorderSizePixel=0
        page.ScrollBarThickness=2
        page.ScrollBarImageColor3=UI.Accent
        page.AutomaticCanvasSize=Enum.AutomaticSize.Y
        page.CanvasSize=UDim2.new()
        page.Parent=win
        local pad=Instance.new("UIPadding")
        pad.PaddingTop=UDim.new(0,5); pad.PaddingBottom=UDim.new(0,5); pad.PaddingLeft=UDim.new(0,5); pad.PaddingRight=UDim.new(0,5); pad.Parent=page
        local list=Instance.new("UIListLayout")
        list.Padding=UDim.new(0,3); list.SortOrder=Enum.SortOrder.LayoutOrder; list.Parent=page

        local expanded=true
        local function resize()
            if not expanded then page.Size=UDim2.new(1,0,0,0); win.Size=UDim2.fromOffset(220,37); return end
            local h=math.clamp(list.AbsoluteContentSize.Y+10,0,430)
            page.Size=UDim2.new(1,0,0,h)
            win.Size=UDim2.fromOffset(220,37+h)
        end
        list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
        task.defer(resize)
        arrow.MouseButton1Click:Connect(function() expanded=not expanded; arrow.Text=expanded and "▼" or "▶"; resize() end)

        local dragging=false
        local startMouse,startPos
        header.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; startMouse=input.Position; startPos=win.Position end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
                local d=input.Position-startMouse
                win.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
            end
        end)
        UIS.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)

        UI.Pages.Vehicle=page
        UI.Windows.Vehicle=win
    end

    if not UI.Keybind then
        function UI.Keybind(page,label,get,set,onPressed)
            local f,t=UI.Row(page,label)
            t.Size=UDim2.new(1,-88,1,0)
            local b=Instance.new("TextButton")
            b.AnchorPoint=Vector2.new(1,.5)
            b.Position=UDim2.new(1,-7,.5,0)
            b.Size=UDim2.fromOffset(74,20)
            b.BackgroundColor3=Color3.fromRGB(32,32,32)
            b.BorderSizePixel=0
            b.Font=Enum.Font.Code
            b.TextSize=10
            b.TextColor3=Color3.fromRGB(205,205,215)
            b.Parent=f
            rounded(b,3)
            local listening=false
            local function paint()
                local key=get()
                b.Text=listening and "PRESS KEY" or (key and key.Name or "NONE")
                b.TextColor3=listening and UI.Accent or Color3.fromRGB(205,205,215)
            end
            b.MouseButton1Click:Connect(function() listening=true; paint() end)
            UIS.InputBegan:Connect(function(input,processed)
                if input.UserInputType~=Enum.UserInputType.Keyboard then return end
                if listening then
                    listening=false
                    if input.KeyCode==Enum.KeyCode.Escape then set(nil) else set(input.KeyCode) end
                    paint()
                    return
                end
                local key=get()
                if not processed and key and input.KeyCode==key and onPressed then task.spawn(onPressed) end
            end)
            paint()
            return b
        end
    end
end
