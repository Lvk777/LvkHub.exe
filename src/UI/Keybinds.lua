-- Feature keybinds live inside per-feature ••• menus instead of permanent rows.
return function(State, Registry, UI)
    local UIS=game:GetService("UserInputService")

    State.Keybinds=State.Keybinds or {}
    local K=State.Keybinds
    local listening=nil
    local activePanel=nil
    local activeFeature=nil
    local keyButton=nil

    local function rounded(obj,r)
        local c=Instance.new("UICorner")
        c.CornerRadius=UDim.new(0,r or 4)
        c.Parent=obj
    end

    local function practiceAllowed()
        return not Registry or not Registry.PracticeAllowed or Registry.PracticeAllowed()
    end

    local features={
        {id="Aimbot",page="Combat",label="Aimbot",guarded=true,get=function() return State.Combat.Aimbot end,set=function(v) State.Combat.Aimbot=v end},
        {id="SilentAim",page="Combat",label="Silent Aim",guarded=true,get=function() return State.Combat.SilentAim end,set=function(v) State.Combat.SilentAim=v end},
        {id="MagicBullets",page="Combat",label="Magic Bullets",guarded=true,get=function() return State.Combat.MagicBullets end,set=function(v) State.Combat.MagicBullets=v end},
        {id="HitBoxes",page="Combat",label="HitBoxes",guarded=true,get=function() return State.Combat.HitBoxes end,set=function(v) State.Combat.HitBoxes=v end},
        {id="Fly",page="Movement",label="Fly",get=function() return State.Movement.Fly end,set=function(v) State.Movement.Fly=v end},
        {id="Speed",page="Movement",label="Speed",get=function() return State.Movement.Speed end,set=function(v) State.Movement.Speed=v end},
        {id="Noclip",page="Movement",label="Noclip",get=function() return State.Movement.Noclip end,set=function(v) State.Movement.Noclip=v end},
        {id="CarFly",page="Vehicle",label="CarFly",get=function() return State.Movement.CarFly end,set=function(v) State.Movement.CarFly=v end},
    }

    local function rowByLabel(page,labelText)
        if not page then return nil end
        for _,child in ipairs(page:GetChildren()) do
            if child:IsA("Frame") then
                for _,d in ipairs(child:GetChildren()) do
                    if d:IsA("TextLabel") and d.Text==labelText then return child,d end
                end
            end
        end
        return nil
    end

    local function repaint(feature)
        local row=rowByLabel(UI.Pages[feature.page],feature.label)
        if not row then return end
        local toggle=nil
        for _,d in ipairs(row:GetChildren()) do
            if d:IsA("TextButton") and d.Name~="LvkKeybindDots" and d:FindFirstChildWhichIsA("Frame") then
                toggle=d
                break
            end
        end
        if not toggle then return end
        local on=feature.get()==true
        toggle.BackgroundColor3=on and UI.Accent or Color3.fromRGB(45,45,45)
        local mark=toggle:FindFirstChildWhichIsA("Frame")
        if mark then mark.BackgroundColor3=on and Color3.fromRGB(235,235,235) or Color3.fromRGB(86,86,86) end
    end

    local function keyName(id)
        local key=K[id]
        return key and key.Name or "NONE"
    end

    local function refreshKeyButton()
        if keyButton and activeFeature then
            keyButton.Text=listening==activeFeature and "PRESS KEY" or keyName(activeFeature)
            keyButton.TextColor3=listening==activeFeature and UI.Accent or Color3.fromRGB(220,220,228)
        end
    end

    local function openFeatureMenu(feature)
        listening=nil
        if activePanel and activePanel.Parent then activePanel:Destroy() end

        local panel=Instance.new("Frame")
        panel.Name="LvkFeatureOptions"
        panel.Size=UDim2.fromOffset(220,108)
        panel.BackgroundColor3=Color3.fromRGB(17,18,22)
        panel.BorderSizePixel=0
        panel.ZIndex=100
        rounded(panel,7)
        local stroke=Instance.new("UIStroke")
        stroke.Color=Color3.fromRGB(62,64,76)
        stroke.Transparency=.12
        stroke.Parent=panel

        local title=Instance.new("TextLabel")
        title.BackgroundTransparency=1
        title.Position=UDim2.fromOffset(10,5)
        title.Size=UDim2.new(1,-42,0,28)
        title.Font=Enum.Font.SourceSansSemibold
        title.TextSize=14
        title.TextColor3=Color3.fromRGB(238,238,242)
        title.TextXAlignment=Enum.TextXAlignment.Left
        title.Text=feature.label.." Options"
        title.ZIndex=101
        title.Parent=panel

        local close=Instance.new("TextButton")
        close.AnchorPoint=Vector2.new(1,0)
        close.Position=UDim2.new(1,-7,0,6)
        close.Size=UDim2.fromOffset(25,22)
        close.BackgroundColor3=Color3.fromRGB(34,35,42)
        close.BorderSizePixel=0
        close.Text="×"
        close.Font=Enum.Font.SourceSansBold
        close.TextSize=16
        close.TextColor3=Color3.fromRGB(215,215,222)
        close.ZIndex=102
        close.Parent=panel
        rounded(close,4)

        local row=Instance.new("Frame")
        row.Position=UDim2.fromOffset(7,39)
        row.Size=UDim2.new(1,-14,0,31)
        row.BackgroundColor3=Color3.fromRGB(27,28,34)
        row.BorderSizePixel=0
        row.ZIndex=101
        row.Parent=panel
        rounded(row,4)

        local label=Instance.new("TextLabel")
        label.BackgroundTransparency=1
        label.Position=UDim2.fromOffset(8,0)
        label.Size=UDim2.new(1,-92,1,0)
        label.Font=Enum.Font.SourceSans
        label.TextSize=12
        label.TextColor3=Color3.fromRGB(220,220,228)
        label.TextXAlignment=Enum.TextXAlignment.Left
        label.Text="Keybind"
        label.ZIndex=102
        label.Parent=row

        local b=Instance.new("TextButton")
        b.AnchorPoint=Vector2.new(1,.5)
        b.Position=UDim2.new(1,-7,.5,0)
        b.Size=UDim2.fromOffset(78,20)
        b.BackgroundColor3=Color3.fromRGB(37,38,46)
        b.BorderSizePixel=0
        b.Font=Enum.Font.Code
        b.TextSize=10
        b.TextColor3=Color3.fromRGB(220,220,228)
        b.ZIndex=103
        b.Parent=row
        rounded(b,3)

        local clear=Instance.new("TextButton")
        clear.Position=UDim2.fromOffset(7,76)
        clear.Size=UDim2.new(1,-14,0,25)
        clear.BackgroundColor3=Color3.fromRGB(31,32,38)
        clear.BorderSizePixel=0
        clear.Font=Enum.Font.SourceSans
        clear.TextSize=11
        clear.TextColor3=Color3.fromRGB(170,175,190)
        clear.Text="CLEAR KEYBIND"
        clear.ZIndex=101
        clear.Parent=panel
        rounded(clear,4)

        activePanel=panel
        activeFeature=feature.id
        keyButton=b
        refreshKeyButton()

        b.MouseButton1Click:Connect(function()
            listening=feature.id
            refreshKeyButton()
        end)
        clear.MouseButton1Click:Connect(function()
            K[feature.id]=nil
            listening=nil
            refreshKeyButton()
        end)
        close.MouseButton1Click:Connect(function()
            listening=nil
            if UI.CloseDockedPanel then UI.CloseDockedPanel(panel) else panel:Destroy() end
        end)

        if UI.OpenDockedPanel then UI.OpenDockedPanel(panel) else panel.Parent=UI.Gui end
    end

    local function addDots(feature)
        local page=UI.Pages[feature.page]
        local row,label=rowByLabel(page,feature.label)
        if not row or row:FindFirstChild("LvkKeybindDots") then return end
        if label then label.Size=UDim2.new(1,-82,1,0) end

        local dots=Instance.new("TextButton")
        dots.Name="LvkKeybindDots"
        dots.AnchorPoint=Vector2.new(1,.5)
        dots.Position=UDim2.new(1,-43,.5,0)
        dots.Size=UDim2.fromOffset(26,20)
        dots.BackgroundColor3=Color3.fromRGB(34,34,40)
        dots.BorderSizePixel=0
        dots.Text="•••"
        dots.Font=Enum.Font.SourceSansBold
        dots.TextSize=14
        dots.TextColor3=Color3.fromRGB(195,195,205)
        dots.Parent=row
        rounded(dots,4)
        dots.MouseButton1Click:Connect(function() openFeatureMenu(feature) end)
    end

    task.defer(function() for _,feature in ipairs(features) do addDots(feature) end end)
    task.delay(.5,function() for _,feature in ipairs(features) do addDots(feature) end end)

    UIS.InputBegan:Connect(function(input,_processed)
        if input.UserInputType~=Enum.UserInputType.Keyboard then return end

        if listening then
            local id=listening
            listening=nil
            if input.KeyCode==Enum.KeyCode.Escape
                or input.KeyCode==Enum.KeyCode.Backspace
                or input.KeyCode==Enum.KeyCode.Delete
                or input.KeyCode==Enum.KeyCode.Unknown then
                K[id]=nil
            elseif K[id]==input.KeyCode then
                K[id]=nil
            else
                K[id]=input.KeyCode
            end
            refreshKeyButton()
            return
        end

        -- Game systems may mark Q/E/Shift/etc. as processed. Feature keybinds are
        -- still allowed unless the user is actively typing into a TextBox.
        if UIS:GetFocusedTextBox() then return end

        for _,feature in ipairs(features) do
            local key=K[feature.id]
            if key and input.KeyCode==key then
                local nextValue=not feature.get()
                if nextValue and feature.guarded and not practiceAllowed() then
                    feature.set(false)
                else
                    feature.set(nextValue)
                end
                repaint(feature)
                break
            end
        end
    end)
end
