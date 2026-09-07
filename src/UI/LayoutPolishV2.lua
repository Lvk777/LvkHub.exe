-- Window placement/clamping and dock positioning polish.
return function(State, UI)
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")

    local function vp()
        local cam=Workspace.CurrentCamera
        return cam and cam.ViewportSize or Vector2.new(1920,1080)
    end

    local function clampFrame(frame)
        if not frame or not frame.Parent or not frame.Visible then return end
        local size=frame.AbsoluteSize
        local pos=frame.AbsolutePosition
        local v=vp()
        local dx,dy=0,0
        if pos.X<4 then dx=4-pos.X end
        if pos.Y<4 then dy=4-pos.Y end
        if pos.X+size.X>v.X-4 then dx=(v.X-4)-(pos.X+size.X) end
        if pos.Y+37>v.Y-4 then dy=(v.Y-4)-(pos.Y+37) end
        if dx~=0 or dy~=0 then
            frame.Position=UDim2.new(frame.Position.X.Scale,frame.Position.X.Offset+dx,frame.Position.Y.Scale,frame.Position.Y.Offset+dy)
        end
    end

    local placed=false
    local timer=0
    RunService.RenderStepped:Connect(function(dt)
        timer+=dt
        if timer<.05 then return end
        timer=0

        local world=UI.Windows.World
        local utility=UI.Windows.Utility
        local vehicle=UI.Windows.Vehicle
        local target=UI.Gui:FindFirstChild("LvkHubDummyTargetInfo")
        local preview=UI.Gui:FindFirstChild("LvkHubUnifiedPreviewV4")

        if not placed and world and utility and vehicle then
            local v=vp()
            utility.Position=UDim2.fromOffset(world.AbsolutePosition.X,math.min(world.AbsolutePosition.Y+world.AbsoluteSize.Y+8,v.Y-math.max(37,utility.AbsoluteSize.Y)-4))

            if target then
                local x=math.min(vehicle.AbsolutePosition.X+vehicle.AbsoluteSize.X+8,v.X-target.AbsoluteSize.X-4)
                target.Position=UDim2.fromOffset(math.max(4,x),vehicle.AbsolutePosition.Y)
            end
            if preview then
                local anchor=target and target.AbsolutePosition or Vector2.new(math.min(vehicle.AbsolutePosition.X+vehicle.AbsoluteSize.X+8,v.X-preview.AbsoluteSize.X-4),vehicle.AbsolutePosition.Y)
                local y=(target and (target.AbsolutePosition.Y+target.AbsoluteSize.Y+8) or (vehicle.AbsolutePosition.Y+120))
                preview.Position=UDim2.fromOffset(math.max(4,anchor.X),math.min(y,v.Y-preview.AbsoluteSize.Y-4))
            end
            placed=true
        end

        -- Keep the ••• settings panel visibly BELOW Utility. This callback is
        -- registered after the base dock logic, so it wins the final position.
        local panel=UI.ActiveDockedPanel
        if panel and panel.Parent and utility then
            local v=vp()
            local x=math.clamp(utility.AbsolutePosition.X,4,math.max(4,v.X-panel.AbsoluteSize.X-4))
            local y=utility.AbsolutePosition.Y+utility.AbsoluteSize.Y+18
            y=math.min(y,math.max(4,v.Y-panel.AbsoluteSize.Y-4))
            panel.Position=UDim2.fromOffset(x,y)
        end

        for _,w in pairs(UI.Windows) do clampFrame(w) end
        clampFrame(vehicle)
        clampFrame(target)
        clampFrame(preview)

        -- Preview follows the main menu visibility; Target Info has its own pin behavior.
        if preview and State.Visuals.Preview==true and UI.Main.Visible==false then preview.Visible=false end
    end)
end
