-- Startup-only placement for detached panels.
-- Target Info is aligned to the right of Vehicle and Visuals Preview directly below it.
-- No continuous position writes: after initial placement both panels remain freely draggable.
return function(State, UI)
    local Workspace=game:GetService("Workspace")

    local function viewport()
        local cam=Workspace.CurrentCamera
        return cam and cam.ViewportSize or Vector2.new(1920,1080)
    end

    local function readyFrame(name)
        local f=UI.Gui:FindFirstChild(name)
        if f and f.AbsoluteSize.X>10 and f.AbsoluteSize.Y>10 then return f end
        return nil
    end

    task.spawn(function()
        local deadline=os.clock()+4
        local vehicle,target,preview
        repeat
            vehicle=UI.Windows and UI.Windows.Vehicle
            target=readyFrame("LvkHubDummyTargetInfo")
            preview=readyFrame("LvkHubVisualsDummyPreview")
            if vehicle and vehicle.AbsoluteSize.X>10 and target and preview then break end
            task.wait(.05)
        until os.clock()>deadline
        if not vehicle or not target or not preview then return end

        task.wait() -- let final text/layout sizes settle
        local v=viewport()
        local desiredX=vehicle.AbsolutePosition.X+vehicle.AbsoluteSize.X+8
        local widest=math.max(target.AbsoluteSize.X,preview.AbsoluteSize.X)
        local x=math.clamp(desiredX,4,math.max(4,v.X-widest-4))
        local y=math.clamp(vehicle.AbsolutePosition.Y,4,math.max(4,v.Y-target.AbsoluteSize.Y-4))
        target.Position=UDim2.fromOffset(x,y)

        task.wait()
        local py=target.AbsolutePosition.Y+target.AbsoluteSize.Y+8
        py=math.clamp(py,4,math.max(4,v.Y-preview.AbsoluteSize.Y-4))
        preview.Position=UDim2.fromOffset(x,py)
    end)
end
