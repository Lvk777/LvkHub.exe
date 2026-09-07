-- Shared ••• popup placement: open once below Movement, then remain draggable.
-- This module only wraps UI.OpenDockedPanel; it never rewrites panel position per-frame.
return function(State, UI)
    local Workspace=game:GetService("Workspace")
    local oldOpen=UI.OpenDockedPanel
    if type(oldOpen)~="function" then return end

    local function viewport()
        local cam=Workspace.CurrentCamera
        return cam and cam.ViewportSize or Vector2.new(1920,1080)
    end

    local function place(panel)
        if not panel or not panel.Parent or UI.ActiveDockedPanel~=panel then return end
        local movement=UI.Windows and UI.Windows.Movement
        if not movement then return end
        local v=viewport()
        local w=math.max(panel.AbsoluteSize.X,214)
        local h=math.max(panel.AbsoluteSize.Y,44)
        local x=math.clamp(movement.AbsolutePosition.X,4,math.max(4,v.X-w-4))
        local y=movement.AbsolutePosition.Y+movement.AbsoluteSize.Y+10
        if y+h>v.Y-4 then y=math.max(4,v.Y-h-4) end
        panel.Position=UDim2.fromOffset(x,y)
    end

    UI.OpenDockedPanel=function(panel)
        oldOpen(panel)
        -- The popup often receives its final AutomaticSize one frame later.
        task.defer(place,panel)
        task.delay(.05,place,panel)
    end
end
