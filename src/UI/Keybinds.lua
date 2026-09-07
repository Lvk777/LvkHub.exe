-- Configurable toggle keybinds for local/dummy-only features.
return function(State, UI)
    if not UI.Keybind then return end

    State.Keybinds=State.Keybinds or {}
    local K=State.Keybinds

    UI.Section(UI.Pages.Combat,"Keybinds")
    UI.Keybind(UI.Pages.Combat,"Aimbot Key",function() return K.Aimbot end,function(v) K.Aimbot=v end,function()
        State.Combat.Aimbot=not State.Combat.Aimbot
    end)

    UI.Section(UI.Pages.Movement,"Keybinds")
    UI.Keybind(UI.Pages.Movement,"Fly Key",function() return K.Fly end,function(v) K.Fly=v end,function()
        State.Movement.Fly=not State.Movement.Fly
    end)
    UI.Keybind(UI.Pages.Movement,"Speed Key",function() return K.Speed end,function(v) K.Speed=v end,function()
        State.Movement.Speed=not State.Movement.Speed
    end)
    UI.Keybind(UI.Pages.Movement,"Noclip Key",function() return K.Noclip end,function(v) K.Noclip=v end,function()
        State.Movement.Noclip=not State.Movement.Noclip
    end)

    if UI.Pages.Vehicle then
        UI.Section(UI.Pages.Vehicle,"Keybinds")
        UI.Keybind(UI.Pages.Vehicle,"CarFly Key",function() return K.CarFly end,function(v) K.CarFly=v end,function()
            State.Movement.CarFly=not State.Movement.CarFly
        end)
    end
end
