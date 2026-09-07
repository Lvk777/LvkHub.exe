-- Vehicle-only controls. Car ESP rendering remains owned by UnifiedTestVisualsV4.
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

    -- Remove the legacy Car ESP row from Visuals so vehicle options live in one panel.
    task.defer(function()
        local visualPage=UI.Pages.Visuals
        if not visualPage then return end
        for _,row in ipairs(visualPage:GetChildren()) do
            if row:IsA("Frame") then
                local label=row:FindFirstChildWhichIsA("TextLabel")
                if label and label.Text=="Car ESP" then row.Visible=false end
            end
        end
    end)
end
