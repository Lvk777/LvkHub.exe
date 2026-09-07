-- Configurable toggle keybinds for local/dummy-only features.
return function(State, UI)
    if not UI.Keybind then return end

    State.Keybinds=State.Keybinds or {}
    local K=State.Keybinds

    local function repaintToggle(page,label,on)
        for _,row in ipairs(page:GetChildren()) do
            if row:IsA("Frame") then
                local text=row:FindFirstChildWhichIsA("TextLabel")
                if text and text.Text==label then
                    local button=row:FindFirstChildWhichIsA("TextButton")
                    if button then
                        button.BackgroundColor3=on and UI.Accent or Color3.fromRGB(45,45,45)
                        local mark=button:FindFirstChildWhichIsA("Frame")
                        if mark then mark.BackgroundColor3=on and Color3.fromRGB(235,235,235) or Color3.fromRGB(86,86,86) end
                    end
                    return
                end
            end
        end
    end

    UI.Section(UI.Pages.Combat,"Keybinds")
    UI.Keybind(UI.Pages.Combat,"Aimbot Key",function() return K.Aimbot end,function(v) K.Aimbot=v end,function()
        State.Combat.Aimbot=not State.Combat.Aimbot
        repaintToggle(UI.Pages.Combat,"Aimbot",State.Combat.Aimbot)
    end)

    UI.Section(UI.Pages.Movement,"Keybinds")
    UI.Keybind(UI.Pages.Movement,"Fly Key",function() return K.Fly end,function(v) K.Fly=v end,function()
        State.Movement.Fly=not State.Movement.Fly
        repaintToggle(UI.Pages.Movement,"Fly",State.Movement.Fly)
    end)
    UI.Keybind(UI.Pages.Movement,"Speed Key",function() return K.Speed end,function(v) K.Speed=v end,function()
        State.Movement.Speed=not State.Movement.Speed
        repaintToggle(UI.Pages.Movement,"Speed",State.Movement.Speed)
    end)
    UI.Keybind(UI.Pages.Movement,"Noclip Key",function() return K.Noclip end,function(v) K.Noclip=v end,function()
        State.Movement.Noclip=not State.Movement.Noclip
        repaintToggle(UI.Pages.Movement,"Noclip",State.Movement.Noclip)
    end)

    if UI.Pages.Vehicle then
        UI.Section(UI.Pages.Vehicle,"Keybinds")
        UI.Keybind(UI.Pages.Vehicle,"CarFly Key",function() return K.CarFly end,function(v) K.CarFly=v end,function()
            State.Movement.CarFly=not State.Movement.CarFly
            repaintToggle(UI.Pages.Vehicle,"CarFly",State.Movement.CarFly)
        end)
    end
end
