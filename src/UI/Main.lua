-- LvkHub.exe UI shell
-- Yokai-style independent draggable category windows, compact dark rows,
-- blue/periwinkle accent, per-window collapse and RightShift visibility.
-- Only the requested categories are created: Combat, Movement, Visuals, Utility, World, Local.

local UIS=game:GetService("UserInputService")
local CoreGui=game:GetService("CoreGui")
local Workspace=game:GetService("Workspace")

return function(State)
    local parent=(gethui and gethui()) or CoreGui
    local old=parent:FindFirstChild("LvkHubExe")
    if old then old:Destroy() end

    local gui=Instance.new("ScreenGui")
    gui.Name="LvkHubExe"
    gui.ResetOnSpawn=false
    gui.IgnoreGuiInset=true
    gui.DisplayOrder=999
    gui.ZIndexBehavior=Enum.ZIndexBehavior.Global
    gui.Parent=parent

    local main=Instance.new("Frame")
    main.Name="Main"
    main.Size=UDim2.fromScale(1,1)
    main.BackgroundTransparency=1
    main.BorderSizePixel=0
    main.Parent=gui

    local accent=Color3.fromRGB(119,120,255)
    local bg=Color3.fromRGB(20,20,20)
    local rowBg=Color3.fromRGB(25,25,25)
    local muted=Color3.fromRGB(162,162,162)
    local text=Color3.fromRGB(235,235,235)

    local categories={"Combat","Movement","Visuals","Utility","World","Local"}
    local pages={}
    local windows={}
    local orderCounter=setmetatable({}, {__index=function() return 0 end})

    local function nextOrder(page)
        orderCounter[page]=orderCounter[page]+1
        return orderCounter[page]
    end

    local function dragWindow(win,header)
        local dragging=false
        local startInput
        local startPos
        header.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then
                dragging=true
                startInput=input.Position
                startPos=win.Position
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
                local d=input.Position-startInput
                win.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
        end)
    end

    local function clampWindow(win)
        local cam=Workspace.CurrentCamera
        if not cam then return end
        local vp=cam.ViewportSize
        local p=win.AbsolutePosition
        local s=win.AbsoluteSize
        local dx,dy=0,0
        if p.X<4 then dx=4-p.X end
        if p.Y<4 then dy=4-p.Y end
        if p.X+s.X>vp.X-4 then dx=(vp.X-4)-(p.X+s.X) end
        if p.Y+37>vp.Y-4 then dy=(vp.Y-4)-(p.Y+37) end
        if dx~=0 or dy~=0 then
            win.Position=UDim2.new(win.Position.X.Scale,win.Position.X.Offset+dx,win.Position.Y.Scale,win.Position.Y.Offset+dy)
        end
    end

    local function makeWindow(name,index)
        local col=(index-1)%6
        local row=math.floor((index-1)/6)

        local win=Instance.new("Frame")
        win.Name=name.."Window"
        win.Size=UDim2.fromOffset(220,37)
        win.Position=UDim2.fromOffset(16+col*230,55+row*420)
        win.BackgroundColor3=bg
        win.BorderSizePixel=0
        win.ClipsDescendants=false
        win.Parent=main
        local wc=Instance.new("UICorner")
        wc.CornerRadius=UDim.new(0,5)
        wc.Parent=win
        local ws=Instance.new("UIStroke")
        ws.Color=Color3.fromRGB(32,35,36)
        ws.Thickness=1
        ws.Transparency=.05
        ws.Parent=win

        local header=Instance.new("Frame")
        header.Name="Header"
        header.Size=UDim2.new(1,0,0,37)
        header.BackgroundColor3=bg
        header.BorderSizePixel=0
        header.Active=true
        header.Parent=win
        local hc=Instance.new("UICorner")
        hc.CornerRadius=UDim.new(0,5)
        hc.Parent=header

        local stripe=Instance.new("Frame")
        stripe.Name="Accent"
        stripe.Size=UDim2.fromOffset(3,19)
        stripe.Position=UDim2.fromOffset(7,9)
        stripe.BorderSizePixel=0
        stripe.BackgroundColor3=accent
        stripe.Parent=header
        local sc=Instance.new("UICorner")
        sc.CornerRadius=UDim.new(1,0)
        sc.Parent=stripe

        local title=Instance.new("TextLabel")
        title.BackgroundTransparency=1
        title.Position=UDim2.fromOffset(16,0)
        title.Size=UDim2.new(1,-48,1,0)
        title.Font=Enum.Font.SourceSansSemibold
        title.TextSize=16
        title.TextColor3=Color3.fromRGB(210,210,210)
        title.TextXAlignment=Enum.TextXAlignment.Left
        title.Text=name
        title.Parent=header

        local arrow=Instance.new("TextButton")
        arrow.Name="Expand"
        arrow.AnchorPoint=Vector2.new(1,.5)
        arrow.Position=UDim2.new(1,-8,.5,0)
        arrow.Size=UDim2.fromOffset(24,24)
        arrow.BackgroundTransparency=1
        arrow.BorderSizePixel=0
        arrow.AutoButtonColor=false
        arrow.Font=Enum.Font.SourceSansBold
        arrow.TextSize=17
        arrow.TextColor3=muted
        arrow.Text="▼"
        arrow.Parent=header

        local page=Instance.new("ScrollingFrame")
        page.Name=name
        page.Position=UDim2.fromOffset(0,37)
        page.Size=UDim2.new(1,0,0,0)
        page.BackgroundColor3=bg
        page.BackgroundTransparency=0
        page.BorderSizePixel=0
        page.ScrollBarThickness=2
        page.ScrollBarImageColor3=accent
        page.AutomaticCanvasSize=Enum.AutomaticSize.Y
        page.CanvasSize=UDim2.new()
        page.Visible=true
        page.ClipsDescendants=true
        page.Parent=win

        local pad=Instance.new("UIPadding")
        pad.PaddingTop=UDim.new(0,5)
        pad.PaddingBottom=UDim.new(0,5)
        pad.PaddingLeft=UDim.new(0,5)
        pad.PaddingRight=UDim.new(0,5)
        pad.Parent=page

        local list=Instance.new("UIListLayout")
        list.Padding=UDim.new(0,3)
        list.SortOrder=Enum.SortOrder.LayoutOrder
        list.Parent=page

        local expanded=true
        local function resize()
            if not expanded then
                page.Size=UDim2.new(1,0,0,0)
                win.Size=UDim2.fromOffset(220,37)
                return
            end
            local contentH=list.AbsoluteContentSize.Y+10
            local h=math.clamp(contentH,0,430)
            page.Size=UDim2.new(1,0,0,h)
            win.Size=UDim2.fromOffset(220,37+h)
        end
        list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
        task.defer(resize)

        arrow.MouseButton1Click:Connect(function()
            expanded=not expanded
            arrow.Text=expanded and "▼" or "▶"
            resize()
        end)
        header.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then task.defer(clampWindow,win) end
        end)
        dragWindow(win,header)

        pages[name]=page
        windows[name]=win
        return page
    end

    for i,name in ipairs(categories) do makeWindow(name,i) end

    UIS.InputBegan:Connect(function(input)
        if input.KeyCode==Enum.KeyCode.RightShift then
            main.Visible=not main.Visible
            State.UI.Visible=main.Visible
        end
    end)

    local UI={
        Gui=gui,
        Main=main,
        Pages=pages,
        Windows=windows,
        Accent=accent,
        Colors={Background=bg,Row=rowBg,Muted=muted,Text=text}
    }

    function UI.Section(page,label)
        local l=Instance.new("TextLabel")
        l.LayoutOrder=nextOrder(page)
        l.Size=UDim2.new(1,0,0,21)
        l.BackgroundTransparency=1
        l.Font=Enum.Font.SourceSansSemibold
        l.TextSize=13
        l.TextColor3=Color3.fromRGB(132,132,132)
        l.TextXAlignment=Enum.TextXAlignment.Left
        l.Text="  "..string.upper(label)
        l.Parent=page
        return l
    end

    function UI.Row(page,label,height)
        local f=Instance.new("Frame")
        f.LayoutOrder=nextOrder(page)
        f.Size=UDim2.new(1,0,0,height or 31)
        f.BackgroundColor3=rowBg
        f.BorderSizePixel=0
        f.Parent=page
        local c=Instance.new("UICorner")
        c.CornerRadius=UDim.new(0,4)
        c.Parent=f

        local t=Instance.new("TextLabel")
        t.BackgroundTransparency=1
        t.Position=UDim2.fromOffset(9,0)
        t.Size=UDim2.new(1,-18,1,0)
        t.Font=Enum.Font.SourceSans
        t.TextSize=14
        t.TextColor3=text
        t.TextXAlignment=Enum.TextXAlignment.Left
        t.Text=label
        t.Parent=f
        return f,t
    end

    function UI.Toggle(page,label,get,set)
        local f,t=UI.Row(page,label)
        t.Size=UDim2.new(1,-48,1,0)
        t.Active=true

        local b=Instance.new("TextButton")
        b.AnchorPoint=Vector2.new(1,.5)
        b.Position=UDim2.new(1,-7,.5,0)
        b.Size=UDim2.fromOffset(28,18)
        b.Text=""
        b.BorderSizePixel=0
        b.AutoButtonColor=false
        b.Parent=f
        local bc=Instance.new("UICorner")
        bc.CornerRadius=UDim.new(0,3)
        bc.Parent=b

        local mark=Instance.new("Frame")
        mark.AnchorPoint=Vector2.new(.5,.5)
        mark.Position=UDim2.fromScale(.5,.5)
        mark.Size=UDim2.fromOffset(18,10)
        mark.BorderSizePixel=0
        mark.Parent=b
        local mc=Instance.new("UICorner")
        mc.CornerRadius=UDim.new(0,2)
        mc.Parent=mark

        local function paint()
            local on=get()==true
            b.BackgroundColor3=on and accent or Color3.fromRGB(45,45,45)
            mark.BackgroundColor3=on and Color3.fromRGB(235,235,235) or Color3.fromRGB(86,86,86)
        end
        local function flip()
            set(not get())
            paint()
        end

        -- One input path per clickable area. The previous implementation listened
        -- on both the child button and its parent row, so one click could fire twice
        -- and immediately return the state to OFF.
        b.MouseButton1Click:Connect(flip)
        t.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then flip() end
        end)
        paint()
        return f
    end

    function UI.Number(page,label,get,set,min,max)
        local f,t=UI.Row(page,label)
        t.Size=UDim2.new(1,-82,1,0)
        local box=Instance.new("TextBox")
        box.AnchorPoint=Vector2.new(1,.5)
        box.Position=UDim2.new(1,-7,.5,0)
        box.Size=UDim2.fromOffset(66,20)
        box.BackgroundColor3=Color3.fromRGB(32,32,32)
        box.BorderSizePixel=0
        box.ClearTextOnFocus=false
        box.Font=Enum.Font.Code
        box.TextSize=11
        box.TextColor3=Color3.fromRGB(200,200,200)
        box.Text=tostring(get())
        box.Parent=f
        local c=Instance.new("UICorner")
        c.CornerRadius=UDim.new(0,3)
        c.Parent=box
        box.FocusLost:Connect(function()
            local n=tonumber(box.Text)
            if n then set(math.clamp(n,min,max)) end
            box.Text=tostring(get())
        end)
        return f
    end

    function UI.Button(page,label,buttonText,callback)
        local f,t=UI.Row(page,label)
        t.Size=UDim2.new(1,-88,1,0)
        local b=Instance.new("TextButton")
        b.AnchorPoint=Vector2.new(1,.5)
        b.Position=UDim2.new(1,-7,.5,0)
        b.Size=UDim2.fromOffset(74,20)
        b.BackgroundColor3=Color3.fromRGB(38,38,38)
        b.BorderSizePixel=0
        b.AutoButtonColor=false
        b.Font=Enum.Font.SourceSansSemibold
        b.TextSize=12
        b.TextColor3=Color3.fromRGB(210,210,210)
        b.Text=buttonText
        b.Parent=f
        local c=Instance.new("UICorner")
        c.CornerRadius=UDim.new(0,3)
        c.Parent=b
        b.MouseButton1Click:Connect(function() task.spawn(callback,b) end)
        return b
    end

    function UI.Dropdown(page,label,values,get,set)
        local f,t=UI.Row(page,label)
        t.Size=UDim2.new(1,-96,1,0)
        local b=Instance.new("TextButton")
        b.AnchorPoint=Vector2.new(1,.5)
        b.Position=UDim2.new(1,-7,.5,0)
        b.Size=UDim2.fromOffset(82,20)
        b.BackgroundColor3=Color3.fromRGB(32,32,32)
        b.BorderSizePixel=0
        b.AutoButtonColor=false
        b.Font=Enum.Font.SourceSans
        b.TextSize=12
        b.TextColor3=Color3.fromRGB(200,200,200)
        b.Parent=f
        local c=Instance.new("UICorner")
        c.CornerRadius=UDim.new(0,3)
        c.Parent=b
        local function paint() b.Text=tostring(get()) end
        b.MouseButton1Click:Connect(function()
            local current=get()
            local i=table.find(values,current) or 0
            set(values[i%#values+1])
            paint()
        end)
        paint()
        return b
    end

    return UI
end
