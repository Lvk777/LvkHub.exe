-- Vehicle-only controls. Car ESP rendering is owned by UnifiedTestVisualsV5.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local UIS=game:GetService("UserInputService")
    local Workspace=game:GetService("Workspace")
    local LP=Players.LocalPlayer
    local page=UI.Pages.Vehicle
    if not page then return end

    UI.Section(page,"Vehicle")
    UI.Toggle(page,"CarFly",function() return State.Movement.CarFly end,function(v) State.Movement.CarFly=v end)
    UI.Number(page,"CarFly Speed",function() return State.Movement.CarFlySpeed or 90 end,function(v) State.Movement.CarFlySpeed=v end,10,400)
    UI.Toggle(page,"Car ESP",function() return State.Visuals.CarESP end,function(v) State.Visuals.CarESP=v end)

    local cfg=State.Visuals._V5Config
    if cfg then
        local row,label=UI.Row(page,"Car ESP Color",38)
        label.Size=UDim2.fromOffset(78,38)
        local bar=Instance.new("Frame")
        bar.Position=UDim2.fromOffset(86,11)
        bar.Size=UDim2.new(1,-94,0,16)
        bar.BackgroundColor3=Color3.new(1,1,1)
        bar.BorderSizePixel=0
        bar.Active=true
        bar.Parent=row
        local bc=Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,4); bc.Parent=bar
        local grad=Instance.new("UIGradient")
        grad.Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(1/6,Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(2/6,Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(3/6,Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(4/6,Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(5/6,Color3.fromRGB(255,0,255)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0)),
        })
        grad.Parent=bar
        local knob=Instance.new("Frame")
        knob.AnchorPoint=Vector2.new(.5,.5)
        knob.Position=UDim2.new(0,0,.5,0)
        knob.Size=UDim2.fromOffset(4,22)
        knob.BackgroundColor3=Color3.fromRGB(245,245,248)
        knob.BorderSizePixel=0
        knob.Parent=bar
        local ks=Instance.new("UIStroke"); ks.Color=Color3.fromRGB(25,25,28); ks.Parent=knob
        local dragging=false
        local function sync()
            local c=cfg.CarColor
            if typeof(c)=="Color3" then
                local h=select(1,c:ToHSV())
                knob.Position=UDim2.new(h,0,.5,0)
            end
        end
        local function setFromX(x)
            local h=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1)
            cfg.CarColor=Color3.fromHSV(h,1,1)
            knob.Position=UDim2.new(h,0,.5,0)
        end
        bar.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; setFromX(input.Position.X) end end)
        UIS.InputChanged:Connect(function(input) if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then setFromX(input.Position.X) end end)
        UIS.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
        task.defer(sync)

        UI.Number(page,"Car ESP Transparency",function() return cfg.CarTransparency or 84 end,function(v) cfg.CarTransparency=v end,0,100)
    end

    local function seatedVehicle()
        local ch=LP.Character
        local hum=ch and ch:FindFirstChildOfClass("Humanoid")
        local seat=hum and hum.SeatPart
        if not seat then return nil,nil end
        local model=seat:FindFirstAncestorOfClass("Model")
        if not model then return nil,nil end
        return model,seat
    end

    local function moveVector(cam)
        local f=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)
        if f.Magnitude>0 then f=f.Unit end
        local r=Vector3.new(cam.CFrame.RightVector.X,0,cam.CFrame.RightVector.Z)
        if r.Magnitude>0 then r=r.Unit end
        local v=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then v+=f end
        if UIS:IsKeyDown(Enum.KeyCode.S) then v-=f end
        if UIS:IsKeyDown(Enum.KeyCode.D) then v+=r end
        if UIS:IsKeyDown(Enum.KeyCode.A) then v-=r end
        if UIS:IsKeyDown(Enum.KeyCode.E) then v+=Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.Q) then v-=Vector3.yAxis end
        return v.Magnitude>0 and v.Unit or Vector3.zero
    end

    RunService.Heartbeat:Connect(function()
        if not State.Movement.CarFly then return end
        local cam=Workspace.CurrentCamera
        if not cam then return end
        local vehicle,seat=seatedVehicle()
        if not vehicle or not seat then return end
        local root=vehicle.PrimaryPart or seat or vehicle:FindFirstChildWhichIsA("BasePart",true)
        if not root then return end
        local dir=moveVector(cam)
        local speed=math.max(10,State.Movement.CarFlySpeed or 90)
        if dir.Magnitude>0 then root.AssemblyLinearVelocity=dir*speed else root.AssemblyLinearVelocity=Vector3.zero end
        local flat=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)
        if flat.Magnitude>0 then pcall(function() root.CFrame=CFrame.lookAt(root.Position,root.Position+flat.Unit) end) end
    end)
end
