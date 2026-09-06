return function(State, Registry, UI)
    local RunService=game:GetService("RunService")
    local page=UI.Pages.Settings
    UI.Section(page,"Settings")
    local _,status=UI.Row(page,"Registry ready")
    status.TextColor3=Color3.fromRGB(150,200,255)
    UI.Button(page,"Refresh registries","REFRESH",function(b)
        Registry.Refresh(); b.Text="DONE"; task.wait(.6); b.Text="REFRESH"
    end)
    UI.Button(page,"Hide hub","HIDE",function()
        UI.Main.Visible=false; State.UI.Visible=false
    end)
    local _,hotkey=UI.Row(page,"Hotkey: RightShift")
    hotkey.TextColor3=Color3.fromRGB(160,170,200)

    task.spawn(function()
        while UI.Gui.Parent do
            status.Text="Bots: "..Registry.CountBots().."  •  Vehicles: "..Registry.CountVehicles().."  •  Studio: "..tostring(RunService:IsStudio())
            task.wait(1)
        end
    end)
end
