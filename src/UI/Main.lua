-- LvkHub.exe lightweight UI

local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

return function(State)
    local parent = (gethui and gethui()) or CoreGui
    local old = parent:FindFirstChild("LvkHubExe")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "LvkHubExe"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 9000
    gui.Parent = parent

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.fromOffset(760, 500)
    main.Position = UDim2.new(.5, -380, .5, -250)
    main.BackgroundColor3 = Color3.fromRGB(13,13,18)
    main.BorderSizePixel = 0
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(85,68,135)
    stroke.Transparency = .25

    local top = Instance.new("Frame")
    top.Name = "Top"
    top.Size = UDim2.new(1,0,0,54)
    top.BackgroundColor3 = Color3.fromRGB(18,18,25)
    top.BorderSizePixel = 0
    top.Parent = main
    local tc = Instance.new("UICorner", top); tc.CornerRadius = UDim.new(0,10)

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(18,0)
    title.Size = UDim2.new(1,-150,1,0)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 17
    title.TextColor3 = Color3.new(1,1,1)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "LVKHUB.EXE  •  GUN TESTING"
    title.Parent = top

    local accent = Instance.new("Frame")
    accent.Size = UDim2.fromOffset(3,28)
    accent.Position = UDim2.fromOffset(8,13)
    accent.BorderSizePixel = 0
    accent.BackgroundColor3 = Color3.fromRGB(125,82,235)
    accent.Parent = top
    Instance.new("UICorner", accent).CornerRadius = UDim.new(1,0)

    local close = Instance.new("TextButton")
    close.AnchorPoint = Vector2.new(1,.5)
    close.Position = UDim2.new(1,-12,.5,0)
    close.Size = UDim2.fromOffset(36,28)
    close.BackgroundColor3 = Color3.fromRGB(31,31,42)
    close.BorderSizePixel = 0
    close.Font = Enum.Font.GothamBold
    close.TextSize = 15
    close.TextColor3 = Color3.new(1,1,1)
    close.Text = "—"
    close.Parent = top
    Instance.new("UICorner", close).CornerRadius = UDim.new(0,7)

    local sidebar = Instance.new("Frame")
    sidebar.Position = UDim2.fromOffset(0,54)
    sidebar.Size = UDim2.new(0,165,1,-54)
    sidebar.BackgroundColor3 = Color3.fromRGB(16,16,22)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = main

    local content = Instance.new("Frame")
    content.Position = UDim2.fromOffset(165,54)
    content.Size = UDim2.new(1,-165,1,-54)
    content.BackgroundTransparency = 1
    content.Parent = main

    local pages = {}
    local buttons = {}
    local tabs = {"Combat","Visuals","Movement","World","Utility","Local","Settings"}

    local function makePage(name)
        local page = Instance.new("ScrollingFrame")
        page.Name = name
        page.Size = UDim2.fromScale(1,1)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = Color3.fromRGB(125,82,235)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.CanvasSize = UDim2.new()
        page.Visible = false
        page.Parent = content
        local pad = Instance.new("UIPadding", page)
        pad.PaddingTop = UDim.new(0,14); pad.PaddingLeft = UDim.new(0,14); pad.PaddingRight = UDim.new(0,14); pad.PaddingBottom = UDim.new(0,14)
        local list = Instance.new("UIListLayout", page)
        list.Padding = UDim.new(0,8)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        pages[name] = page
        return page
    end

    for i,name in ipairs(tabs) do
        makePage(name)
        local b = Instance.new("TextButton")
        b.Name = name .. "Tab"
        b.Size = UDim2.new(1,-18,0,38)
        b.Position = UDim2.fromOffset(9,10+(i-1)*44)
        b.BackgroundTransparency = 1
        b.BackgroundColor3 = Color3.fromRGB(125,82,235)
        b.BorderSizePixel = 0
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 12
        b.TextColor3 = Color3.fromRGB(190,190,205)
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.Text = "   "..name
        b.Parent = sidebar
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,7)
        buttons[name] = b
    end

    local function show(name)
        State.UI.ActiveTab = name
        for n,p in pairs(pages) do p.Visible = (n==name) end
        for n,b in pairs(buttons) do
            b.BackgroundTransparency = n==name and .25 or 1
            b.TextColor3 = n==name and Color3.new(1,1,1) or Color3.fromRGB(190,190,205)
        end
    end
    for name,b in pairs(buttons) do b.MouseButton1Click:Connect(function() show(name) end) end
    show(State.UI.ActiveTab or "Visuals")

    -- drag
    local dragging=false; local startPos; local startInput
    top.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; startInput=input.Position; startPos=main.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
            local d=input.Position-startInput
            main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)

    local collapsed=false
    close.MouseButton1Click:Connect(function()
        collapsed=not collapsed
        sidebar.Visible=not collapsed; content.Visible=not collapsed
        main.Size=collapsed and UDim2.fromOffset(760,54) or UDim2.fromOffset(760,500)
        close.Text=collapsed and "□" or "—"
    end)

    UIS.InputBegan:Connect(function(input)
        if input.KeyCode==Enum.KeyCode.RightShift then
            main.Visible=not main.Visible
            State.UI.Visible=main.Visible
        end
    end)

    local UI={Gui=gui,Main=main,Pages=pages,Buttons=buttons,Accent=Color3.fromRGB(125,82,235)}

    function UI.Section(page,text)
        local l=Instance.new("TextLabel")
        l.Size=UDim2.new(1,0,0,22); l.BackgroundTransparency=1
        l.Font=Enum.Font.GothamBold; l.TextSize=12; l.TextColor3=Color3.fromRGB(166,159,192)
        l.TextXAlignment=Enum.TextXAlignment.Left; l.Text=string.upper(text); l.Parent=page
        return l
    end

    function UI.Row(page,label,height)
        local f=Instance.new("Frame")
        f.Size=UDim2.new(1,0,0,height or 38); f.BackgroundColor3=Color3.fromRGB(24,24,33); f.BorderSizePixel=0; f.Parent=page
        Instance.new("UICorner", f).CornerRadius=UDim.new(0,7)
        local t=Instance.new("TextLabel")
        t.BackgroundTransparency=1; t.Position=UDim2.fromOffset(10,0); t.Size=UDim2.new(1,-20,1,0)
        t.Font=Enum.Font.Gotham; t.TextSize=13; t.TextColor3=Color3.fromRGB(230,230,240); t.TextXAlignment=Enum.TextXAlignment.Left; t.Text=label; t.Parent=f
        return f,t
    end

    function UI.Toggle(page,label,get,set)
        local f=UI.Row(page,label)
        local b=Instance.new("TextButton")
        b.Size=UDim2.fromOffset(48,24); b.Position=UDim2.new(1,-58,.5,-12); b.Text=""; b.BorderSizePixel=0; b.Parent=f
        Instance.new("UICorner", b).CornerRadius=UDim.new(1,0)
        local dot=Instance.new("Frame")
        dot.Size=UDim2.fromOffset(18,18); dot.BorderSizePixel=0; dot.BackgroundColor3=Color3.new(1,1,1); dot.Parent=b
        Instance.new("UICorner", dot).CornerRadius=UDim.new(1,0)
        local function paint()
            local on=get()==true; b.BackgroundColor3=on and UI.Accent or Color3.fromRGB(50,50,62); dot.Position=on and UDim2.fromOffset(27,3) or UDim2.fromOffset(3,3)
        end
        b.MouseButton1Click:Connect(function() set(not get()); paint() end); paint(); return f
    end

    function UI.Number(page,label,get,set,min,max)
        local f=UI.Row(page,label)
        local box=Instance.new("TextBox")
        box.Size=UDim2.fromOffset(90,24); box.Position=UDim2.new(1,-100,.5,-12); box.BackgroundColor3=Color3.fromRGB(34,34,45); box.BorderSizePixel=0
        box.ClearTextOnFocus=false; box.Font=Enum.Font.Code; box.TextSize=12; box.TextColor3=Color3.new(1,1,1); box.Text=tostring(get()); box.Parent=f
        Instance.new("UICorner", box).CornerRadius=UDim.new(0,5)
        box.FocusLost:Connect(function() local n=tonumber(box.Text); if n then set(math.clamp(n,min,max)) end; box.Text=tostring(get()) end)
        return f
    end

    function UI.Button(page,label,buttonText,callback)
        local f=UI.Row(page,label)
        local b=Instance.new("TextButton")
        b.AnchorPoint=Vector2.new(1,.5); b.Position=UDim2.new(1,-10,.5,0); b.Size=UDim2.fromOffset(118,26)
        b.BackgroundColor3=UI.Accent; b.BorderSizePixel=0; b.Font=Enum.Font.GothamBold; b.TextSize=11; b.TextColor3=Color3.new(1,1,1); b.Text=buttonText; b.Parent=f
        Instance.new("UICorner", b).CornerRadius=UDim.new(0,6)
        b.MouseButton1Click:Connect(function() task.spawn(callback,b) end)
        return b
    end

    return UI
end
