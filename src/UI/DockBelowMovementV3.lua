-- Opens every ••• panel below Movement, with no upward clamp that can overlap other windows.
return function(State, UI)
    local oldOpen=UI.OpenDockedPanel
    if type(oldOpen)~="function" then return end

    local function place(panel)
        if not panel or not panel.Parent or UI.ActiveDockedPanel~=panel then return end
        local movement=UI.Windows and UI.Windows.Movement
        if not movement then return end
        local x=movement.AbsolutePosition.X
        local y=movement.AbsolutePosition.Y+movement.AbsoluteSize.Y+18
        panel.Position=UDim2.fromOffset(x,y)
    end

    UI.OpenDockedPanel=function(panel)
        oldOpen(panel)
        task.defer(place,panel)
        task.delay(.05,place,panel)
        task.delay(.15,place,panel)
    end
end
